package templates

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#CNPGUserSecret: corev1.#Secret & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	type:       corev1.#SecretTypeBasicAuth
	metadata: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "cnpg-main-user"
	}
	stringData: {
		username: #config.cnpg.main.user
		password: #config.cnpg.main.password
	}
}

#CNPGUrlsSecret: corev1.#Secret & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	type:       corev1.#SecretTypeOpaque
	metadata: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "cnpg-main-urls"
	}
	let _host = "\(#config.metadata.name)-cnpg-main-rw"
	let _user = #config.cnpg.main.user
	let _pass = #config.cnpg.main.password
	let _db   = #config.cnpg.main.database
	stringData: {
		host:     _host
		porthost: "\(_host):5432"
		jdbc:     "jdbc:postgresql://\(_host):5432/\(_db)"
		nossl:    "postgresql://\(_user):\(_pass)@\(_host):5432/\(_db)?sslmode=disable"
		std:      "postgresql://\(_user):\(_pass)@\(_host):5432/\(_db)"
	}
}

#CNPGCluster: {
	#config: #Config
	apiVersion: "postgresql.cnpg.io/v1"
	kind:       "Cluster"
	metadata: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "cnpg-main"
	}
	metadata: {
		labels: "cnpg.io/reload": "on"
		annotations: {
			"cnpg.io/hibernation":              "off"
			"cnpg.io/skipEmptyWalArchiveCheck": "enabled"
		}
	}
	spec: {
		instances:             #config.cnpg.main.instances
		imageName:             #config.cnpg.main.image.reference
		postgresUID:           26
		postgresGID:           26
		enableSuperuserAccess: true
		primaryUpdateStrategy: "unsupervised"
		primaryUpdateMethod:   "switchover"
		logLevel:              "info"
		nodeMaintenanceWindow: {
			inProgress: false
			reusePVC:   true
		}
		resources: #config.resources
		storage: pvcTemplate: {
			accessModes: ["ReadWriteOnce"]
			resources: requests: storage: #config.cnpg.main.storage.size
		}
		walStorage: pvcTemplate: {
			accessModes: ["ReadWriteOnce"]
			resources: requests: storage: #config.cnpg.main.walStorage.size
		}
		bootstrap: initdb: {
			secret: name: "\(#config.metadata.name)-cnpg-main-user"
			database:      #config.cnpg.main.database
			owner:         #config.cnpg.main.user
			dataChecksums: true
		}
	}
}
