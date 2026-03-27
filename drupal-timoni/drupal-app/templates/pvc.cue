package templates

import (
	corev1 "k8s.io/api/core/v1"
)

// #PersistentVolumeClaim defines a template for Kubernetes PVCs.
#PersistentVolumeClaim: corev1.#PersistentVolumeClaim & {
	#config: #Config
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		if #config.drupal.persistence.annotations != _|_ {
			annotations: #config.drupal.persistence.annotations
		}
		name:      "\(#config.metadata.name)-drupal"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: [#config.drupal.persistence.accessMode]
		resources: requests: {
			storage: #config.drupal.persistence.size
			if #config.drupal.persistence.iops != "" {
				iops: #config.drupal.persistence.iops
			}
		}
		if #config.drupal.persistence.storageClass != "" {
			if #config.drupal.persistence.storageClass == "-" {
				storageClassName: ""
			}
			if #config.drupal.persistence.storageClass != "-" {
				storageClassName: #config.drupal.persistence.storageClass
			}
		}
	}
}

// #DrupalBackupPersistentVolumeClaim defines a template for Drupal backup PVCs.
#DrupalBackupPersistentVolumeClaim: corev1.#PersistentVolumeClaim & {
	#config: #Config
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		if #config.drupal.backup.persistence.annotations != _|_ {
			annotations: #config.drupal.backup.persistence.annotations
		}
		name:      "\(#config.metadata.name)-drupal-backup"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/name": "\(#config.metadata.name)-drupal-backup"
		}
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: [#config.drupal.backup.persistence.accessMode]
		resources: requests: {
			storage: #config.drupal.backup.persistence.size
			if #config.drupal.backup.persistence.iops != "" {
				iops: #config.drupal.backup.persistence.iops
			}
		}
		if #config.drupal.backup.persistence.storageClass != "" {
			if #config.drupal.backup.persistence.storageClass == "-" {
				storageClassName: ""
			}
			if #config.drupal.backup.persistence.storageClass != "-" {
				storageClassName: #config.drupal.backup.persistence.storageClass
			}
		}
	}
}

// #MySQLPersistentVolumeClaim defines a template for MySQL PVCs.
#MySQLPersistentVolumeClaim: corev1.#PersistentVolumeClaim & {
	#config: #Config
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "\(#config.metadata.name)-mysql"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: ["ReadWriteOnce"]
		resources: requests: storage: #config.mysql.primary.persistence.size
		if #config.mysql.primary.persistence.storageClass != "" {
			if #config.mysql.primary.persistence.storageClass == "-" {
				storageClassName: ""
			}
			if #config.mysql.primary.persistence.storageClass != "-" {
				storageClassName: #config.mysql.primary.persistence.storageClass
			}
		}
	}
}

// #PostgreSQLPersistentVolumeClaim defines a template for PostgreSQL PVCs.
#PostgreSQLPersistentVolumeClaim: corev1.#PersistentVolumeClaim & {
	#config: #Config
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: ["ReadWriteOnce"]
		resources: requests: storage: #config.postgresql.primary.persistence.size
		if #config.postgresql.primary.persistence.storageClass != "" {
			if #config.postgresql.primary.persistence.storageClass == "-" {
				storageClassName: ""
			}
			if #config.postgresql.primary.persistence.storageClass != "-" {
				storageClassName: #config.postgresql.primary.persistence.storageClass
			}
		}
	}
}
