package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)

#MinioSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-minio"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	stringData: {
		"rootUser": #config.minio.auth.rootUser
		"rootPassword": #config.minio.auth.rootPassword
	}
}

#MinioService: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-minio"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: {
		type: #config.minio.service.type
		if #config.minio.service.type == "ClusterIP" && #config.minio.service.clusterIP != _|_ {
			clusterIP: #config.minio.service.clusterIP
		}
		if #config.minio.service.type == "LoadBalancer" || #config.minio.service.type == "NodePort" {
			if #config.minio.service.externalTrafficPolicy != _|_ {
				externalTrafficPolicy: #config.minio.service.externalTrafficPolicy
			}
		}
		if #config.minio.service.type == "LoadBalancer" {
			if #config.minio.service.loadBalancerIP != _|_ {
				loadBalancerIP: #config.minio.service.loadBalancerIP
			}
			if #config.minio.service.loadBalancerSourceRanges != _|_ {
				loadBalancerSourceRanges: #config.minio.service.loadBalancerSourceRanges
			}
		}
		selector: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-minio"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		ports: [
			{
				name:       "minio-api"
				port:       #config.minio.service.port
				targetPort: 9000
				if (#config.minio.service.type == "NodePort" || #config.minio.service.type == "LoadBalancer") && #config.minio.service.nodePort != _|_ {
					nodePort: #config.minio.service.nodePort
				}
			},
			{
				name:       "minio-console"
				port:       #config.minio.service.consolePort
				targetPort: 9001
				if (#config.minio.service.type == "NodePort" || #config.minio.service.type == "LoadBalancer") && #config.minio.service.consoleNodePort != _|_ {
					nodePort: #config.minio.service.consoleNodePort
				}
			},
		]
	}
}

#MinioStatefulSet: appsv1.#StatefulSet & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(#config.metadata.name)-minio"
		namespace: #config.metadata.namespace
		labels: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-minio"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
	spec: {
		replicas: 1
		selector: matchLabels: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-minio"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		serviceName: "\(#config.metadata.name)-minio"
		template: {
			metadata: labels: {
				"app.kubernetes.io/name":     "\(#config.metadata.name)-minio"
				"app.kubernetes.io/instance": #config.metadata.name
			}
			spec: {
				automountServiceAccountToken: false
				serviceAccountName: "\(#config.metadata.name)-minio"
				if #config.minio.podSecurityContext != _|_ {
					securityContext: #config.minio.podSecurityContext
				}
				containers: [
					{
						name:            "minio"
						image:           "\(#config.minio.image.registry)/\(#config.minio.image.repository):\(#config.minio.image.tag)"
						imagePullPolicy: "IfNotPresent"
						env: [
							{
								name: "MINIO_ROOT_USER"
								valueFrom: secretKeyRef: {
									name: "\(#config.metadata.name)-minio"
									key:  "rootUser"
								}
							},
							{
								name: "MINIO_ROOT_PASSWORD"
								valueFrom: secretKeyRef: {
									name: "\(#config.metadata.name)-minio"
									key:  "rootPassword"
								}
							},
						]
						args: [
							"server",
							"/data",
							"--console-address",
							":9001",
						]
						ports: [
							{
								name:          "minio-api"
								containerPort: 9000
							},
							{
								name:          "minio-console"
								containerPort: 9001
							},
						]
						livenessProbe: {
							httpGet: {
								path: "/minio/health/live"
								port: "minio-api"
								scheme: "HTTP"
							}
							initialDelaySeconds: 5
							periodSeconds: 5
							timeoutSeconds: 5
							successThreshold: 1
							failureThreshold: 5
						}
						readinessProbe: {
							tcpSocket: {
								port: "minio-api"
							}
							initialDelaySeconds: 5
							periodSeconds: 5
							timeoutSeconds: 1
							successThreshold: 1
							failureThreshold: 5
						}
						startupProbe: {
							tcpSocket: {
								port: "minio-console"
							}
							initialDelaySeconds: 0
							periodSeconds: 5
							timeoutSeconds: 1
							successThreshold: 1
							failureThreshold: 60
						}
						if #config.minio.resources != _|_ {
							resources: #config.minio.resources
						}
						if #config.minio.securityContext != _|_ {
							securityContext: #config.minio.securityContext
						}
						if #config.minio.persistence.enabled {
							volumeMounts: [
								{
									name:      "minio-data"
									mountPath: "/data"
								},
							]
						}
					},
				]
			}
		}
		if #config.minio.persistence.enabled {
			volumeClaimTemplates: [
				{
					metadata: name: "minio-data"
					spec: {
						accessModes: #config.minio.persistence.accessModes
						if #config.minio.persistence.resources != _|_ {
							resources: #config.minio.persistence.resources
						}
						if #config.minio.persistence.storageClassName != "" {
							storageClassName: #config.minio.persistence.storageClassName
						}
					}
				},
			]
		}
	}
}

#MinioServiceAccount: corev1.#ServiceAccount & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name:      "\(#config.metadata.name)-minio"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
}
