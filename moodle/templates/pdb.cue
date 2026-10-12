package templates

import (
	policyv1 "k8s.io/api/policy/v1"
	"k8s.io/apimachinery/pkg/util/intstr"
)

#PodDisruptionBudget: policyv1.#PodDisruptionBudget & {
	#config: #Config

	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      #config.#fullname
		namespace: #config.metadata.namespace
		labels:    #config.#labels
	}
	spec: {
		minAvailable: intstr.#IntOrString & #config.pdb.minAvailable
		selector: matchLabels: #config.#selectorLabels
	}
}

