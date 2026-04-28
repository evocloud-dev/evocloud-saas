package templates

import (
	autoscalev2 "k8s.io/api/autoscaling/v2"
)

#APIHPA: autoscalev2.#HorizontalPodAutoscaler & {
	#config:    #Config
	apiVersion: "autoscaling/v2"
	kind:       "HorizontalPodAutoscaler"
	metadata: {
		name:      "\(#config.metadata.name)-api"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "api"
		}
	}
	spec: autoscalev2.#HorizontalPodAutoscalerSpec & {
		scaleTargetRef: {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			name:       "\(#config.metadata.name)-api"
		}
		minReplicas: #config.api.autoscaling.minReplicas
		maxReplicas: #config.api.autoscaling.maxReplicas
		metrics: [
			if #config.api.autoscaling.targetCPUUtilizationPercentage != _|_ {
				{
					type: "Resource"
					resource: {
						name: "cpu"
						target: {
							type:               "Utilization"
							averageUtilization: #config.api.autoscaling.targetCPUUtilizationPercentage
						}
					}
				}
			},
			if #config.api.autoscaling.targetMemoryUtilizationPercentage != _|_ {
				{
					type: "Resource"
					resource: {
						name: "memory"
						target: {
							type:               "Utilization"
							averageUtilization: #config.api.autoscaling.targetMemoryUtilizationPercentage
						}
					}
				}
			},
		]
	}
}

#WorkerHPA: autoscalev2.#HorizontalPodAutoscaler & {
	#config:    #Config
	apiVersion: "autoscaling/v2"
	kind:       "HorizontalPodAutoscaler"
	metadata: {
		name:      "\(#config.metadata.name)-worker"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "worker"
		}
	}
	spec: autoscalev2.#HorizontalPodAutoscalerSpec & {
		scaleTargetRef: {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			name:       "\(#config.metadata.name)-worker"
		}
		minReplicas: #config.worker.autoscaling.minReplicas
		maxReplicas: #config.worker.autoscaling.maxReplicas
		metrics: [
			if #config.worker.autoscaling.targetCPUUtilizationPercentage != _|_ {
				{
					type: "Resource"
					resource: {
						name: "cpu"
						target: {
							type:               "Utilization"
							averageUtilization: #config.worker.autoscaling.targetCPUUtilizationPercentage
						}
					}
				}
			},
			if #config.worker.autoscaling.targetMemoryUtilizationPercentage != _|_ {
				{
					type: "Resource"
					resource: {
						name: "memory"
						target: {
							type:               "Utilization"
							averageUtilization: #config.worker.autoscaling.targetMemoryUtilizationPercentage
						}
					}
				}
			},
		]
	}
}

#DashboardHPA: autoscalev2.#HorizontalPodAutoscaler & {
	#config:    #Config
	apiVersion: "autoscaling/v2"
	kind:       "HorizontalPodAutoscaler"
	metadata: {
		name:      "\(#config.metadata.name)-dashboard"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "dashboard"
		}
	}
	spec: autoscalev2.#HorizontalPodAutoscalerSpec & {
		scaleTargetRef: {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			name:       "\(#config.metadata.name)-dashboard"
		}
		minReplicas: #config.dashboard.autoscaling.minReplicas
		maxReplicas: #config.dashboard.autoscaling.maxReplicas
		metrics: [
			if #config.dashboard.autoscaling.targetCPUUtilizationPercentage != _|_ {
				{
					type: "Resource"
					resource: {
						name: "cpu"
						target: {
							type:               "Utilization"
							averageUtilization: #config.dashboard.autoscaling.targetCPUUtilizationPercentage
						}
					}
				}
			},
			if #config.dashboard.autoscaling.targetMemoryUtilizationPercentage != _|_ {
				{
					type: "Resource"
					resource: {
						name: "memory"
						target: {
							type:               "Utilization"
							averageUtilization: #config.dashboard.autoscaling.targetMemoryUtilizationPercentage
						}
					}
				}
			},
		]
	}
}
