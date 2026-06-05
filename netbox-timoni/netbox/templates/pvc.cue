package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#MediaPVC: corev1.#PersistentVolumeClaim & {
	#config: #Config

	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "\(#config._fullname)-media"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "netbox"
		}
		if #config.persistence.annotations != _|_ || #config.commonAnnotations != _|_ {
			annotations: {
				for k, v in #config.persistence.annotations {
					"\(k)": v
				}
				for k, v in #config.commonAnnotations {
					"\(k)": v
				}
			}
		}
	}
	spec: {
		accessModes: [#config.persistence.accessMode]
		resources: requests: storage: #config.persistence.size
		if #config.persistence.storageClass != "" {
			storageClassName: #config.persistence.storageClass
		}
		if #config.persistence.selector != _|_ {
			selector: #config.persistence.selector
		}
	}
}

#ReportsPVC: corev1.#PersistentVolumeClaim & {
	#config: #Config

	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "\(#config._fullname)-reports"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "netbox"
		}
		if #config.reportsPersistence.annotations != _|_ || #config.commonAnnotations != _|_ {
			annotations: {
				for k, v in #config.reportsPersistence.annotations {
					"\(k)": v
				}
				for k, v in #config.commonAnnotations {
					"\(k)": v
				}
			}
		}
	}
	spec: {
		accessModes: [#config.reportsPersistence.accessMode]
		resources: requests: storage: #config.reportsPersistence.size
		if #config.reportsPersistence.storageClass != "" {
			storageClassName: #config.reportsPersistence.storageClass
		}
		if #config.reportsPersistence.selector != _|_ {
			selector: #config.reportsPersistence.selector
		}
	}
}

#ScriptsPVC: corev1.#PersistentVolumeClaim & {
	#config: #Config

	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "\(#config._fullname)-scripts"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "netbox"
		}
		if #config.scriptsPersistence.annotations != _|_ || #config.commonAnnotations != _|_ {
			annotations: {
				for k, v in #config.scriptsPersistence.annotations {
					"\(k)": v
				}
				for k, v in #config.commonAnnotations {
					"\(k)": v
				}
			}
		}
	}
	spec: {
		accessModes: [#config.scriptsPersistence.accessMode]
		resources: requests: storage: #config.scriptsPersistence.size
		if #config.scriptsPersistence.storageClass != "" {
			storageClassName: #config.scriptsPersistence.storageClass
		}
		if #config.scriptsPersistence.selector != _|_ {
			selector: #config.scriptsPersistence.selector
		}
	}
}
