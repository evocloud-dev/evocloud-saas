package templates

import (
	corev1 "k8s.io/api/core/v1"
    
)

#Hooks:corev1.#ConfigMap &  {
	#in: #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      #in.metadata.name + "-hooks"
		namespace: #in.metadata.namespace
		labels:    #in.metadata.labels
		if #in.metadata.annotations != _|_ {
			annotations: #in.metadata.annotations
		}
	}

	data: {
		// THE ENGINE: Loop through all hooks
		for name, script in #in.nextcloud.hooks {
			// THE BOUNCER: Only add if the script is not empty
			if script != "" {
				// EXTENSION MATCH: Add the ".sh" suffix to the filename
				"\(name).sh": script
			}
		}
	}
}
