package templates

import (
	"encoding/yaml"
	"uuid"

	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#TestJob: batchv1.#Job & {
	#config: #Config
	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "test"
	}
	metadata: annotations: timoniv1.Action.Force
	spec: batchv1.#JobSpec & {
		template: corev1.#PodTemplateSpec & {
			let _checksum = uuid.SHA1(uuid.ns.DNS, yaml.Marshal(#config))
			metadata: annotations: "timoni.sh/checksum": "\(_checksum)"
			spec: {
				containers: [{
					name:            "curl"
					image:           "docker.io/curlimages/curl:8.21.0"
					imagePullPolicy: "IfNotPresent"
					command: [
						"curl",
						"-v",
						"-m",
						"5",
						"\(#config.metadata.name):\(#config.service.main.ports.main.port)",
					]
				}]
				restartPolicy: "Never"
				nodeSelector:  *{"kubernetes.io/os": "linux"} | {[string]: string}
			}
		}
		backoffLimit: 1
	}
}
