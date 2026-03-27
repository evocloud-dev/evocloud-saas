package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)

// Dragonfly Cache
#DragonflyCacheDeployment: appsv1.#Deployment & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-dragonfly-cache"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: 1
		selector: matchLabels: "app.kubernetes.io/name": "\(#config.metadata.name)-dragonfly-cache"
		template: {
			metadata: labels: "app.kubernetes.io/name": "\(#config.metadata.name)-dragonfly-cache"
			spec: corev1.#PodSpec & {
				containers: [
					{
						name:            "dragonfly"
						image:           "\(#config["dragonfly-cache"].image.repository):\(#config["dragonfly-cache"].image.tag)"
						imagePullPolicy: #config["dragonfly-cache"].image.pullPolicy
						ports: [{containerPort: 6379, name: "redis"}]
						if #config["dragonfly-cache"].args != _|_ {
							args: #config["dragonfly-cache"].args
						}
					},
				]
			}
		}
	}
}

#DragonflyCacheService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-dragonfly-cache"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#ServiceSpec & {
		ports: [{port: 6379, targetPort: "redis", name: "redis"}]
		selector: "app.kubernetes.io/name": "\(#config.metadata.name)-dragonfly-cache"
	}
}

// Dragonfly Queue
#DragonflyQueueDeployment: appsv1.#Deployment & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-dragonfly-queue"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: 1
		selector: matchLabels: "app.kubernetes.io/name": "\(#config.metadata.name)-dragonfly-queue"
		template: {
			metadata: labels: "app.kubernetes.io/name": "\(#config.metadata.name)-dragonfly-queue"
			spec: corev1.#PodSpec & {
				containers: [
					{
						name:            "dragonfly"
						image:           "\(#config["dragonfly-queue"].image.repository):\(#config["dragonfly-queue"].image.tag)"
						if #config["dragonfly-queue"].args != _|_ {
							args: #config["dragonfly-queue"].args
						}
						imagePullPolicy: #config["dragonfly-queue"].image.pullPolicy
						ports: [{containerPort: 6379, name: "redis"}]
					},
				]
			}
		}
	}
}

#DragonflyQueueService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-dragonfly-queue"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#ServiceSpec & {
		ports: [{port: 6379, targetPort: "redis", name: "redis"}]
		selector: "app.kubernetes.io/name": "\(#config.metadata.name)-dragonfly-queue"
	}
}
