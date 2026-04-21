package templates

import (
	rbacv1 "k8s.io/api/rbac/v1"
)

#RoleBinding: rbacv1.#RoleBinding & {
	#config: #Config

	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "RoleBinding"
	metadata: {
		name:      #config._fullname
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "netbox"
		}
		if #config.commonAnnotations != _|_ {
			annotations: #config.commonAnnotations
		}
	}
	roleRef: {
		kind:     "Role"
		name:     #config._fullname
		apiGroup: "rbac.authorization.k8s.io"
	}
	subjects: [
		{
			kind:      "ServiceAccount"
			name: {
				if #config.serviceAccount.create {
					if #config.serviceAccount.name != "" {
						#config.serviceAccount.name
					}
					if #config.serviceAccount.name == "" {
						#config._fullname
					}
				}
				if !#config.serviceAccount.create {
					if #config.serviceAccount.name != "" {
						#config.serviceAccount.name
					}
					if #config.serviceAccount.name == "" {
						"default"
					}
				}
			}
			namespace: #config.metadata.namespace
		},
	]
}
