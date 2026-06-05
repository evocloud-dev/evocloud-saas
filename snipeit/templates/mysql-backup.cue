package templates

import (
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
	"strings"
)

#MysqlBackupScriptConfigMap: corev1.#ConfigMap & {
	#config: #Config
	let c = #config
	let backupName = "\(#config.metadata.name)-mysql-backup"

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      backupName
		namespace: #config.metadata.namespace
		labels:    #MysqlBackupLabels & {#config: c}
	}
	data: {
		"mysql-backup.sh":  #mysqlBackupScript
		"mysql-restore.sh": #mysqlRestoreScript
	}
}

#MysqlBackupSanitizeConfigMap: corev1.#ConfigMap & {
	#config: #Config
	let c = #config
	let backup = #config["mysql-backup"]
	let backupName = "\(#config.metadata.name)-mysql-backup"

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(backupName)-sanitize"
		namespace: #config.metadata.namespace
		labels:    #MysqlBackupLabels & {#config: c}
	}
	data: "sanitize.sql": strings.Join(backup.sanitize.sql, "\n")
}

#MysqlBackupGCSSecret: corev1.#Secret & {
	#config: #Config
	let c = #config
	let backup = #config["mysql-backup"]
	let backupName = "\(#config.metadata.name)-mysql-backup"

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(backupName)-gcs"
		namespace: #config.metadata.namespace
		labels:    #MysqlBackupLabels & {#config: c}
	}
	type: "Opaque"
	stringData: "key.json": backup.gcs.serviceAccountKey
}

#MysqlBackupMysqlSecret: corev1.#Secret & {
	#config: #Config
	let c = #config
	let backup = #config["mysql-backup"]
	let backupName = "\(#config.metadata.name)-mysql-backup"

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(backupName)-mysql"
		namespace: #config.metadata.namespace
		labels:    #MysqlBackupLabels & {#config: c}
	}
	type: "Opaque"
	stringData: {
		DB_USER: backup.database.user
		DB_PASS: backup.database.pass
	}
}

#MysqlBackupCronJob: batchv1.#CronJob & {
	#config: #Config
	let c = #config
	let backup = #config["mysql-backup"]
	let backupName = "\(#config.metadata.name)-mysql-backup"

	apiVersion: "batch/v1"
	kind:       "CronJob"
	metadata: {
		name:      backupName
		namespace: #config.metadata.namespace
		labels:    #MysqlBackupLabels & {#config: c}
	}
	spec: {
		schedule:                   backup.schedule
		successfulJobsHistoryLimit: 1
		jobTemplate: spec: template: spec: #MysqlBackupPodSpec & {#config: c}
	}
}

#MysqlRestoreCronJob: batchv1.#CronJob & {
	#config: #Config
	let c = #config
	let backup = #config["mysql-backup"]
	let backupName = "\(#config.metadata.name)-mysql-backup"

	apiVersion: "batch/v1"
	kind:       "CronJob"
	metadata: {
		name:      backupName
		namespace: #config.metadata.namespace
		labels:    #MysqlBackupLabels & {#config: c}
	}
	spec: {
		schedule:                   backup.schedule
		successfulJobsHistoryLimit: 1
		jobTemplate: spec: template: spec: #MysqlRestorePodSpec & {#config: c}
	}
}

#MysqlBackupJob: batchv1.#Job & {
	#config: #Config
	let c = #config
	let backupName = "\(#config.metadata.name)-mysql-backup"

	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		name:      backupName
		namespace: #config.metadata.namespace
		labels:    #MysqlBackupLabels & {#config: c}
		annotations: {
			"helm.sh/hook":               "post-install,post-upgrade"
			"helm.sh/hook-delete-policy": "hook-succeeded"
		}
	}
	spec: template: spec: #MysqlBackupPodSpec & {#config: c}
}

#MysqlRestoreJob: batchv1.#Job & {
	#config: #Config
	let c = #config
	let backupName = "\(#config.metadata.name)-mysql-backup"

	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		name:      "\(backupName)-restore"
		namespace: #config.metadata.namespace
		labels:    #MysqlBackupLabels & {#config: c}
		annotations: {
			"helm.sh/hook":               "post-install,post-upgrade"
			"helm.sh/hook-delete-policy": "hook-succeeded"
		}
	}
	spec: template: spec: #MysqlRestorePodSpec & {#config: c}
}

#MysqlBackupPodSpec: corev1.#PodSpec & {
	#config: #Config
	let c = #config
	let backup = #config["mysql-backup"]
	let backupName = "\(#config.metadata.name)-mysql-backup"

	if len(backup.image.pullSecrets) > 0 {
		imagePullSecrets: [for secret in backup.image.pullSecrets {{name: secret}}]
	}
	restartPolicy: "Never"
	containers: [#MysqlBackupContainer & {#config: c}]
	volumes: [{
		name: "scripts"
		configMap: corev1.#ConfigMapVolumeSource & {
			name:        backupName
			defaultMode: 365
		}
	}, {
		name: "secret-key"
		secret: corev1.#SecretVolumeSource & {
			secretName: "\(backupName)-gcs"
		}
	}]
}

#MysqlRestorePodSpec: corev1.#PodSpec & {
	#config: #Config
	let c = #config
	let backup = #config["mysql-backup"]
	let backupName = "\(#config.metadata.name)-mysql-backup"

	if len(backup.image.pullSecrets) > 0 {
		imagePullSecrets: [for secret in backup.image.pullSecrets {{name: secret}}]
	}
	restartPolicy: "Never"
	containers: [#MysqlRestoreContainer & {#config: c}]
	volumes: [
		{
			name: "scripts"
			configMap: corev1.#ConfigMapVolumeSource & {
				name:        backupName
				defaultMode: 365
			}
		},
		if backup.sanitize.enabled {
			{
				name: "sanitize"
				configMap: corev1.#ConfigMapVolumeSource & {
					name: "\(backupName)-sanitize"
				}
			}
		},
		{
			name: "secret-key"
			secret: corev1.#SecretVolumeSource & {
				secretName: "\(backupName)-gcs"
			}
		},
	]
}

#MysqlBackupContainer: corev1.#Container & {
	#config: #Config
	let backup = #config["mysql-backup"]
	let backupName = "\(#config.metadata.name)-mysql-backup"

	name:            "mysql-backup"
	image:           "\(backup.image.name):\(backup.image.tag)"
	imagePullPolicy: backup.image.pullPolicy
	command:         ["sh", "-c", "/scripts/mysql-backup.sh"]
	env: [
		{name: "DB_HOST", value: backup.database.host},
		{name: "DB_NAME", value: backup.database.name},
		{name: "DB_CHARSET", value: backup.database.charset},
		{name: "GSBUCKET", value: backup.gcs.bucket.name},
		{name: "GSPATH", value: backup.gcs.bucket.path},
		{name: "FILENAME", value: backup._backupFilename},
	]
	envFrom: [{
		secretRef: corev1.#SecretEnvSource & {
			name: "\(backupName)-mysql"
		}
	}]
	resources: backup.resources
	volumeMounts: [{
		name:      "scripts"
		mountPath: "/scripts"
		readOnly:  true
	}, {
		name:      "secret-key"
		mountPath: "/etc/gcloud"
		readOnly:  true
	}]
}

#MysqlRestoreContainer: corev1.#Container & {
	#config: #Config
	let backup = #config["mysql-backup"]
	let backupName = "\(#config.metadata.name)-mysql-backup"

	name:            "mysql-backup"
	image:           "\(backup.image.name):\(backup.image.tag)"
	imagePullPolicy: backup.image.pullPolicy
	command:         ["sh", "-c", "/scripts/mysql-restore.sh"]
	env: [
		{name: "DB_HOST", value: backup.database.host},
		{name: "DB_NAME", value: backup.database.name},
		{name: "GSBUCKET", value: backup.gcs.bucket.name},
		{name: "GSPATH", value: backup.gcs.bucket.path},
		{name: "FILENAME", value: backup._backupFilename},
		if backup.sanitize.enabled {
			{name: "SANITIZE_ENABLED", value: "true"}
		},
	]
	envFrom: [{
		secretRef: corev1.#SecretEnvSource & {
			name: "\(backupName)-mysql"
		}
	}]
	resources: backup.resources
	volumeMounts: [
		{
			name:      "scripts"
			mountPath: "/scripts"
			readOnly:  true
		},
		{
			name:      "secret-key"
			mountPath: "/etc/gcloud"
			readOnly:  true
		},
		if backup.sanitize.enabled {
			{
				name:      "sanitize"
				mountPath: "/tmp/sanitize.sql"
				subPath:   "sanitize.sql"
			}
		},
	]
}

#MysqlBackupLabels: {
	#config: #Config
	let backup = #config["mysql-backup"]

	"app.kubernetes.io/name":     "mysql-backup"
	"app.kubernetes.io/instance": #config.metadata.name
	"helm.sh/chart":              backup.chart
}

#mysqlBackupScript: """
	#!/bin/sh -e
	
	# The following variables must be set.
	# DB_HOST=localhost
	# DB_USER=root
	# DB_PASS=password
	# DB_NAME='--all-databases'
	# GSBUCKET=bucketname
	# FILENAME=filename
	#
	# The following line prefixes the backups with the defined directory. it must be blank or end with a /
	# GSPATH=
	#
	# Change this if command is not in $PATH
	# MYSQLDUMPPATH=
	# GSUTILPATH=
	#
	# Change this if you want temporary file to be created in specific path
	# TMP_PATH=
	
	DATESTAMP=$(date +"_%Y-%m-%d")
	DAY=$(date +"%d")
	DAYOFWEEK=$(date +"%A")
	
	if [ "$DAY" = "01" ]; then
		PERIOD=month
	elif [ "$DAYOFWEEK" = "Sunday" ]; then
		PERIOD=week
	else
		PERIOD=day
	fi
	
	printf "Selected period: %s\\n" "$PERIOD"
	gcloud auth activate-service-account --key-file=/etc/gcloud/key.json
	printf "\\nStarting backing up the database to a file...\\n"
	"${MYSQLDUMPPATH}mysqldump" --quick --default-character-set="${DB_CHARSET}" --host="${DB_HOST}" --user="${DB_USER}" --password="${DB_PASS}" "${DB_NAME}" > "${TMP_PATH}${FILENAME}${DATESTAMP}.sql"
	printf "Done backing up the database to a file.\\n\\nStarting compression...\\n"
	gzip "${TMP_PATH}${FILENAME}${DATESTAMP}.sql"
	printf "Done compressing the backup file.\\n\\nRemoving old backup (2 %ss ago)...\\n" "$PERIOD"
	"${GSUTILPATH}gsutil" rm -R "gs://${GSBUCKET}/${GSPATH}previous_${PERIOD}/" || true
	printf "Old backup removed.\\n\\nMoving the backup from past %s to another folder...\\n" "$PERIOD"
	"${GSUTILPATH}gsutil" mv "gs://${GSBUCKET}/${GSPATH}${PERIOD}/" "gs://${GSBUCKET}/${GSPATH}previous_${PERIOD}" || true
	printf "Past backup moved.\\n\\nUploading the new backup...\\n"
	"${GSUTILPATH}gsutil" cp "${TMP_PATH}${FILENAME}${DATESTAMP}.sql.gz" "gs://${GSBUCKET}/${GSPATH}${PERIOD}/"
	printf "New backup uploaded.\\n\\nAll done."
	"""

#mysqlRestoreScript: """
	#!/bin/sh -e
	
	# The following variables must be set.
	# DB_HOST=localhost
	# DB_USER=root
	# DB_PASS=password
	# DB_NAME='--all-databases'
	# GSBUCKET=bucketname
	# FILENAME=filename
	#
	# The following line prefixes the backups with the defined directory. it must be blank or end with a /
	# GSPATH=
	#
	# Change this if command is not in $PATH
	# MYSQLPATH=
	# GSUTILPATH=
	#
	# Change this if you want temporary file to be created in specific path
	# TMP_PATH=
	
	gcloud auth activate-service-account --key-file=/etc/gcloud/key.json
	printf "\\nGetting latest Backup..."
	"${GSUTILPATH}gsutil" cp "gs://${GSBUCKET}/${GSPATH}day/${FILENAME}_*.sql.gz" "${TMP_PATH}${FILENAME}.sql.gz"
	printf "\\nUncompressing the SQL-Dump..."
	gunzip "${TMP_PATH}${FILENAME}.sql.gz"
	printf "\\nImporting the SQL-Dump"
	"${MYSQLPATH}mysql" --host="${DB_HOST}" --user="${DB_USER}" --password="${DB_PASS}" "${DB_NAME}" < "${TMP_PATH}${FILENAME}.sql"
	
	if [ ! -z "$SANITIZE_ENABLED" ]; then
		printf "\\nExecuting sanitize SQL-Commands"
		"${MYSQLPATH}mysql" --host="${DB_HOST}" --user="${DB_USER}" --password="${DB_PASS}" "${DB_NAME}" < "/tmp/sanitize.sql"
		printf "\\nFinished executing Sanitize"
	else
		printf "\\nSanitize is disabled"
	fi
	"""