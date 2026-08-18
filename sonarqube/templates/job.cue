package templates

import (
	"encoding/yaml"
	"uuid"

	corev1 "k8s.io/api/core/v1"
	batchv1 "k8s.io/api/batch/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#TestJob: batchv1.#Job & {
	#config:    #Config
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
				restartPolicy:                "Never"
				automountServiceAccountToken: false
				securityContext: {
					runAsNonRoot: true
					runAsUser:    1000
					runAsGroup:   1000
					seccompProfile: type: "RuntimeDefault"
				}
				containers: [{
					name:            "wget"
					image:           "\(#config.tests.image.repository):\(#config.tests.image.tag)"
					imagePullPolicy: #config.tests.image.pullPolicy
					command: ["sh", "-ec"]
					args: [
						"wget -qO- \"http://\(#config.fullname):\(#config.service.port)\(#config._contextPath)/api/system/status\"",
					]
					securityContext: {
						allowPrivilegeEscalation: false
						readOnlyRootFilesystem:   true
						capabilities: drop: ["ALL"]
					}
					resources: #config.tests.resources
				}]
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
			}
		}
		backoffLimit: 1
	}
}
