package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)

// Redis Cache
#RedisCacheDeployment: appsv1.#Deployment & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-redis-cache-master"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: 1
		selector: matchLabels: "app.kubernetes.io/name": "\(#config.metadata.name)-redis-cache-master"
		template: {
			metadata: labels: "app.kubernetes.io/name": "\(#config.metadata.name)-redis-cache-master"
			spec: corev1.#PodSpec & {
				containers: [
					{
						name:            "redis"
						image:           "\(#config["redis-cache"].image.repository):\(#config["redis-cache"].image.tag)"
						imagePullPolicy: "IfNotPresent"
						ports: [{containerPort: 6379, name: "redis"}]
						env: [{name: "ALLOW_EMPTY_PASSWORD", value: "yes"}]
					},
				]
			}
		}
	}
}

#RedisCacheService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-redis-cache-master"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#ServiceSpec & {
		ports: [{port: 6379, targetPort: "redis", name: "redis"}]
		selector: "app.kubernetes.io/name": "\(#config.metadata.name)-redis-cache-master"
	}
}

// Redis Queue
#RedisQueueDeployment: appsv1.#Deployment & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-redis-queue-master"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: 1
		selector: matchLabels: "app.kubernetes.io/name": "\(#config.metadata.name)-redis-queue-master"
		template: {
			metadata: labels: "app.kubernetes.io/name": "\(#config.metadata.name)-redis-queue-master"
			spec: corev1.#PodSpec & {
				containers: [
					{
						name:            "redis"
						image:           "\(#config["redis-queue"].image.repository):\(#config["redis-queue"].image.tag)"
						imagePullPolicy: "IfNotPresent"
						ports: [{containerPort: 6379, name: "redis"}]
						env: [{name: "ALLOW_EMPTY_PASSWORD", value: "yes"}]
					},
				]
			}
		}
	}
}

#RedisQueueService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-redis-queue-master"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#ServiceSpec & {
		ports: [{port: 6379, targetPort: "redis", name: "redis"}]
		selector: "app.kubernetes.io/name": "\(#config.metadata.name)-redis-queue-master"
	}
}