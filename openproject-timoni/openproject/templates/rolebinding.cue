package templates

import (
	rbacv1 "k8s.io/api/rbac/v1"
)

#RoleBinding: rbacv1.#RoleBinding & {
	#config: #Config

	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "RoleBinding"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
	}
	roleRef: {
		apiGroup: "rbac.authorization.k8s.io"
		kind:     "Role"
		name:     #config.metadata.name
	}
	subjects: [
		{
			kind:      "ServiceAccount"
			name:      #config.metadata.name
			namespace: #config.metadata.namespace
		},
	]
}
