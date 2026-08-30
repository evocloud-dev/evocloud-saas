package templates

import (
	corev1 "k8s.io/api/core/v1"
	rbacv1 "k8s.io/api/rbac/v1"
)

#KafkaRBAC: {
	#config: #Config
	let k = #config."hyperswitch-app".kafka
	let fullname = "\(#config.metadata.name)-\(k.name)"

	_saName: *"" | string
	if k.serviceAccount.name != "" {_saName: k.serviceAccount.name}
	if k.serviceAccount.name == "" {_saName: fullname}

	serviceAccount: [
		if k.serviceAccount.create {
			corev1.#ServiceAccount & {
				apiVersion: "v1"
				kind:       "ServiceAccount"
				metadata: {
					name:      _saName
					namespace: #config.metadata.namespace
					labels: #config.metadata.labels & {
						"app.kubernetes.io/component": "kafka"
						if k.commonLabels != _|_ {
							for key, val in k.commonLabels {"\(key)": val}
						}
					}
					if k.serviceAccount.annotations != _|_ || k.commonAnnotations != _|_ {
						annotations: {
							if k.serviceAccount.annotations != _|_ {
								for key, val in k.serviceAccount.annotations {"\(key)": val}
							}
							if k.commonAnnotations != _|_ {
								for key, val in k.commonAnnotations {"\(key)": val}
							}
						}
					}
				}
				automountServiceAccountToken: k.serviceAccount.automountServiceAccountToken
			}
		},
	]

	role: [
		if k.rbac.create {
			rbacv1.#Role & {
				apiVersion: "rbac.authorization.k8s.io/v1"
				kind:       "Role"
				metadata: {
					name:      fullname
					namespace: #config.metadata.namespace
					labels: #config.metadata.labels & {
						"app.kubernetes.io/component": "kafka"
						if k.commonLabels != _|_ {
							for key, val in k.commonLabels {"\(key)": val}
						}
					}
					if k.commonAnnotations != _|_ {
						annotations: k.commonAnnotations
					}
				}
				rules: [
					{
						apiGroups: [""]
						resources: ["services"]
						verbs: ["get", "list", "watch"]
					},
				]
			}
		},
	]

	roleBinding: [
		if k.rbac.create {
			rbacv1.#RoleBinding & {
				apiVersion: "rbac.authorization.k8s.io/v1"
				kind:       "RoleBinding"
				metadata: {
					name:      fullname
					namespace: #config.metadata.namespace
					labels: #config.metadata.labels & {
						"app.kubernetes.io/component": "kafka"
						if k.commonLabels != _|_ {
							for key, val in k.commonLabels {"\(key)": val}
						}
					}
					if k.commonAnnotations != _|_ {
						annotations: k.commonAnnotations
					}
				}
				roleRef: {
					apiGroup: "rbac.authorization.k8s.io"
					kind:     "Role"
					name:     fullname
				}
				subjects: [
					{
						kind:      "ServiceAccount"
						name:      _saName
						namespace: #config.metadata.namespace
					},
				]
			}
		},
	]
}
