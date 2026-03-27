package templates

import (
	"encoding/yaml"
	"uuid"

	corev1 "k8s.io/api/core/v1"
	batchv1 "k8s.io/api/batch/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#TestJob: batchv1.#Job & {
	#in:    #Config
	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: timoniv1.#MetaComponent & {
		#Meta:      #in.metadata
		#Component: "test"
	}
	metadata: annotations: timoniv1.Action.Force
	spec: batchv1.#JobSpec & {
		template: corev1.#PodTemplateSpec & {
			let _checksum = uuid.SHA1(uuid.ns.DNS, yaml.Marshal(#in))
			metadata: annotations: "timoni.sh/checksum": "\(_checksum)"
			spec: {
				containers: [{
					name:            "curl"
					image:           #in.test.image.reference
					imagePullPolicy: #in.test.image.pullPolicy
					command: [
						"curl",
						"-v",
						"-m",
						"5",
						"\(#in.metadata.name):\(#in.service.port)",
					]
				}]
				restartPolicy: "Never"
				if #in.podSecurityContext != _|_ {
					securityContext: #in.podSecurityContext
				}
				if #in.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: #in.topologySpreadConstraints
				}
				if #in.affinity != _|_ {
					affinity: #in.affinity
				}
				if #in.tolerations != _|_ {
					tolerations: #in.tolerations
				}
				if #in.imagePullSecrets != _|_ {
					imagePullSecrets: #in.imagePullSecrets
				}
			}
		}
		backoffLimit: 1
	}
}
