// SPDX-License-Identifier: Apache-2.0
package templates

import (
	policyv1 "k8s.io/api/policy/v1"
)

#PDBBuilder: {
	_config:   #Config
	_fullname: string

	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      _fullname
		namespace: _config.metadata.namespace
		labels:    _config.metadata.labels & _config.commonLabels
	}
	spec: policyv1.#PodDisruptionBudgetSpec & {
		minAvailable: _config.pdb.minAvailable
		selector: matchLabels: _config.metadata.labels
	}
}
