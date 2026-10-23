package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	networkingv1 "k8s.io/api/networking/v1"
	policyv1 "k8s.io/api/policy/v1"
)

#MariaDBNetworkPolicy: networkingv1.#NetworkPolicy & {
	#config:    #Config
	apiVersion: "networking.k8s.io/v1"
	kind:       "NetworkPolicy"
	metadata: {
		name:      #config.#mariadbFullname
		namespace: #config.metadata.namespace
		labels:    #config.#mariadbLabels
	}
	spec: networkingv1.#NetworkPolicySpec & {
		podSelector: {
			matchLabels: {
				"app.kubernetes.io/instance":   #config.metadata.name
				"app.kubernetes.io/managed-by": "timoni"
				"app.kubernetes.io/name":       "mariadb"
				"app.kubernetes.io/version":    "12.0.2"
			}
		}
		policyTypes: [
			"Ingress",
			"Egress",
		]
		egress: [
			{},
		]
		ingress: [
			{
				ports: [
					{
						port: #config.mariadb.primary.service.ports.mysql
					},
				]
			},
		]
	}
}

#MariaDBPodDisruptionBudget: policyv1.#PodDisruptionBudget & {
	#config:    #Config
	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      #config.#mariadbFullname
		namespace: #config.metadata.namespace
		labels:    #config.#mariadbPrimaryLabels
	}
	spec: policyv1.#PodDisruptionBudgetSpec & {
		maxUnavailable: 1
		selector: {
			matchLabels: {
				"app.kubernetes.io/instance":  #config.metadata.name
				"app.kubernetes.io/name":      "mariadb"
				"app.kubernetes.io/component": "primary"
			}
		}
	}
}

#MariaDBServiceAccount: corev1.#ServiceAccount & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name:      #config.#mariadbFullname
		namespace: #config.metadata.namespace
		labels:    #config.#mariadbLabels
	}
	automountServiceAccountToken: false
}

#MariaDBSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config.#mariadbFullname
		namespace: #config.metadata.namespace
		labels:    #config.#mariadbLabels
	}
	type: corev1.#SecretTypeOpaque
	stringData: {
		"mariadb-root-password": #config.#mariadbRootPassword
		"mariadb-password":      #config.mariadb.auth.password
	}
}

#MariaDBConfigMap: corev1.#ConfigMap & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      #config.#mariadbFullname
		namespace: #config.metadata.namespace
		labels:    #config.#mariadbPrimaryLabels
	}
	data: {
		"my.cnf": #config.#mariadbMyCnf
	}
}

#MariaDBHeadlessService: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.#mariadbFullname)-headless"
		namespace: #config.metadata.namespace
		labels:    #config.#mariadbLabels
	}
	spec: corev1.#ServiceSpec & {
		type:                     corev1.#ServiceTypeClusterIP
		publishNotReadyAddresses: true
		clusterIP:                "None"
		ports: [
			{
				name:       "mysql"
				port:       #config.mariadb.primary.service.ports.mysql
				protocol:   "TCP"
				targetPort: "mysql"
			},
		]
		selector: {
			"app.kubernetes.io/instance": #config.metadata.name
			"app.kubernetes.io/name":     "mariadb"
			"app.kubernetes.io/part-of":  "mariadb"
		}
	}
}

#MariaDBService: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #config.#mariadbFullname
		namespace: #config.metadata.namespace
		labels:    #config.#mariadbPrimaryLabels
	}
	spec: corev1.#ServiceSpec & {
		type:            corev1.#ServiceTypeClusterIP
		sessionAffinity: "None"
		ports: [
			{
				name:       "mysql"
				port:       #config.mariadb.primary.service.ports.mysql
				protocol:   "TCP"
				targetPort: "mysql"
			},
		]
		selector: {
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/name":      "mariadb"
			"app.kubernetes.io/component": "primary"
		}
	}
}

#MariaDBStatefulSet: appsv1.#StatefulSet & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      #config.#mariadbFullname
		namespace: #config.metadata.namespace
		labels:    #config.#mariadbPrimaryLabels
	}
	spec: appsv1.#StatefulSetSpec & {
		replicas:             1
		revisionHistoryLimit: 10
		selector: {
			matchLabels: {
				"app.kubernetes.io/instance":  #config.metadata.name
				"app.kubernetes.io/name":      "mariadb"
				"app.kubernetes.io/part-of":   "mariadb"
				"app.kubernetes.io/component": "primary"
			}
		}
		serviceName: "\(#config.#mariadbFullname)-headless"
		updateStrategy: {
			type: "RollingUpdate"
		}
		template: {
			metadata: {
				annotations: {
					"checksum/configuration": #config.#mariadbConfigChecksum
				}
				labels: #config.#mariadbPrimaryLabels
			}
			spec: corev1.#PodSpec & {
				automountServiceAccountToken: false
				serviceAccountName:           #config.#mariadbFullname
				affinity: {
					podAntiAffinity: {
						preferredDuringSchedulingIgnoredDuringExecution: [
							{
								podAffinityTerm: {
									labelSelector: {
										matchLabels: {
											"app.kubernetes.io/instance":  #config.metadata.name
											"app.kubernetes.io/name":      "mariadb"
											"app.kubernetes.io/component": "primary"
										}
									}
									topologyKey: "kubernetes.io/hostname"
								}
								weight: 1
							},
						]
					}
				}
				securityContext: #config.mariadb.primary.podSecurityContext
				initContainers: [
					{
						name:            "preserve-logs-symlinks"
						image:           #config.mariadb.image.reference
						imagePullPolicy: #config.mariadb.image.pullPolicy
						securityContext: #config.mariadb.primary.containerSecurityContext
						command: [
							"/bin/bash",
						]
						args: [
							"-ec",
							"""
							#!/bin/bash

							. /opt/bitnami/scripts/libfs.sh
							# We copy the logs folder because it has symlinks to stdout and stderr
							if ! is_dir_empty /opt/bitnami/mariadb/logs; then
							  cp -r /opt/bitnami/mariadb/logs /emptydir/app-logs-dir
							fi
							""",
						]
						volumeMounts: [
							{
								name:      "empty-dir"
								mountPath: "/emptydir"
							},
						]
					},
				]
				containers: [
					{
						name:            "mariadb"
						image:           #config.mariadb.image.reference
						imagePullPolicy: #config.mariadb.image.pullPolicy
						securityContext: #config.mariadb.primary.containerSecurityContext
						env: [
							{
								name:  "BITNAMI_DEBUG"
								value: "false"
							},
							{
								name:  "MARIADB_ROOT_PASSWORD_FILE"
								value: "/opt/bitnami/mariadb/secrets/mariadb-root-password"
							},
							{
								name:  "MARIADB_USER"
								value: #config.mariadb.auth.username
							},
							{
								name:  "MARIADB_PASSWORD_FILE"
								value: "/opt/bitnami/mariadb/secrets/mariadb-password"
							},
							{
								name:  "MARIADB_DATABASE"
								value: #config.mariadb.auth.database
							},
							{
								name:  "MARIADB_ENABLE_SSL"
								value: "no"
							},
						]
						ports: [
							{
								name:          "mysql"
								containerPort: 3306
							},
						]
						livenessProbe: {
							failureThreshold:    3
							initialDelaySeconds: 120
							periodSeconds:       10
							successThreshold:    1
							timeoutSeconds:      1
							exec: {
								command: [
									"/bin/bash",
									"-ec",
									"""
									password_aux="${MARIADB_ROOT_PASSWORD:-}"
									if [[ -f "${MARIADB_ROOT_PASSWORD_FILE:-}" ]]; then
									    password_aux=$(cat "$MARIADB_ROOT_PASSWORD_FILE")
									fi
									mariadb-admin status -uroot -p"${password_aux}"
									""",
								]
							}
						}
						readinessProbe: {
							failureThreshold:    3
							initialDelaySeconds: 30
							periodSeconds:       10
							successThreshold:    1
							timeoutSeconds:      1
							exec: {
								command: [
									"/bin/bash",
									"-ec",
									"""
									password_aux="${MARIADB_ROOT_PASSWORD:-}"
									if [[ -f "${MARIADB_ROOT_PASSWORD_FILE:-}" ]]; then
									    password_aux=$(cat "$MARIADB_ROOT_PASSWORD_FILE")
									fi
									mariadb-admin ping -uroot -p"${password_aux}"
									""",
								]
							}
						}
						resources: #config.mariadb.primary.resources
						volumeMounts: [
							{
								name:      "data"
								mountPath: "/bitnami/mariadb"
							},
							{
								name:      "config"
								mountPath: "/opt/bitnami/mariadb/conf/my.cnf"
								subPath:   "my.cnf"
							},
							{
								name:      "mariadb-credentials"
								mountPath: "/opt/bitnami/mariadb/secrets/"
							},
							{
								name:      "empty-dir"
								mountPath: "/tmp"
								subPath:   "tmp-dir"
							},
							{
								name:      "empty-dir"
								mountPath: "/opt/bitnami/mariadb/conf"
								subPath:   "app-conf-dir"
							},
							{
								name:      "empty-dir"
								mountPath: "/opt/bitnami/mariadb/tmp"
								subPath:   "app-tmp-dir"
							},
							{
								name:      "empty-dir"
								mountPath: "/opt/bitnami/mariadb/logs"
								subPath:   "app-logs-dir"
							},
						]
					},
				]
				volumes: [
					{
						name:     "empty-dir"
						emptyDir: {}
					},
					{
						name: "config"
						configMap: {
							name: #config.#mariadbFullname
						}
					},
					{
						name: "mariadb-credentials"
						secret: {
							secretName: #config.#databaseSecretName
							items: [
								{
									key:  "mariadb-root-password"
									path: "mariadb-root-password"
								},
								{
									key:  "mariadb-password"
									path: "mariadb-password"
								},
							]
						}
					},
					if !#config.mariadb.primary.persistence.enabled {
						{
							name:     "data"
							emptyDir: {}
						}
					},
					if #config.mariadb.primary.persistence.enabled && #config.mariadb.primary.persistence.existingClaim != "" {
						{
							name: "data"
							persistentVolumeClaim: {
								claimName: #config.mariadb.primary.persistence.existingClaim
							}
						}
					},
				]
			}
		}
		if #config.mariadb.primary.persistence.enabled && #config.mariadb.primary.persistence.existingClaim == "" {
			volumeClaimTemplates: [
				{
					apiVersion: "v1"
					kind:       "PersistentVolumeClaim"
					metadata: {
						name: "data"
						labels: {
							"app.kubernetes.io/instance":  #config.metadata.name
							"app.kubernetes.io/name":      "mariadb"
							"app.kubernetes.io/component": "primary"
						}
					}
					spec: {
						accessModes: [
							#config.mariadb.primary.persistence.accessMode,
						]
						if #config.mariadb.primary.persistence.storageClass != "" {
							storageClassName: #config.mariadb.primary.persistence.storageClass
						}
						resources: {
							requests: {
								storage: #config.mariadb.primary.persistence.size
							}
						}
					}
				},
			]
		}
	}
}

