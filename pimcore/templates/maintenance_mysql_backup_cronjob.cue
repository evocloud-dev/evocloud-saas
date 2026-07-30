package templates

import (
	batchv1 "k8s.io/api/batch/v1"
)

#CronJobMysqlBackup: batchv1.#CronJob & {
	#config: #Config

	apiVersion: "batch/v1"
	kind:       "CronJob"
	metadata: {
		name:      "\(#config.metadata.name)-maintenance-mysql-backup"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: {
		schedule:          "@daily"
		concurrencyPolicy: "Forbid"
		jobTemplate: spec: {
			ttlSecondsAfterFinished: 60
			template: {
				metadata: {
					labels: {
						"app.kubernetes.io/name":     #config.metadata.name
						"app.kubernetes.io/instance": "\(#config.metadata.name)-maintenance-mysql-backup"
					}
				}
				spec: {
					if #config.maintenance.mysqlBackup.imagePullSecrets != _|_ && len(#config.maintenance.mysqlBackup.imagePullSecrets) > 0 {
						imagePullSecrets: #config.maintenance.mysqlBackup.imagePullSecrets
					}
					restartPolicy: "OnFailure"
					initContainers: [
						{
							name:  "wait-for-mysql"
							image: "divante/mysql-client:1.0.0"
							command: [
								"sh",
								"-c",
								"until mysql -u \"\(#config.pimcore.db.username)\" -p\"\(#config.pimcore.db.password)\" -h \"\(#config.pimcore.db.host)\" \"\(#config.pimcore.db.name)\" -e \"SELECT 1\"; do echo wait-for-mysql; sleep 5; done;",
							]
						},
					]
					containers: [
						{
							name:            "mysql-backup"
							image:           "\(#config.maintenance.mysqlBackup.image.registry):\(#config.maintenance.mysqlBackup.image.tag)"
							imagePullPolicy: #config.maintenance.mysqlBackup.image.pullPolicy
							command: ["/bin/sh", "-c"]
							args: [
								"""
								COMPRESSION_TOOL=\"\(#config.maintenance.mysqlBackup.compression.tool)\"
								COMPRESSION_EXT=\"\"
								DBNAME=\"\(#config.pimcore.db.name)\"
								BACKUP_DIR=\"/backup\"
								TODAY=$(date +%Y-%m-%d)
								DAY_OF_WEEK=$(date +%u)
								case \"$COMPRESSION_TOOL\" in
								  gzip|pigz) COMPRESSION_EXT=\".gz\" ;;
								  xz|pixz) COMPRESSION_EXT=\".xz\" ;;
								  bzip2|pbzip2|lbzip2) COMPRESSION_EXT=\".bz2\" ;;
								  zstd|zstdmt) COMPRESSION_EXT=\".zst\" ;;
								  lz4) COMPRESSION_EXT=\".lz4\" ;;
								  \"\" ) ;;
								  *) echo \"WARNING: Unknown compression tool $COMPRESSION_TOOL; using uncompressed dump\"; COMPRESSION_TOOL=\"\";;
								esac
								
								FILENAME=\"$BACKUP_DIR/$DBNAME-$TODAY.sql$COMPRESSION_EXT\"
								
								if [ -n \"$COMPRESSION_TOOL\" ] && ! command -v \"$COMPRESSION_TOOL\" >/dev/null 2>&1; then
								  if ! command -v apt-get >/dev/null 2>&1; then
								    echo \"ERROR: apt-get not available - base image is not Debian/Ubuntu.\"
								    exit 1
								  fi
								
								  echo \"Installing compression tools ($COMPRESSION_TOOL)...\"
								  apt-get update
								  apt-get install -y --no-install-recommends \"$COMPRESSION_TOOL\"
								  apt-get clean
								fi
								
								if [ -n \"$COMPRESSION_TOOL\" ] && ! command -v \"$COMPRESSION_TOOL\" >/dev/null 2>&1; then
								  echo \"ERROR: Compression tool $COMPRESSION_TOOL could not be installed.\"
								  exit 1
								fi
								
								# Perform daily backup
								echo \"Creating backup of $DBNAME to $FILENAME\"
								if [ -n \"$COMPRESSION_TOOL\" ]; then
								  mysqldump \\
								    -h \"\(#config.pimcore.db.host)\" \\
								    -u \"\(#config.pimcore.db.username)\" \\
								    -p\"\(#config.pimcore.db.password)\" \\
								    \"\(#config.pimcore.db.name)\" \\
								    | \"$COMPRESSION_TOOL\" > \"$FILENAME\" || exit 1
								else
								  mysqldump \\
								    -h \"\(#config.pimcore.db.host)\" \\
								    -u \"\(#config.pimcore.db.username)\" \\
								    -p\"\(#config.pimcore.db.password)\" \\
								    \"\(#config.pimcore.db.name)\" \\
								    > \"$FILENAME\" || exit 1
								fi
								echo \"Backup done\"
								
								# Weekly backup on Sunday
								
								if [ \"$DAY_OF_WEEK\" -eq 7 ]; then
								  cp \"$FILENAME\" \"$BACKUP_DIR/weekly-$DBNAME-$TODAY.sql$COMPRESSION_EXT\"
								fi
								
								# Monthly backup on the last day of the month
								if [ \"$(date --date='tomorrow' +%m)\" != \"$(date +%m)\" ]; then
								  cp \"$FILENAME\" \"$BACKUP_DIR/monthly-$DBNAME-$TODAY.sql$COMPRESSION_EXT\"
								fi
								
								echo \"Cleanup old backups\"
								# Cleanup old backups, keep daily backups for 7 days, weekly for 30 days, monthly for 365 days
								find \"$BACKUP_DIR\" -type f -name \"$DBNAME-*.sql*\" -mtime +7 -exec rm \"{}\" +
								find \"$BACKUP_DIR\" -type f -name \"weekly-$DBNAME-*.sql*\" -mtime +30 -exec rm \"{}\" +
								find \"$BACKUP_DIR\" -type f -name \"monthly-$DBNAME-*.sql*\" -mtime +365 -exec rm \"{}\" +
								echo \"Cleanup done\"
								""",
							]
							resources: #config.maintenance.mysqlBackup.resources
							volumeMounts: [
								{
									name:      "pimcore-mysql-backup"
									mountPath: "/backup"
									subPath:   #config.pvc.mysqlBackup.subPath
								},
							]
						},
					]
					volumes: [
						{
							name: "pimcore-mysql-backup"
							persistentVolumeClaim: claimName: #backupClaimName
						},
					]
					if #config.nodeSelector != _|_ && #config.nodeSelector != {} {
						nodeSelector: #config.nodeSelector
					}
					if #config.affinity != _|_ && #config.affinity != {} {
						affinity: #config.affinity
					}
					if #config.tolerations.maintenance != _|_ {
						tolerations: #config.tolerations.maintenance
					}
				}
			}
		}
	}

	#backupClaimName: {
		if #config.pvc.mysqlBackup.existingClaim != "" {
			#config.pvc.mysqlBackup.existingClaim
		}
		if #config.pvc.mysqlBackup.existingClaim == "" {
			"\(#config.metadata.name)-\(#config.pvc.mysqlBackup.name)"
		}
	}
}
