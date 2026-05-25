package templates

import (
	corev1 "k8s.io/api/core/v1"
)

// 1. /charts/postgresql/templates/backup/pvc.yaml
#PostgresqlBackupPVC: corev1.#PersistentVolumeClaim & {
	#config: #Config

	// Lines 12-19: HELPER LOGIC (Translated from _helpers.tpl)
	// These define local variables (pg, _labels) to ensure 1:1 parity with Helm naming/labeling.
	let pg = #config."hyperswitch-app".postgresql

	let _labels = {
		for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
		"app.kubernetes.io/name":      "postgresql"
		"app.kubernetes.io/instance":  #config.metadata.name
		"app.kubernetes.io/component": "pg_dumpall"
	}

	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql-pgdumpall"
		namespace: #config.metadata.namespace
		labels:    _labels & pg.commonLabels
		if pg.backup.cronjob.storage.resourcePolicy == "keep" || len(pg.commonAnnotations) > 0 || len(pg.backup.cronjob.storage.annotations) > 0 {
			annotations: {
				if pg.backup.cronjob.storage.resourcePolicy == "keep" {
					"helm.sh/resource-policy": "keep"
				}
				for k, v in pg.commonAnnotations {"\(k)": v}
				for k, v in pg.backup.cronjob.storage.annotations {"\(k)": v}
			}
		}
	}
	spec: {
		accessModes: pg.backup.cronjob.storage.accessModes
		resources: requests: storage: pg.backup.cronjob.storage.size
		if pg.backup.cronjob.storage.storageClass != "" {
			if pg.backup.cronjob.storage.storageClass == "-" {
				storageClassName: ""
			}
			if pg.backup.cronjob.storage.storageClass != "-" {
				storageClassName: pg.backup.cronjob.storage.storageClass
			}
		}
	}
}

// 2. /charts/postgresql/templates/backup/networkpolicy.yaml
#PostgresqlBackupNetworkPolicy: {
	#config: #Config

	// Lines 10-17 style helpers repeated here
	let pg = #config."hyperswitch-app".postgresql

	let _labels = {
		for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
		"app.kubernetes.io/name":      "postgresql"
		"app.kubernetes.io/instance":  #config.metadata.name
		"app.kubernetes.io/component": "pg_dumpall"
	}

	apiVersion: "networking.k8s.io/v1"
	kind:       "NetworkPolicy"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql-pgdumpall"
		namespace: #config.metadata.namespace
		labels:    _labels & pg.commonLabels
		if len(pg.commonAnnotations) > 0 {
			annotations: pg.commonAnnotations
		}
	}
	spec: {
		podSelector: matchLabels: {
			for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
			"app.kubernetes.io/name":      "postgresql"
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "pg_dumpall"
			for k, v in pg.backup.cronjob.labels {"\(k)": v}
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
#PostgresqlBackupCronJob: {
	#config: #Config

	// Lines 10-17 style helpers repeated here
	let pg = #config."hyperswitch-app".postgresql

	let _labels = {
		for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
		"app.kubernetes.io/name":      "postgresql"
		"app.kubernetes.io/instance":  #config.metadata.name
		"app.kubernetes.io/component": "pg_dumpall"
	}

	apiVersion: "batch/v1"
	kind:       "CronJob"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql-pgdumpall"
		namespace: #config.metadata.namespace
		labels:    _labels & pg.commonLabels & pg.backup.cronjob.labels
		if len(pg.commonAnnotations) > 0 || len(pg.backup.cronjob.annotations) > 0 {
			annotations: pg.commonAnnotations & pg.backup.cronjob.annotations
		}
	}
	spec: {
		schedule: pg.backup.cronjob.schedule
		if pg.backup.cronjob.timeZone != "" {
			timeZone: pg.backup.cronjob.timeZone
		}
		concurrencyPolicy:          pg.backup.cronjob.concurrencyPolicy
		failedJobsHistoryLimit:     pg.backup.cronjob.failedJobsHistoryLimit
		successfulJobsHistoryLimit: pg.backup.cronjob.successfulJobsHistoryLimit
		if pg.backup.cronjob.startingDeadlineSeconds != "" {
			startingDeadlineSeconds: pg.backup.cronjob.startingDeadlineSeconds
		}
		jobTemplate: spec: {
			if pg.backup.cronjob.ttlSecondsAfterFinished != "" {
				ttlSecondsAfterFinished: pg.backup.cronjob.ttlSecondsAfterFinished
			}
			template: {
				metadata: {
					labels: _labels & pg.commonLabels & pg.backup.cronjob.labels
					if len(pg.commonAnnotations) > 0 || len(pg.backup.cronjob.annotations) > 0 {
						annotations: pg.commonAnnotations & pg.backup.cronjob.annotations
					}
				}
				spec: {
					if len(pg.image.pullSecrets) > 0 {
						imagePullSecrets: [for s in pg.image.pullSecrets {name: s}]
					}
					if len(pg.backup.cronjob.nodeSelector) > 0 {
						nodeSelector: pg.backup.cronjob.nodeSelector
					}
					if len(pg.backup.cronjob.tolerations) > 0 {
						tolerations: pg.backup.cronjob.tolerations
					}
					containers: [
						{
							name:            "\(#config.metadata.name)-postgresql-pgdumpall"
							image:           "\(pg.image.registry)/\(pg.image.repository):\(pg.image.tag)"
							imagePullPolicy: pg.image.pullPolicy
							env: [
								{
									name: "PGUSER"
									if pg.auth.enablePostgresUser {
										value: "postgres"
									}
									if !pg.auth.enablePostgresUser {
										value: pg.auth.username
									}
								},
								if !pg.auth.usePasswordFiles {
									{
										name: "PGPASSWORD"
										valueFrom: secretKeyRef: {
											name: "\(#config.metadata.name)-postgresql"
											key:  "postgres-password"
										}
									}
								},
								if pg.auth.usePasswordFiles {
									{
										name:  "PGPASSFILE"
										value: "/opt/bitnami/postgresql/secrets/postgres-password"
									}
								},
								{
									name:  "PGHOST"
									value: "\(#config.metadata.name)-postgresql"
								},
								{
									name:  "PGPORT"
									value: "\(pg.primary.service.ports.postgresql)"
								},
								{
									name:  "PGDUMP_DIR"
									value: pg.backup.cronjob.storage.mountPath
								},
								if pg.tls.enabled {
									{
										name: "PGSSLROOTCERT"
										let _caCert = [if pg.tls.autoGenerated {"ca.crt"}, pg.tls.certCAFilename][0]
										value: "/tmp/certs/\(_caCert)"
									}
								},
							]
							command: pg.backup.cronjob.command
							volumeMounts: [
								if pg.tls.enabled {
									{
										name:      "raw-certificates"
										mountPath: "/tmp/certs"
									}
								},
								if pg.backup.cronjob.storage.enabled {
									{
										name:      "datadir"
										mountPath: pg.backup.cronjob.storage.mountPath
										if pg.backup.cronjob.storage.subPath != "" {
											subPath: pg.backup.cronjob.storage.subPath
										}
									}
								},
								{
									name:      "empty-dir"
									mountPath: "/tmp"
									subPath:   "tmp-dir"
								},
								...pg.backup.cronjob.extraVolumeMounts,
							]
							if pg.backup.cronjob.containerSecurityContext.enabled {
								securityContext: {
									runAsUser:                pg.backup.cronjob.containerSecurityContext.runAsUser
									runAsGroup:               pg.backup.cronjob.containerSecurityContext.runAsGroup
									runAsNonRoot:             pg.backup.cronjob.containerSecurityContext.runAsNonRoot
									privileged:               pg.backup.cronjob.containerSecurityContext.privileged
									readOnlyRootFilesystem:   pg.backup.cronjob.containerSecurityContext.readOnlyRootFilesystem
									allowPrivilegeEscalation: pg.backup.cronjob.containerSecurityContext.allowPrivilegeEscalation
									capabilities: drop:   pg.backup.cronjob.containerSecurityContext.capabilities.drop
									seccompProfile: type: pg.backup.cronjob.containerSecurityContext.seccompProfile.type
								}
							}
							resources: pg.backup.cronjob.resources
						},
					]
					restartPolicy: pg.backup.cronjob.restartPolicy
					if pg.backup.cronjob.podSecurityContext.enabled {
						securityContext: fsGroup: pg.backup.cronjob.podSecurityContext.fsGroup
					}
					volumes: [
						if pg.tls.enabled {
							{
								name: "raw-certificates"
								secret: secretName: "\(#config.metadata.name)-postgresql-crt"
							}
						},
						if pg.backup.cronjob.storage.enabled {
							{
								name: "datadir"
								persistentVolumeClaim: {
									if pg.backup.cronjob.storage.existingClaim != "" {
										claimName: pg.backup.cronjob.storage.existingClaim
									}
									if pg.backup.cronjob.storage.existingClaim == "" {
										claimName: "\(#config.metadata.name)-postgresql-pgdumpall"
									}
								}
							}
						},
						{
							name: "empty-dir"
							emptyDir: {}
						},
						...pg.backup.cronjob.extraVolumes,
					]
				}
			}
		}
	}
}
