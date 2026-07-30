package templates

import (
	corev1 "k8s.io/api/core/v1"
)

// #TestConnection defines a test pod that verifies the NetBox web service
// is reachable at its internal Service address. This is the Timoni equivalent
// of the Helm test hook in templates/tests/test-connection.yaml.
// Run with: timoni test <instance-name> -n <namespace>
#TestConnection: corev1.#Pod & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Pod"
	metadata: {
		name:      "\(#config._fullname)-test-connection"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "test"
		}
		annotations: {
			if #config.commonAnnotations != _|_ {
				for k, v in #config.commonAnnotations {
					"\(k)": v
				}
			}
		}
	}
	spec: corev1.#PodSpec & {
		restartPolicy: "Never"
		if #config.test.securityContext.enabled {
			securityContext: {
				runAsUser:                #config.test.securityContext.runAsUser
				runAsGroup:               #config.test.securityContext.runAsGroup
				runAsNonRoot:             #config.test.securityContext.runAsNonRoot
				readOnlyRootFilesystem:   #config.test.securityContext.readOnlyRootFilesystem
				allowPrivilegeEscalation: #config.test.securityContext.allowPrivilegeEscalation
				if #config.test.securityContext.seccompProfile != _|_ {
					seccompProfile: #config.test.securityContext.seccompProfile
				}
				if #config.test.securityContext.capabilities != _|_ {
					capabilities: #config.test.securityContext.capabilities
				}
			}
		}
		containers: [
			{
				name: "wget"
				image: {
					#registry: {
						if #config.global.imageRegistry != "" { #config.global.imageRegistry }
						if #config.global.imageRegistry == "" { #config.test.image.registry }
					}
					#tag: {
						if #config.test.image.digest != "" { "@\(#config.test.image.digest)" }
						if #config.test.image.digest == "" { ":\(#config.test.image.tag)" }
					}
					"\(#registry)/\(#config.test.image.repository)\(#tag)"
				}
				imagePullPolicy: #config.test.image.pullPolicy
				command: ["wget"]
				args: ["\(#config._fullname):\(#config.service.port)"]
				resources: #config.test.resources
			},
		]
	}
}
