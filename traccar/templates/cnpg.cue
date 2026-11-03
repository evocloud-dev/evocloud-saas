package templates

#CNPGCluster: {
	#config: #Config
	apiVersion: "postgresql.cnpg.io/v1"
	kind:       "Cluster"
	metadata: {
		name:      "\(#config.metadata.name)-cnpg-main"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"cnpg.io/reload":             "on"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		annotations: {
			"cnpg.io/hibernation":             "off"
			"cnpg.io/skipEmptyWalArchiveCheck": "enabled"
			if #config.metadata.annotations != _|_ {
				#config.metadata.annotations
			}
		}
	}
	spec: {
		imageName:             #config.cnpg.image.reference
		postgresUID:           26
		postgresGID:           26
		enableSuperuserAccess: true
		primaryUpdateStrategy: "unsupervised"
		primaryUpdateMethod:   "switchover"
		logLevel:              "info"
		instances:             #config.cnpg.instances
		nodeMaintenanceWindow: {
			inProgress: false
			reusePVC:   true
		}
		resources: #config.cnpg.resources
		storage: pvcTemplate: {
			accessModes: ["ReadWriteOnce"]
			resources: requests: storage: #config.cnpg.storage
		}
		walStorage: pvcTemplate: {
			accessModes: ["ReadWriteOnce"]
			resources: requests: storage: #config.cnpg.walStorage
		}
		bootstrap: initdb: {
			secret: name: "\(#config.metadata.name)-cnpg-main-user"
			database:      #config.cnpg.database
			owner:         #config.cnpg.user
			dataChecksums: true
		}
	}
}

