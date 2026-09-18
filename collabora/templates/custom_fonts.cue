package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#CustomFontsPVC: corev1.#PersistentVolumeClaim & {
	#config: #Config
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "\(#config.metadata.name)-custom-fonts"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: [#config.deployment.customFonts.pvc.accessMode]
		resources: requests: storage: #config.deployment.customFonts.pvc.size
		if #config.deployment.customFonts.pvc.storageClassName != _|_ {
			storageClassName: #config.deployment.customFonts.pvc.storageClassName
		}
	}
}

#CustomFontsPod: corev1.#Pod & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Pod"
	metadata: {
		name:      "\(#config.metadata.name)-custom-fonts"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
	spec: corev1.#PodSpec & {
		restartPolicy: "Never"
		containers: [{
			name:            "\(#config.metadata.name)-custom-fonts"
			securityContext: #config.securityContext
			image:           "\(#config.deployment.customFonts.image.repository):\(#config.deployment.customFonts.image.tag)"
			command: ["sleep", "3600"]
			volumeMounts: [{
				mountPath: "/mnt/fonts"
				name:      "fonts"
			}]
		}]
		volumes: [{
			name: "fonts"
			persistentVolumeClaim: claimName: "\(#config.metadata.name)-custom-fonts"
		}]
	}
}

