package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#BeatStatefulSet: appsv1.#StatefulSet & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(#config.metadata.name)-celery-beat"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "celery-beat"
		}
	}
	spec: appsv1.#StatefulSetSpec & {
		replicas: 1
		updateStrategy: {
			type: "RollingUpdate"
			rollingUpdate: partition: 0
		}
		serviceName: "\(#config.metadata.name)-celery-beat"
		selector: matchLabels: (timoniv1.#Selector & {#Name: "\(#config.metadata.name)-celery-beat"}).labels & {
			"app.kubernetes.io/component": "celery-beat"
		}
		template: {
			metadata: {
				if #config.worker.podAnnotations != _|_ {
					annotations: #config.worker.podAnnotations
				}
				labels: (timoniv1.#Selector & {#Name: "\(#config.metadata.name)-celery-beat"}).labels & {
					"app.kubernetes.io/component": "celery-beat"
				}
			}
			spec: corev1.#PodSpec & {
				if #config.global.imagePullSecrets != [] {
					imagePullSecrets: #config.global.imagePullSecrets
				}
				serviceAccountName: #config.metadata.name
				securityContext: {
					runAsUser:  0
					runAsGroup: 0
				}
				containers: [
					{
						name: "saleor-celery-beat"
						if #config.securityContext != _|_ {
							securityContext: #config.securityContext
						}
						image:           "\(#config.global.image.repository):\(#config.global.image.tag)"
						imagePullPolicy: #config.global.image.pullPolicy
						command: ["celery", "--app", "saleor.celeryconf:app", "beat", "--scheduler", "saleor.schedulers.schedulers.DatabaseScheduler"]
						resources: {
							requests: {
								cpu:    #config.worker.scheduler.resources.requests.cpu
								memory: #config.worker.scheduler.resources.requests.memory
							}
							limits: {
								cpu:    #config.worker.scheduler.resources.limits.cpu
								memory: #config.worker.scheduler.resources.limits.memory
							}
						}
						env: #config.#internal.celeryEnv
					},
				]
				if #config.tolerations != _|_ {
					tolerations: #config.tolerations
				}
			}
		}
	}
}
