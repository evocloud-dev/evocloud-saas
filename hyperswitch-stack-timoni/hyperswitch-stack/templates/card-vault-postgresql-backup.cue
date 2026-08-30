package templates

import (
	corev1 "k8s.io/api/core/v1"
	netv1 "k8s.io/api/networking/v1"
	batchv1 "k8s.io/api/batch/v1"
)

// 1. /charts/postgresql/templates/backup/pvc.yaml
#CardVaultPostgresqlBackupPVC: corev1.#PersistentVolumeClaim & {
	#config: #Config
	let cv = #config."hyperswitch-app"."hyperswitch-card-vault"
	let pg = cv.postgresql
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "\(#config.metadata.name)-locker-db-pgdumpall"
		namespace: #config.metadata.namespace
		labels: {
			for k, v in #config.metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
			"app.kubernetes.io/name":      "hyperswitch-card-vault-postgresql"
			"app.kubernetes.io/component": "pg_dumpall"
		}
		if pg.backup.cronjob.annotations != _|_ || pg.backup.cronjob.storage.resourcePolicy != "" {
			annotations: {
				if pg.backup.cronjob.annotations != _|_ {
					for k, v in pg.backup.cronjob.annotations {"\(k)": v}
				}
				if pg.backup.cronjob.storage.resourcePolicy != "" {
					"helm.sh/resource-policy": pg.backup.cronjob.storage.resourcePolicy
				}
			}
		}
	}
	spec: {
		accessModes: pg.backup.cronjob.storage.accessModes
		resources: requests: storage: pg.backup.cronjob.storage.size
		if pg.backup.cronjob.storage.storageClass != _|_ {
			storageClassName: pg.backup.cronjob.storage.storageClass
		}
	}
}

// 2. /charts/postgresql/templates/backup/networkpolicy.yaml
#CardVaultPostgresqlBackupNetworkPolicy: netv1.#NetworkPolicy & {
	#config:    #Config
	apiVersion: "networking.k8s.io/v1"
	kind:       "NetworkPolicy"
	metadata: {
		name:      "\(#config.metadata.name)-locker-db-pgdumpall"
		namespace: #config.metadata.namespace
		labels: {
			for k, v in #config.metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
			"app.kubernetes.io/name":      "hyperswitch-card-vault-postgresql"
			"app.kubernetes.io/component": "pg_dumpall"
		}
	}
	spec: {
		podSelector: matchLabels: {
			for k, v in #config.metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
			"app.kubernetes.io/component": "pg_dumpall"
		}
		policyTypes: ["Egress"]
		egress: [
			{
				ports: [
					{port: 5432, protocol: "TCP"},
					{port: 53, protocol: "TCP"},
					{port: 53, protocol: "UDP"},
				]
			},
		]
	}
}

// 3. /charts/postgresql/templates/backup/cronjob.yaml
#CardVaultPostgresqlBackupCronJob: batchv1.#CronJob & {
	#config: #Config
	let cv = #config."hyperswitch-app"."hyperswitch-card-vault"
	let pg = cv.postgresql
	apiVersion: "batch/v1"
	kind:       "CronJob"
	metadata: {
		name:      "\(#config.metadata.name)-locker-db-pgdumpall"
		namespace: #config.metadata.namespace
		labels: {
			for k, v in #config.metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
			"app.kubernetes.io/name":      "hyperswitch-card-vault-postgresql"
			"app.kubernetes.io/component": "pg_dumpall"
		}
	}
	spec: {
		schedule:                   pg.backup.cronjob.schedule
		concurrencyPolicy:          pg.backup.cronjob.concurrencyPolicy
		failedJobsHistoryLimit:     pg.backup.cronjob.failedJobsHistoryLimit
		successfulJobsHistoryLimit: pg.backup.cronjob.successfulJobsHistoryLimit
		if pg.backup.cronjob.timeZone != _|_ {
			timeZone: pg.backup.cronjob.timeZone
		}
		if pg.backup.cronjob.startingDeadlineSeconds != _|_ {
			startingDeadlineSeconds: pg.backup.cronjob.startingDeadlineSeconds
		}
		jobTemplate: spec: {
			if pg.backup.cronjob.ttlSecondsAfterFinished != _|_ {
				ttlSecondsAfterFinished: pg.backup.cronjob.ttlSecondsAfterFinished
			}
			template: {
				metadata: {
					labels: {
						for k, v in #config.metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
						"app.kubernetes.io/component": "pg_dumpall"
					}
					if pg.backup.cronjob.podAnnotations != _|_ {
						annotations: pg.backup.cronjob.podAnnotations
					}
				}
				spec: {
					restartPolicy: pg.backup.cronjob.restartPolicy
					if pg.backup.cronjob.nodeSelector != _|_ {
						nodeSelector: pg.backup.cronjob.nodeSelector
					}
					if pg.backup.cronjob.tolerations != _|_ {
						tolerations: pg.backup.cronjob.tolerations
					}
					if pg.backup.cronjob.podSecurityContext != _|_ {
						securityContext: pg.backup.cronjob.podSecurityContext
					}
					containers: [
						{
							name:  "\(#config.metadata.name)-locker-db-pgdumpall"
							image: "\(pg.image.repository):\(pg.image.tag)"
							env: [
								{name: "PGUSER", value: pg.auth.username},
								{
									name: "PGPASSWORD"
									valueFrom: secretKeyRef: {
										name: "\(#config.metadata.name)-locker-db"
										key:  "password"
									}
								},
								{name: "PGHOST", value: "\(#config.metadata.name)-locker-db"},
								{name: "PGPORT", value: "5432"},
								{name: "PGDUMP_DIR", value: pg.backup.cronjob.storage.mountPath},
							]
							command: pg.backup.cronjob.command
							volumeMounts: [
								if pg.backup.cronjob.storage.enabled {
									{
										name:      "datadir"
										mountPath: pg.backup.cronjob.storage.mountPath
										subPath:   pg.backup.cronjob.storage.subPath
									}
								},
								{
									name:      "empty-dir"
									mountPath: "/tmp"
									subPath:   "tmp-dir"
								},
								for vm in pg.backup.cronjob.extraVolumeMounts {vm},
							]
							if pg.backup.cronjob.containerSecurityContext != _|_ {
								securityContext: pg.backup.cronjob.containerSecurityContext
							}
							if pg.backup.cronjob.resources != _|_ {
								resources: pg.backup.cronjob.resources
							}
						},
					]
					volumes: [
						if pg.backup.cronjob.storage.enabled {
							{
								name: "datadir"
								persistentVolumeClaim: claimName: "\(#config.metadata.name)-locker-db-pgdumpall"
							}
						},
						{
							name: "empty-dir"
							emptyDir: {}
						},
						for v in pg.backup.cronjob.extraVolumes {v},
					]
				}
			}
		}
	}
}
