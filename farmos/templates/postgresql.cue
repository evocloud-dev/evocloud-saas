package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#PostgresqlSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config._fullname)-postgresql"
		namespace: #config.metadata.namespace
		labels:    #config._labels & {
			"app.kubernetes.io/component": "postgresql"
		}
	}
	type: corev1.#SecretTypeOpaque
	stringData: {
		POSTGRES_DB:       #config.postgresql.auth.database
		POSTGRES_USER:     #config.postgresql.auth.username
		POSTGRES_PASSWORD: #config.postgresql.auth.password
	}
}

#PostgresqlService: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config._fullname)-postgresql"
		namespace: #config.metadata.namespace
		labels:    #config._labels & {
			"app.kubernetes.io/component": "postgresql"
			"service.name":                "postgresql"
		}
	}
	spec: corev1.#ServiceSpec & {
		type:                     corev1.#ServiceTypeClusterIP
		publishNotReadyAddresses: false
		ports: [
			{
				name:       "postgresql"
				port:       #config.postgresql.service.port
				protocol:   corev1.#ProtocolTCP
				targetPort: 5432
			},
		]
		selector: {
			"app.kubernetes.io/name":      #config.metadata.name
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "postgresql"
			"pod.name":                    "postgresql"
		}
	}
}

#PostgresqlStatefulSet: appsv1.#StatefulSet & {
	#config: #Config

	_pgSelectorLabels: {
		"app.kubernetes.io/name":      #config.metadata.name
		"app.kubernetes.io/instance":  #config.metadata.name
		"app.kubernetes.io/component": "postgresql"
		"pod.name":                    "postgresql"
	}

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(#config._fullname)-postgresql"
		namespace: #config.metadata.namespace
		labels:    #config._labels & {
			"app.kubernetes.io/component": "postgresql"
		}
	}
	spec: appsv1.#StatefulSetSpec & {
		serviceName:          "\(#config._fullname)-postgresql"
		replicas:             1
		revisionHistoryLimit: 3
		selector: {
			matchLabels: _pgSelectorLabels
		}
		template: {
			metadata: {
				labels: #config._labels & _pgSelectorLabels & {
					"pod.lifecycle": "permanent"
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           "default"
				automountServiceAccountToken: false
				hostNetwork:                  false
				hostPID:                      false
				hostIPC:                      false
				shareProcessNamespace:        false
				enableServiceLinks:           false
				restartPolicy:                "Always"
				nodeSelector:                 #config.nodeSelector
				terminationGracePeriodSeconds: 60
				securityContext: {
					fsGroup:             999
					fsGroupChangePolicy: "OnRootMismatch"
					supplementalGroups:  [999]
				}
				containers: [
					{
						name:            "postgresql"
						image:           #config.postgresql.image.reference
						imagePullPolicy: #config.postgresql.image.pullPolicy
						tty:             false
						stdin:           false
						ports: [
							{
								name:          "postgresql"
								containerPort: 5432
								protocol:      "TCP"
							},
						]
						env: [
							{
								name:  "TZ"
								value: #config.tz
							},
							{
								name:  "PGDATA"
								value: "/var/lib/postgresql/data/pgdata"
							},
							{
								name: "POSTGRES_DB"
								valueFrom: {
									secretKeyRef: {
										name: "\(#config._fullname)-postgresql"
										key:  "POSTGRES_DB"
									}
								}
							},
							{
								name: "POSTGRES_USER"
								valueFrom: {
									secretKeyRef: {
										name: "\(#config._fullname)-postgresql"
										key:  "POSTGRES_USER"
									}
								}
							},
							{
								name: "POSTGRES_PASSWORD"
								valueFrom: {
									secretKeyRef: {
										name: "\(#config._fullname)-postgresql"
										key:  "POSTGRES_PASSWORD"
									}
								}
							},
						]
						volumeMounts: [
							{
								name:      "devshm"
								mountPath: "/dev/shm"
								readOnly:  false
							},
							{
								name:      "tmp"
								mountPath: "/tmp"
								readOnly:  false
							},
							{
								name:      "varrun"
								mountPath: "/var/run/postgresql"
								readOnly:  false
							},
							{
								name:      "pgdata"
								mountPath: "/var/lib/postgresql/data"
								readOnly:  false
							},
						]
						livenessProbe: {
							exec: {
								command: [
									"sh",
									"-c",
									"pg_isready -U \"$POSTGRES_USER\" -d \"$POSTGRES_DB\" -h 127.0.0.1 -p 5432",
								]
							}
							initialDelaySeconds: 15
							failureThreshold:    5
							successThreshold:    1
							timeoutSeconds:      5
							periodSeconds:       15
						}
						readinessProbe: {
							exec: {
								command: [
									"sh",
									"-c",
									"pg_isready -U \"$POSTGRES_USER\" -d \"$POSTGRES_DB\" -h 127.0.0.1 -p 5432",
								]
							}
							initialDelaySeconds: 10
							failureThreshold:    5
							successThreshold:    1
							timeoutSeconds:      5
							periodSeconds:       10
						}
						startupProbe: {
							exec: {
								command: [
									"sh",
									"-c",
									"pg_isready -U \"$POSTGRES_USER\" -d \"$POSTGRES_DB\" -h 127.0.0.1 -p 5432",
								]
							}
							initialDelaySeconds: 5
							failureThreshold:    30
							successThreshold:    1
							timeoutSeconds:      3
							periodSeconds:       5
						}
						resources: #config.postgresql.resources
						securityContext: {
							runAsNonRoot:             true
							runAsUser:                999
							runAsGroup:               999
							readOnlyRootFilesystem:   true
							allowPrivilegeEscalation: false
							privileged:               false
							seccompProfile: {
								type: "RuntimeDefault"
							}
							capabilities: {
								drop: ["ALL"]
							}
						}
					},
				]
				volumes: [
					{
						name: "devshm"
						emptyDir: {
							medium:    "Memory"
							sizeLimit: "512Mi"
						}
					},
					{
						name: "tmp"
						emptyDir: {
							medium:    "Memory"
							sizeLimit: "512Mi"
						}
					},
					{
						name: "varrun"
						emptyDir: {
							medium:    "Memory"
							sizeLimit: "128Mi"
						}
					},
					if !#config.postgresql.persistence.enabled {
						{
							name:     "pgdata"
							emptyDir: {}
						}
					},
				]
				if #config.tolerations != _|_ {
					tolerations: #config.tolerations
				}
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
			}
		}
		if #config.postgresql.persistence.enabled {
			volumeClaimTemplates: [
				{
					metadata: {
						name: "pgdata"
						labels: #config._labels & {
							"app.kubernetes.io/component": "postgresql"
						}
					}
					spec: corev1.#PersistentVolumeClaimSpec & {
						accessModes: #config.postgresql.persistence.accessModes
						resources: {
							requests: {
								storage: #config.postgresql.persistence.size
							}
						}
						if #config.postgresql.persistence.storageClass != _|_ {
							if #config.postgresql.persistence.storageClass != "" {
								storageClassName: #config.postgresql.persistence.storageClass
							}
						}
					}
				},
			]
		}
	}
}