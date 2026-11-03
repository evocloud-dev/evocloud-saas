package templates

#CnpgCluster: {
	#config:    #Config
	apiVersion: "postgresql.cnpg.io/v1"
	kind:       "Cluster"
	metadata: {
		name:      "\(#config.metadata.name)-cnpg-main"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"cnpg.io/reload": "on"
		}
		annotations: {
			if #config.metadata.annotations != _|_ {
				#config.metadata.annotations
			}
			"cnpg.io/hibernation":             "off"
			"cnpg.io/skipEmptyWalArchiveCheck": "enabled"
		}
	}
	spec: {
		imageName:             #config.cnpg.main.image.reference
		postgresUID:           #config.cnpg.main.postgresUID
		postgresGID:           #config.cnpg.main.postgresGID
		enableSuperuserAccess: true
		primaryUpdateStrategy: "unsupervised"
		primaryUpdateMethod:   "switchover"
		logLevel:              "info"
		instances:             #config.cnpg.main.instances
		nodeMaintenanceWindow: {
			inProgress: false
			reusePVC:   true
		}
		resources: #config.cnpg.main.resources
		storage: pvcTemplate: {
			accessModes: ["ReadWriteOnce"]
			resources: requests: storage: #config.cnpg.main.storage
		}
		walStorage: pvcTemplate: {
			accessModes: ["ReadWriteOnce"]
			resources: requests: storage: #config.cnpg.main.storage
		}
		bootstrap: initdb: {
			secret: name: "\(#config.metadata.name)-cnpg-main-user"
			database:      #config.cnpg.main.database
			owner:         #config.cnpg.main.user
			dataChecksums: true
		}
	}
}
