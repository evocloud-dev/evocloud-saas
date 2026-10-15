@extern(embed)

package templates

import (
	corev1 "k8s.io/api/core/v1"
)

_bootstrapMjs:    string @embed(file="bootstrap.mjs", type=text)
_startMjs:        string @embed(file="start.mjs", type=text)
_tlsAdmissionMjs: string @embed(file="tls-admission.mjs", type=text)
_readinessMjs:    string @embed(file="readiness.mjs", type=text)

#BootstrapConfigMap: corev1.#ConfigMap & {
	#config: #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      #config._bootstrapConfigMapName
		namespace: #config.metadata.namespace
		labels:    #config._labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	data: {
		"bootstrap.mjs":     _bootstrapMjs
		"start.mjs":         _startMjs
		"tls-admission.mjs": _tlsAdmissionMjs
		"readiness.mjs":     _readinessMjs
	}
}

// Alias for compatibility
#ConfigMap: #BootstrapConfigMap
