package templates

import (
	rbacv1 "k8s.io/api/rbac/v1"
)

#Role: rbacv1.#Role & {
	#config: #Config

	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "Role"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
	}
	rules: [
		{
			apiGroups: ["security.openshift.io"]
			resourceNames: [#config.serviceAccount.openshift.securityContextConstraints.roleBinding.resourceName]
			resources: ["securitycontextconstraints"]
			verbs: ["use"]
		},
	]
}
