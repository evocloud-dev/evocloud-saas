package templates

import (
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#TestJob: batchv1.#Job & {
	#config:    #Config
	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		name:      #config.#testName
		namespace: #config.metadata.namespace
		labels: #config.#allLabels & {
			"app.kubernetes.io/component": "test"
		}
		annotations: timoniv1.Action.Force
	}
	spec: batchv1.#JobSpec & {
		template: corev1.#PodTemplateSpec & {
			spec: {
				containers: [{
					name:            "wget"
					image:           #config.test.image.reference
					imagePullPolicy: #config.test.image.pullPolicy
					command: [
						"sh",
						"-ec",
						"wget -qO- http://\(#config.#fullname):\(#config.service.port)/api/health\nwget -qO- http://\(#config.#fullname):\(#config.service.port)/ | grep -qi opencut\n",
					]
					resources: {
						requests: {
							cpu:    "10m"
							memory: "16Mi"
						}
						limits: {
							cpu:    "100m"
							memory: "64Mi"
						}
					}
					securityContext: {
						allowPrivilegeEscalation: false
						readOnlyRootFilesystem:   true
						runAsNonRoot:             true
						runAsUser:                65534
						runAsGroup:               65534
						capabilities: drop: ["ALL"]
						seccompProfile: type: "RuntimeDefault"
					}
				}]
				restartPolicy: "Never"
				if len(#config.imagePullSecrets) > 0 {
					imagePullSecrets: #config.imagePullSecrets
				}
			}
		}
		backoffLimit: 1
	}
}
