package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)

// Valkey Cache
#ValkeyCacheDeployment: appsv1.#Deployment & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-valkey-cache"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: 1
		selector: matchLabels: "app.kubernetes.io/name": "\(#config.metadata.name)-valkey-cache"
		template: {
			metadata: labels: "app.kubernetes.io/name": "\(#config.metadata.name)-valkey-cache"
			spec: corev1.#PodSpec & {
				containers: [
					{
						name:            "valkey"
						image:           "\(#config["valkey-cache"].image.repository):\(#config["valkey-cache"].image.tag)"
						imagePullPolicy: "IfNotPresent"
						ports: [{containerPort: 6379, name: "redis"}]
						env: [{name: "ALLOW_EMPTY_PASSWORD", value: "yes"}]
					},
				]
			}
		}
	}
}

#ValkeyCacheService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-valkey-cache"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#ServiceSpec & {
		ports: [{port: 6379, targetPort: "redis", name: "redis"}]
		selector: "app.kubernetes.io/name": "\(#config.metadata.name)-valkey-cache"
	}
}

// Valkey Queue
#ValkeyQueueDeployment: appsv1.#Deployment & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-valkey-queue"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: 1
		selector: matchLabels: "app.kubernetes.io/name": "\(#config.metadata.name)-valkey-queue"
		template: {
			metadata: labels: "app.kubernetes.io/name": "\(#config.metadata.name)-valkey-queue"
			spec: corev1.#PodSpec & {
				containers: [
					{
						name:            "valkey"
						image:           "\(#config["valkey-queue"].image.repository):\(#config["valkey-queue"].image.tag)"
						imagePullPolicy: "IfNotPresent"
						ports: [{containerPort: 6379, name: "redis"}]
						env: [{name: "ALLOW_EMPTY_PASSWORD", value: "yes"}]
					},
				]
			}
		}
	}
}

#ValkeyQueueService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-valkey-queue"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#ServiceSpec & {
		ports: [{port: 6379, targetPort: "redis", name: "redis"}]
		selector: "app.kubernetes.io/name": "\(#config.metadata.name)-valkey-queue"
	}
}
