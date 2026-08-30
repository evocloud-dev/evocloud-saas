package templates

import (
	corev1 "k8s.io/api/core/v1"
	rbacv1 "k8s.io/api/rbac/v1"
)

// Helper to calculate names without ternary operator
#GetPrimaryName: {
	#config: #Config
	_pg: #config."hyperswitch-app".postgresql
	result: string
	if _pg.fullnameOverride != "" {
		result: _pg.fullnameOverride
	}
	if _pg.fullnameOverride == "" {
		if _pg.architecture == "replication" {
			result: #config.metadata.name + "-postgresql-" + _pg.primary.name
		}
		if _pg.architecture != "replication" {
			result: #config.metadata.name + "-postgresql"
		}
	}
}

// 1. /charts/postgresql/templates/serviceaccount.yaml
#PostgresqlServiceAccount: corev1.#ServiceAccount & {
	#config: #Config
	_pg: #config."hyperswitch-app".postgresql

	let _labels = {
		for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
		"app.kubernetes.io/name":     "postgresql"
		"app.kubernetes.io/instance": #config.metadata.name
	}

	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		if _pg.serviceAccount.name != "" {
			name: _pg.serviceAccount.name
		}
		if _pg.serviceAccount.name == "" {
			name: #config.metadata.name + "-postgresql"
		}
		namespace: #config.metadata.namespace
		labels:    _labels & _pg.commonLabels
		if len(_pg.serviceAccount.annotations) > 0 || len(_pg.commonAnnotations) > 0 {
			annotations: _pg.serviceAccount.annotations & _pg.commonAnnotations
		}
	}
	automountServiceAccountToken: _pg.serviceAccount.automountServiceAccountToken
}

// 2. /charts/postgresql/templates/secrets.yaml (Base Auth)
#PostgresqlSecret: corev1.#Secret & {
	#config: #Config
	_pg: #config."hyperswitch-app".postgresql

	let _labels = {
		for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
		"app.kubernetes.io/name":     "postgresql"
		"app.kubernetes.io/instance": #config.metadata.name
	}

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config.metadata.name + "-postgresql"
		namespace: #config.metadata.namespace
		labels:    _labels & _pg.commonLabels
		if len(_pg.commonAnnotations) > 0 {
			annotations: _pg.commonAnnotations
		}
	}
	type: "Opaque"
	stringData: {
		if _pg.auth.postgresPassword != "" {
			"postgres-password": _pg.auth.postgresPassword
		}
		if _pg.auth.password != "" {
			"password": _pg.auth.password
		}
		if _pg.auth.replicationPassword != "" {
			"replication-password": _pg.auth.replicationPassword
		}
	}
}

// 3. /charts/postgresql/templates/secrets.yaml (Service Binding Postgres)
#PostgresqlSvcBindPostgresSecret: corev1.#Secret & {
	#config: #Config
	_pg: #config."hyperswitch-app".postgresql
	_primaryName: (#GetPrimaryName & {#config: #config}).result

	let _labels = {
		for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
		"app.kubernetes.io/name":     "postgresql"
		"app.kubernetes.io/instance": #config.metadata.name
	}

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config.metadata.name + "-postgresql-svcbind-postgres"
		namespace: #config.metadata.namespace
		labels:    _labels & _pg.commonLabels
		if len(_pg.commonAnnotations) > 0 {
			annotations: _pg.commonAnnotations
		}
	}
	type: "servicebinding.io/postgresql"
	stringData: {
		provider: "bitnami"
		type:     "postgresql"
		host:     _primaryName
		port:     "\(_pg.primary.service.ports.postgresql)"
		username: "postgres"
		database: "postgres"
		password: _pg.auth.postgresPassword
		uri:      "postgresql://postgres:\(_pg.auth.postgresPassword)@\(_primaryName):\(_pg.primary.service.ports.postgresql)/postgres"
	}
}

// 4. /charts/postgresql/templates/secrets.yaml (Service Binding Custom User)
#PostgresqlSvcBindCustomSecret: corev1.#Secret & {
	#config: #Config
	_pg: #config."hyperswitch-app".postgresql
	_primaryName: (#GetPrimaryName & {#config: #config}).result

	let _labels = {
		for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
		"app.kubernetes.io/name":     "postgresql"
		"app.kubernetes.io/instance": #config.metadata.name
	}

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config.metadata.name + "-postgresql-svcbind-custom-user"
		namespace: #config.metadata.namespace
		labels:    _labels & _pg.commonLabels
		if len(_pg.commonAnnotations) > 0 {
			annotations: _pg.commonAnnotations
		}
	}
	type: "servicebinding.io/postgresql"
	stringData: {
		provider: "bitnami"
		type:     "postgresql"
		host:     _primaryName
		port:     "\(_pg.primary.service.ports.postgresql)"
		username: _pg.auth.username
		password: _pg.auth.password
		if _pg.auth.database != "" {
			database: _pg.auth.database
		}
		let _db = [if _pg.auth.database != "" {_pg.auth.database}, ""][0]
		uri: "postgresql://\(_pg.auth.username):\(_pg.auth.password)@\(_primaryName):\(_pg.primary.service.ports.postgresql)/\(_db)"
	}
}

// 5. /charts/postgresql/templates/tls-secrets.yaml
#PostgresqlTlsSecret: corev1.#Secret & {
	#config: #Config
	_pg: #config."hyperswitch-app".postgresql

	let _labels = {
		for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
		"app.kubernetes.io/name":     "postgresql"
		"app.kubernetes.io/instance": #config.metadata.name
	}

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config.metadata.name + "-postgresql-crt"
		namespace: #config.metadata.namespace
		labels:    _labels & _pg.commonLabels
		if len(_pg.commonAnnotations) > 0 {
			annotations: _pg.commonAnnotations
		}
	}
	type: "kubernetes.io/tls"
	stringData: {
		"tls.crt": ""
		"tls.key": ""
		"ca.crt":  ""
	}
}

// 6. /charts/postgresql/templates/role.yaml
#PostgresqlRole: rbacv1.#Role & {
	#config: #Config
	_pg: #config."hyperswitch-app".postgresql

	let _labels = {
		for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
		"app.kubernetes.io/name":     "postgresql"
		"app.kubernetes.io/instance": #config.metadata.name
	}

	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "Role"
	metadata: {
		name:      #config.metadata.name + "-postgresql"
		namespace: #config.metadata.namespace
		labels:    _labels & _pg.commonLabels
		if len(_pg.commonAnnotations) > 0 {
			annotations: _pg.commonAnnotations
		}
	}
	rules: [
		for r in [{
			apiGroups: ["policy"]
			resources: ["podsecuritypolicies"]
			verbs: ["use"]
			resourceNames: [#config.metadata.name + "-postgresql"]
		}] if _pg.psp.create {r},
		..._pg.rbac.rules,
	]
}

// 7. /charts/postgresql/templates/rolebinding.yaml
#PostgresqlRoleBinding: rbacv1.#RoleBinding & {
	#config: #Config
	_pg: #config."hyperswitch-app".postgresql

	let _labels = {
		for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
		"app.kubernetes.io/name":     "postgresql"
		"app.kubernetes.io/instance": #config.metadata.name
	}

	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "RoleBinding"
	metadata: {
		name:      #config.metadata.name + "-postgresql"
		namespace: #config.metadata.namespace
		labels:    _labels & _pg.commonLabels
		if len(_pg.commonAnnotations) > 0 {
			annotations: _pg.commonAnnotations
		}
	}
	roleRef: {
		apiGroup: "rbac.authorization.k8s.io"
		kind:     "Role"
		name:     #config.metadata.name + "-postgresql"
	}
	subjects: [
		{
			kind: "ServiceAccount"
			let _saName = [if _pg.serviceAccount.name != "" {_pg.serviceAccount.name}, if _pg.serviceAccount.name == "" && _pg.serviceAccount.create {#config.metadata.name + "-postgresql"}, "default"][0]
			name:      _saName
			namespace: #config.metadata.namespace
		},
	]
}

// 8. /charts/postgresql/templates/psp.yaml
#PostgresqlPSP: {
	#config: #Config
	_pg: #config."hyperswitch-app".postgresql

	let _labels = {
		for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
		"app.kubernetes.io/name":     "postgresql"
		"app.kubernetes.io/instance": #config.metadata.name
	}

	apiVersion: "policy/v1beta1"
	kind:       "PodSecurityPolicy"
	metadata: {
		name:      #config.metadata.name + "-postgresql"
		namespace: #config.metadata.namespace
		labels:    _labels & _pg.commonLabels
		if len(_pg.commonAnnotations) > 0 {
			annotations: _pg.commonAnnotations
		}
	}
	spec: {
		privileged: false
		volumes: ["configMap", "secret", "persistentVolumeClaim", "emptyDir", "projected"]
		hostNetwork: false
		hostIPC:     false
		hostPID:     false
		runAsUser: rule:          "RunAsAny"
		seLinux: rule:            "RunAsAny"
		supplementalGroups: rule: "MustRunAs"
		supplementalGroups: ranges: [{min: 1, max: 65535}]
		fsGroup: rule: "MustRunAs"
		fsGroup: ranges: [{min: 1, max: 65535}]
		readOnlyRootFilesystem: false
	}
}

// 9. /charts/postgresql/templates/prometheusrule.yaml
#PostgresqlPrometheusRule: {
	#config: #Config
	_pg: #config."hyperswitch-app".postgresql

	let _labels = {
		for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
		"app.kubernetes.io/name":     "postgresql"
		"app.kubernetes.io/instance": #config.metadata.name
	}

	apiVersion: "monitoring.coreos.com/v1"
	kind:       "PrometheusRule"
	metadata: {
		name: #config.metadata.name + "-postgresql"
		let _namespace = [if _pg.metrics.prometheusRule.namespace != "" {_pg.metrics.prometheusRule.namespace}, #config.metadata.namespace][0]
		namespace: _namespace
		labels: _labels & _pg.metrics.prometheusRule.labels & {"app.kubernetes.io/component": "metrics"}
		if len(_pg.commonAnnotations) > 0 {
			annotations: _pg.commonAnnotations
		}
	}
	spec: {
		groups: [
			{
				name:  #config.metadata.name + "-postgresql"
				rules: _pg.metrics.prometheusRule.rules
			},
		]
	}
}

// 10. /charts/postgresql/templates/extra-list.yaml
#PostgresqlExtra: {
	#config: #Config
	_pg: #config."hyperswitch-app".postgresql
	objects: [
		for ed in _pg.extraDeploy {ed},
	]
}
