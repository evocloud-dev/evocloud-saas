package templates

import (
	"struct"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#MongodbStatefulSet: appsv1.#StatefulSet & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(#config.metadata.name)-mongodb"
		namespace: #config.metadata.namespace
		labels: {
			"app.kubernetes.io/name":       "\(#config.metadata.name)-mongodb"
			"app.kubernetes.io/instance":   #config.metadata.name
			"app.kubernetes.io/component":  "mongodb"
			"app.kubernetes.io/version":    #config.mongodb.image.tag
			"app.kubernetes.io/managed-by": "timoni"
		}
	}
	spec: appsv1.#StatefulSetSpec & {
		serviceName: metadata.name
		replicas:    1
		selector: matchLabels: {
			"app.kubernetes.io/name":      "\(#config.metadata.name)-mongodb"
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "mongodb"
		}
		template: {
			metadata: {
				labels: {
					"app.kubernetes.io/name":      "\(#config.metadata.name)-mongodb"
					"app.kubernetes.io/instance":  #config.metadata.name
					"app.kubernetes.io/component": "mongodb"
				}
			}
			spec: corev1.#PodSpec & {
				automountServiceAccountToken: false
				if struct.MinFields(#config.mongodb.podSecurityContext, 1) {
					securityContext: #config.mongodb.podSecurityContext
				}
				containers: [
					{
						name:            "mongodb"
						image:           "\(#config.mongodb.image.registry)/\(#config.mongodb.image.repository):\(#config.mongodb.image.tag)"
						imagePullPolicy: #config.mongodb.image.pullPolicy
						ports: [
							{
								name:          "mongodb"
								containerPort: 27017
								protocol:      "TCP"
							},
						]
						env: [
							if #config.mongodb.auth.enabled {
								{
									name:  "MONGO_INITDB_ROOT_USERNAME"
									value: "root"
								}
							},
							if #config.mongodb.auth.enabled {
								{
									name: "MONGO_INITDB_ROOT_PASSWORD"
									valueFrom: corev1.#EnvVarSource & {
										secretKeyRef: corev1.#SecretKeySelector & {
											name: "\(#config.metadata.name)-mongodb"
											key:  "mongodb-root-password"
										}
									}
								}
							},
						]
						if struct.MinFields(#config.mongodb.securityContext, 1) {
						securityContext: #config.mongodb.securityContext
					    }
						if #config.mongodb.resources != _|_ {
							resources: #config.mongodb.resources
						}
						volumeMounts: [
							{
								name:      "data"
								mountPath: "/data/db"
							},
						]
					},
				]
			}
		}
		volumeClaimTemplates: [
			{
				metadata: name: "data"
				spec: corev1.#PersistentVolumeClaimSpec & {
					accessModes: ["ReadWriteOnce"]
					resources: requests: storage: "8Gi"
				}
			},
		]
	}
}

#MongodbDeployment: appsv1.#Deployment & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-mongodb"
		namespace: #config.metadata.namespace
		labels: {
			"app.kubernetes.io/name":       "\(#config.metadata.name)-mongodb"
			"app.kubernetes.io/instance":   #config.metadata.name
			"app.kubernetes.io/component":  "mongodb"
			"app.kubernetes.io/version":    #config.mongodb.image.tag
			"app.kubernetes.io/managed-by": "timoni"
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: 1
		selector: matchLabels: {
			"app.kubernetes.io/name":      "\(#config.metadata.name)-mongodb"
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "mongodb"
		}
		template: {
			metadata: {
				labels: {
					"app.kubernetes.io/name":      "\(#config.metadata.name)-mongodb"
					"app.kubernetes.io/instance":  #config.metadata.name
					"app.kubernetes.io/component": "mongodb"
				}
			}
			spec: corev1.#PodSpec & {
				containers: [
					{
						name:            "mongodb"
						image:           "\(#config.mongodb.image.registry)/\(#config.mongodb.image.repository):\(#config.mongodb.image.tag)"
						imagePullPolicy: #config.mongodb.image.pullPolicy
						ports: [
							{
								name:          "mongodb"
								containerPort: 27017
								protocol:      "TCP"
							},
						]
						env: [
							if #config.mongodb.auth.enabled {
								{
									name:  "MONGO_INITDB_ROOT_USERNAME"
									value: "root"
								}
							},
							if #config.mongodb.auth.enabled {
								{
									name: "MONGO_INITDB_ROOT_PASSWORD"
									valueFrom: corev1.#EnvVarSource & {
										secretKeyRef: corev1.#SecretKeySelector & {
											name: "\(#config.metadata.name)-mongodb"
											key:  "mongodb-root-password"
										}
									}
								}
							},
						]
						volumeMounts: [
							{
								name:      "data"
								mountPath: "/data/db"
							},
						]
					},
				]
				volumes: [
					{
						name: "data"
						emptyDir: {}
					},
				]
			}
		}
	}
}

#MongodbService: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-mongodb"
		namespace: #config.metadata.namespace
		labels: {
			"app.kubernetes.io/name":       "\(#config.metadata.name)-mongodb"
			"app.kubernetes.io/instance":   #config.metadata.name
			"app.kubernetes.io/component":  "mongodb"
			"app.kubernetes.io/version":    #config.mongodb.image.tag
			"app.kubernetes.io/managed-by": "timoni"
		}
	}
	spec: corev1.#ServiceSpec & {
		selector: {
			"app.kubernetes.io/name":      "\(#config.metadata.name)-mongodb"
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "mongodb"
		}
		ports: [
			{
				name:       "mongodb"
				port:       27017
				targetPort: 27017
				protocol:   "TCP"
			},
		]
	}
}

#MongodbSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-mongodb"
		namespace: #config.metadata.namespace
		labels: {
			"app.kubernetes.io/name":       "\(#config.metadata.name)-mongodb"
			"app.kubernetes.io/instance":   #config.metadata.name
			"app.kubernetes.io/component":  "mongodb"
			"app.kubernetes.io/version":    #config.mongodb.image.tag
			"app.kubernetes.io/managed-by": "timoni"
		}
	}
	type: "Opaque"
	stringData: {
		"mongodb-root-password": #config.mongodb.auth.password
	}
}
