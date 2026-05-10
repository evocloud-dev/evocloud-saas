package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#SoketiDeployment: appsv1.#Deployment & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-soketi"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "soketi"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: #config.soketi.replicaCount
		selector: matchLabels: (timoniv1.#Selector & {#Name: #config.metadata.name}).labels & {
			"app.kubernetes.io/component": "soketi"
		}
		template: {
			metadata: {
				labels: (timoniv1.#Selector & {#Name: #config.metadata.name}).labels & {
					"app.kubernetes.io/component": "soketi"
				}
			}
			spec: corev1.#PodSpec & {
				securityContext: {
					runAsUser:    #config.securityContext.runAsUser
					runAsGroup:   #config.securityContext.runAsGroup
					fsGroup:      #config.securityContext.fsGroup
					runAsNonRoot: #config.securityContext.runAsNonRoot
				}
				containers: [
					{
						name:            "soketi"
						image:           "\(#config.soketi.image.repository):\(#config.soketi.image.tag)"
						imagePullPolicy: #config.soketi.image.pullPolicy
						ports: [
							{
								name:          "soketi-app"
								containerPort: 6001
							},
							{
								name:          "soketi-metrics"
								containerPort: 6002
							},
						]
						envFrom: [
							{configMapRef: name: "\(#config.metadata.name)-app-config"},
							{secretRef: name:    "\(#config.metadata.name)-app-secrets"},
						]
						volumeMounts: [
							{
								name:      "shared-data"
								mountPath: "/data"
								subPath:   "coolify/ssh"
							},
						]
						readinessProbe: exec: command: [
							"/bin/sh",
							"-c",
							"wget -qO- http://127.0.0.1:6001/ready && wget -qO- http://127.0.0.1:6002/ready",
						]
						livenessProbe: exec: command: [
							"/bin/sh",
							"-c",
							"wget -qO- http://127.0.0.1:6001/ready && wget -qO- http://127.0.0.1:6002/ready",
						]
						resources: #config.soketi.resources
					},
				]
				volumes: [
					{
						name: "shared-data"
						persistentVolumeClaim: claimName: "\(#config.metadata.name)-shared-data-pvc"
					},
				]
			}
		}
	}
}
