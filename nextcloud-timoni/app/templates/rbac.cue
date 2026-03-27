package templates

import (
	rbacv1 "k8s.io/api/rbac/v1"
)

#Role: rbacv1.#Role & {
	#in:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "Role"
	metadata: {
		name:      #in.metadata.name + "-privileged"
		namespace: #in.metadata.namespace
		labels:    #in.metadata.labels
	}
	rules: [
		{
			apiGroups: ["extensions"]
			resourceNames: ["privileged"]
			resources: ["podsecuritypolicies"]
			verbs: ["use"]
		},
	]
}

#RoleBinding: rbacv1.#RoleBinding & {
	#in:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "RoleBinding"
	metadata: {
		name:      #in.metadata.name + "-privileged"
		namespace: #in.metadata.namespace
		labels:    #in.metadata.labels
	}
	roleRef: {
		apiGroup: "rbac.authorization.k8s.io"
		kind:     "Role"
		name:     #in.metadata.name + "-privileged"
	}
	subjects: [
		{
			kind:      "ServiceAccount"
			name:      #in.rbac.serviceAccount.name
			namespace: #in.metadata.namespace
		},
	]
}