package templates

import (
	rbacv1 "k8s.io/api/rbac/v1"
)

#Role: rbacv1.#Role & {
	#config: #Config

	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "Role"
	metadata: {
		name:      #config.#fullname
		namespace: #config.metadata.namespace
		labels:    #config.#labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	rules: [
		{
			apiGroups: [""]
			resources: ["pods", "pods/log", "events", "persistentvolumeclaims", "services", "secrets"]
			verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
		},
	]
}

#RoleBinding: rbacv1.#RoleBinding & {
	#config: #Config

	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "RoleBinding"
	metadata: {
		name:      #config.#fullname
		namespace: #config.metadata.namespace
		labels:    #config.#labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	roleRef: {
		apiGroup: "rbac.authorization.k8s.io"
		kind:     "Role"
		name:     #config.#fullname
	}
	subjects: [
		{
			kind:      "ServiceAccount"
			name:      #config.#serviceAccountName
			namespace: #config.metadata.namespace
		},
	]
}
