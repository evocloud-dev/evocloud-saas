package templates

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#ServiceAccount: corev1.#ServiceAccount & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "sonarqube"
	}
	metadata: {
		name: [
			if #config.serviceAccount.name != "" {
				#config.serviceAccount.name
			},
			#config.fullname,
		][0]
		if #config.serviceAccount.annotations != _|_ {
			annotations: #config.serviceAccount.annotations
		}
	}
	automountServiceAccountToken: #config.serviceAccount.automountServiceAccountToken
}
