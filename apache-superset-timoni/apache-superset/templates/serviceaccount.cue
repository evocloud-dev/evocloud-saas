package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServiceAccount: corev1.#ServiceAccount & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name: {
			if #config.serviceAccountName != null && #config.serviceAccountName != "" {
				#config.serviceAccountName
			}
			if #config.serviceAccountName == null || #config.serviceAccountName == "" {
				#config.metadata.name
			}
		}
		namespace: #config.metadata.namespace
		labels: {
			"app.kubernetes.io/name":       #config.metadata.name
			"helm.sh/chart":                #config.metadata.labels.chart
			"app.kubernetes.io/instance":   #config.metadata.name
			"app.kubernetes.io/managed-by": #config.metadata.labels.heritage
			"kubernetes.io/cluster-service": "true"
			"addonmanager.kubernetes.io/mode": "Reconcile"
		} & #config.extraLabels
		if #config.serviceAccount.annotations != _|_ {
			annotations: #config.serviceAccount.annotations
		}
	}
}
