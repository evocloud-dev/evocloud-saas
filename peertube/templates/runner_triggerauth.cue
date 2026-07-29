package templates

#RunnerTriggerAuthentication: {
	#config:    #Config
	apiVersion: "keda.sh/v1alpha1"
	kind:       "TriggerAuthentication"
	metadata: {
		name:      *"\((#config.metadata.name))-runner-keda-pg-auth" | string
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "runner"
		}
	}
	#pgSecret: {
		if #config.postgresql.enabled && #config.runner.kedaDefaults.postgresql.existingSecret == "" {
			"\(#config.metadata.name)-server-postgres"
		}
		if !(#config.postgresql.enabled && #config.runner.kedaDefaults.postgresql.existingSecret == "") {
			#config.runner.kedaDefaults.postgresql.existingSecret
		}
	}
	spec: secretTargetRef: [
		{
			parameter: "password"
			name:      #pgSecret
			key:       *"postgres-password" | string
			if #config.runner.kedaDefaults.postgresql.passwordKey != "" {
				key: #config.runner.kedaDefaults.postgresql.passwordKey
			}
		},
	]
}
