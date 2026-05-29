package templates

#Helpers: {
	#config: #Config

	name: {
		if #config.nameOverride != "" {
			#config.nameOverride
		}
		if #config.nameOverride == "" {
			"listmonk"
		}
	}

	fullname: {
		if #config.fullnameOverride != "" {
			#config.fullnameOverride
		}
		if #config.fullnameOverride == "" {
			"\(#config.metadata.name)-\(name)"
		}
	}

	chart: "listmonk-\(#config.moduleVersion)"

	labels: {
		"helm.sh/chart":                chart
		"app.kubernetes.io/name":       name
		"app.kubernetes.io/instance":   #config.metadata.name
		"app.kubernetes.io/version":    #config.moduleVersion
		"app.kubernetes.io/managed-by": "timoni"
	}

	selectorLabels: {
		"app.kubernetes.io/name":     name
		"app.kubernetes.io/instance": #config.metadata.name
	}

	serviceAccountName: {
		if #config.serviceAccount.create {
			if #config.serviceAccount.name != "" {
				#config.serviceAccount.name
			}
			if #config.serviceAccount.name == "" {
				fullname
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

	dbSecretName: {
		if #config.database.existingSecret != "" {
			#config.database.existingSecret
		}
		if #config.database.existingSecret == "" {
			"\(fullname)-db"
		}
	}

	smtpSecretName: {
		if #config.smtp.existingSecret != "" {
			#config.smtp.existingSecret
		}
		if #config.smtp.existingSecret == "" {
			"\(fullname)-smtp"
		}
	}

	postgresStatefulSetName: "\(name)-postgres"
}
