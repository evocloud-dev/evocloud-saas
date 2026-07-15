package templates



#RunnerScaledObject: {
	#config:    #Config
	#group:     _
	apiVersion: "keda.sh/v1alpha1"
	kind:       "ScaledObject"
	metadata: {
		name:      *"\((#config.metadata.name))-runner-\(#group.id)-keda" | string
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "runner"
			"peertube.runner/group":       #group.id
		}
	}
	spec: {
		scaleTargetRef: {
			apiVersion: "apps/v1"
			kind:       "StatefulSet"
			name:       *"\((#config.metadata.name))-runner-\(#group.id)" | string
		}
		minReplicaCount: #config.runner.kedaDefaults.minReplicas
		#maxReplicas:    *#config.runner.kedaDefaults.maxReplicas | int
		if #group.keda != _|_ && #group.keda.maxReplicas != _|_ {
			#maxReplicas: #group.keda.maxReplicas
		}
		maxReplicaCount: #maxReplicas
		cooldownPeriod:  #config.runner.kedaDefaults.cooldownPeriod
		pollingInterval: #config.runner.kedaDefaults.pollingInterval
		#pgHost: {
			if #config.postgresql.enabled && #config.runner.kedaDefaults.postgresql.host == "" {
				"\(#config.metadata.name)-postgresql.\(#config.metadata.namespace)"
			}
			if !(#config.postgresql.enabled && #config.runner.kedaDefaults.postgresql.host == "") {
				#config.runner.kedaDefaults.postgresql.host
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
		triggers: [
			if #pgSecret != "" && #pgHost != "" {
				{
					type: "postgresql"
					authenticationRef: name: *"\((#config.metadata.name))-runner-keda-pg-auth" | string
					metadata: {
						host:             #pgHost
						port:             "\(#config.runner.kedaDefaults.postgresql.port)"
						userName:         #config.runner.kedaDefaults.postgresql.userName
						dbName:           #config.runner.kedaDefaults.postgresql.dbName
						sslmode:          #config.runner.kedaDefaults.postgresql.sslmode
						#targetVal:       #config.runner.kedaDefaults.postgresql.targetQueryValue
						targetQueryValue: "\(#targetVal)"

						query:            #config.runner.kedaDefaults.postgresql.query
					}
				}
			},
			if #config.runner.kedaDefaults.cpu.enabled {
				{
					type:       "cpu"
					metricType: "Utilization"
					metadata: {
						value: "\(#config.runner.kedaDefaults.cpu.targetCPUUtilizationPercentage)"
					}
				}
			},
		]
		if #config.runner.kedaDefaults.advanced != _|_ {
			if #config.runner.kedaDefaults.advanced != null {
				advanced: #config.runner.kedaDefaults.advanced
			}
		}
	}
}
