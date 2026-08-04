package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#MongodbStatefulSet: appsv1.#StatefulSet & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	_labels: {
		"app.kubernetes.io/name":      "\(#config.metadata.name)-mongodb"
		"app.kubernetes.io/instance":  #config.metadata.name
		"app.kubernetes.io/component": "mongodb"
		"app.kubernetes.io/version":   #config.mongodb.image.tag
		"app.kubernetes.io/managed-by": "timoni"
	}
	metadata: {
		name:      "\(#config.metadata.name)-mongodb"
		namespace: #config.metadata.namespace
		labels:    _labels
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
			metadata: labels: {
				"app.kubernetes.io/name":      "\(#config.metadata.name)-mongodb"
				"app.kubernetes.io/instance":  #config.metadata.name
				"app.kubernetes.io/component": "mongodb"
			}
			spec: corev1.#PodSpec & {
				containers: [{
					name:  "mongodb"
					image: #config.mongodb.image.reference
					imagePullPolicy: #config.mongodb.image.pullPolicy
					ports: [{
						name:          "mongodb"
						containerPort: 27017
						protocol:      "TCP"
					}]
					env: [
						if #config.mongodb.auth.enabled {
							{
								name:  "MONGO_INITDB_ROOT_USERNAME"
								value: #config.mongodb.auth.rootUser
							}
						},
						if #config.mongodb.auth.enabled {
							{
								name: "MONGO_INITDB_ROOT_PASSWORD"
								valueFrom: secretKeyRef: {
									name: #config.mongodbSecretName
									key:  "mongodb-root-password"
								}
							}
						},
						for envVar in #config.mongodb.extraEnvVars {
							envVar
						},
					]
					volumeMounts: [{
						name:      "data"
						mountPath: "/data/db"
					}]
				}]
			}
		}
		volumeClaimTemplates: [{
			metadata: name: "data"
			spec: corev1.#PersistentVolumeClaimSpec & {
				accessModes: ["ReadWriteOnce"]
				resources: requests: storage: "8Gi"
			}
		}]
	}
}

#MongodbService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	_labels: {
		"app.kubernetes.io/name":      "\(#config.metadata.name)-mongodb"
		"app.kubernetes.io/instance":  #config.metadata.name
		"app.kubernetes.io/component": "mongodb"
		"app.kubernetes.io/version":   #config.mongodb.image.tag
		"app.kubernetes.io/managed-by": "timoni"
	}
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-mongodb"
		namespace: #config.metadata.namespace
		labels:    _labels
	}
	spec: corev1.#ServiceSpec & {
		selector: {
			"app.kubernetes.io/name":      "\(#config.metadata.name)-mongodb"
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "mongodb"
		}
		ports: [{
			name:       "mongodb"
			port:       27017
			targetPort: 27017
			protocol:   "TCP"
		}]
	}
}

#MongodbSecret: corev1.#Secret & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	_labels: {
		"app.kubernetes.io/name":      "\(#config.metadata.name)-mongodb"
		"app.kubernetes.io/instance":  #config.metadata.name
		"app.kubernetes.io/component": "mongodb"
		"app.kubernetes.io/version":   #config.mongodb.image.tag
		"app.kubernetes.io/managed-by": "timoni"
	}
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-mongodb"
		namespace: #config.metadata.namespace
		labels:    _labels
	}
	type: "Opaque"
	stringData: {
		if #config.mongodb.auth.rootPassword == "" {
			"mongodb-root-password": "root"
		}
		if #config.mongodb.auth.rootPassword != "" {
			"mongodb-root-password": #config.mongodb.auth.rootPassword
		}
	}
}
