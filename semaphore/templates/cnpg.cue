package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#CNPGUrlsSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	type:       corev1.#SecretTypeOpaque
	metadata: {
		name:      "\(#config.metadata.name)-cnpg-main-urls"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "cnpg-main-urls"
		}
	}
	stringData: {
		host:     "\(#config.metadata.name)-cnpg-main-rw"
		jdbc:     "jdbc:postgresql://\(#config.metadata.name)-cnpg-main-rw:\(#config.cnpg.main.port)/\(#config.cnpg.main.database)"
		nossl:    "postgresql://\(#config.cnpg.main.user):\(#config.cnpg.main.password)@\(#config.metadata.name)-cnpg-main-rw:\(#config.cnpg.main.port)/\(#config.cnpg.main.database)?sslmode=disable"
		porthost: "\(#config.metadata.name)-cnpg-main-rw:\(#config.cnpg.main.port)"
		std:      "postgresql://\(#config.cnpg.main.user):\(#config.cnpg.main.password)@\(#config.metadata.name)-cnpg-main-rw:\(#config.cnpg.main.port)/\(#config.cnpg.main.database)"
	}
}

#CNPGUserSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	type:       corev1.#SecretTypeBasicAuth
	metadata: {
		name:      "\(#config.metadata.name)-cnpg-main-user"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "cnpg-main-user"
		}
	}
	stringData: {
		password: #config.cnpg.main.password
		username: #config.cnpg.main.user
	}
}

#CNPGCluster: {
	#config:    #Config
	apiVersion: "postgresql.cnpg.io/v1"
	kind:       "Cluster"
	metadata: {
		name:      "\(#config.metadata.name)-cnpg-main"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "cnpg-main"
			"cnpg.io/reload":              "on"
		}
		annotations: {
			"cnpg.io/hibernation":              "off"
			"cnpg.io/skipEmptyWalArchiveCheck": "enabled"
		}
	}
	spec: {
		imageName:             #config.cnpg.main.image.reference
		postgresUID:           26
		postgresGID:           26
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
		storage: {
			pvcTemplate: {
				accessModes: #config.cnpg.main.storage.accessModes
				resources: {
					requests: {
						storage: #config.cnpg.main.storage.size
					}
				}
			}
		}
		walStorage: {
			pvcTemplate: {
				accessModes: #config.cnpg.main.walStorage.accessModes
				resources: {
					requests: {
						storage: #config.cnpg.main.walStorage.size
					}
				}
			}
		}
		bootstrap: {
			initdb: {
				secret: {
					name: "\(#config.metadata.name)-cnpg-main-user"
				}
				database:      #config.cnpg.main.database
				owner:         #config.cnpg.main.user
				dataChecksums: true
			}
		}
	}
}
