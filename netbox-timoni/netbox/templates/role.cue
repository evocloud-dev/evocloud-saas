package templates

import (
	rbacv1 "k8s.io/api/rbac/v1"
)

#Role: rbacv1.#Role & {
	#config: #Config

	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "Role"
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
	rules: [
		if #config.worker.enabled && #config.worker.waitForBackend.enabled {
			{
				apiGroups: ["apps"]
				resources: ["statefulsets", "deployments", "replicasets"]
				verbs: ["get", "list", "watch"]
			}
		},
		for r in #config.rbac.rules {r},
	]
}
