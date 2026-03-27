package templates

import (
	"strings"
	"strconv"
	corev1 "k8s.io/api/core/v1"
)

// ── Name Helpers ──

// #NextcloudName mirrors {{- define "nextcloud.name" -}}
#NextcloudName: {
	#in: #Config
	out:     *#in.metadata.name | string
	if #in.nameOverride != "" {
		out: #in.nameOverride
	}
}

// #NextcloudFullname mirrors {{- define "nextcloud.fullname" -}}
#NextcloudFullname: {
	#in: #Config
	out:     string
	if #in.fullnameOverride != "" {
		out: #in.fullnameOverride
	}
	if #in.fullnameOverride == "" {
		#name: #NextcloudName & {#in: #in}
		if strings.Contains(#in.metadata.name, #name.out) {
			out: #in.metadata.name
		}
		if !strings.Contains(#in.metadata.name, #name.out) {
			out: "\(#in.metadata.name)-\(#name.out)"
		}
	}
}

// #NextcloudRedisFullname mirrors {{- define "nextcloud.redis.fullname" -}}
#NextcloudRedisFullname: {
	#in: #Config
	out:     #in.metadata.name + "-redis"
}

// #NextcloudChart mirrors {{- define "nextcloud.chart" -}}
#NextcloudChart: {
	#in: #Config
	out:     "\(#in.metadata.name)-\(#in.moduleVersion)" // Simplified for Timoni
}

// ── Label Helpers ──

// #NextcloudSelectorLabels mirrors {{- define "nextcloud.selectorLabels" -}}
#NextcloudSelectorLabels: {
	#in:    #Config
	#component: string | *""
	labels: {
		"app.kubernetes.io/name":     (#NextcloudName & {#in: #in}).out
		"app.kubernetes.io/instance": #in.metadata.name
		if #component != "" {
			"app.kubernetes.io/component": #component
		}
	}
}

// #NextcloudLabels mirrors {{- define "nextcloud.labels" -}}
#NextcloudLabels: {
	#in:    #Config
	#component: string | *""
	labels: (#NextcloudSelectorLabels & {#in: #in, #component: #component}).labels & {
		"helm.sh/chart":                (#NextcloudChart & {#in: #in}).out
		"app.kubernetes.io/managed-by": "timoni"
		"app.kubernetes.io/version":    #in.moduleVersion
	}
}

// ── Environment Variables ──

// #NextcloudEnv mirrors {{- define "nextcloud.env" -}}
#NextcloudEnv: {
	#in:          #Config
	#ncSecretRef: string | *#in.ncSecretRef
	#dbSecretRef: string | *#in.dbSecretRef

	out: [
		if #in.nextcloud.phpClientHttpsFix.enabled {
			{name: "OVERWRITEPROTOCOL", value: #in.nextcloud.phpClientHttpsFix.protocol}
		},
		if #in.nextcloud.phpClientHttpsFix.enabled {
			{name: "OVERWRITECLIURL", value: "\(#in.nextcloud.phpClientHttpsFix.protocol)://\(#in.nextcloud.host)"}
		},

		// MariaDB (Subchart/In-cluster)
		if #in.database.mariadb.enabled {
			{name: "MYSQL_HOST", value: #in.database.mariadb.primaryHost}
		},
		if #in.database.mariadb.enabled {
			{name: "MYSQL_DATABASE", value: #in.database.mariadb.auth.database}
		},
		if #in.database.mariadb.enabled {
			{
				name: "MYSQL_USER"
				valueFrom: secretKeyRef: {
					name: #dbSecretRef
					key:  #in.database.externalDatabase.existingSecret.usernameKey
				}
			}
		},
		if #in.database.mariadb.enabled {
			{
				name: "MYSQL_PASSWORD"
				valueFrom: secretKeyRef: {
					name: #dbSecretRef
					key:  #in.database.externalDatabase.existingSecret.passwordKey
				}
			}
		},

		// PostgreSQL (Subchart/In-cluster)
		if #in.database.postgresql.enabled {
			{name: "POSTGRES_HOST", value: #in.database.postgresql.primaryHost}
		},
		if #in.database.postgresql.enabled {
			{name: "POSTGRES_DB", value: #in.database.postgresql.auth.database}
		},
		if #in.database.postgresql.enabled {
			{
				name: "POSTGRES_USER"
				valueFrom: secretKeyRef: {
					name: #dbSecretRef
					key:  #in.database.externalDatabase.existingSecret.usernameKey
				}
			}
		},
		if #in.database.postgresql.enabled {
			{
				name: "POSTGRES_PASSWORD"
				valueFrom: secretKeyRef: {
					name: #dbSecretRef
					key:  #in.database.externalDatabase.existingSecret.passwordKey
				}
			}
		},

		// Internal (SQLite) - ONLY if nothing else is enabled
		if !#in.database.mariadb.enabled && !#in.database.postgresql.enabled && !#in.database.externalDatabase.enabled {
			{name: "SQLITE_DATABASE", value: #in.database.internalDatabase.name}
		},

		// External DB - PostgreSQL
		if #in.database.externalDatabase.enabled && #in.database.externalDatabase.type == "postgresql" {
			{
				name: "POSTGRES_HOST"
				if #in.database.externalDatabase.existingSecret.hostKey != "" {
					valueFrom: secretKeyRef: {name: #dbSecretRef, key: #in.database.externalDatabase.existingSecret.hostKey}
				}
				if #in.database.externalDatabase.existingSecret.hostKey == "" {
					value: #in.database.externalDatabase.host
				}
			}
		},
		if #in.database.externalDatabase.enabled && #in.database.externalDatabase.type == "postgresql" {
			{
				name: "POSTGRES_DB"
				if #in.database.externalDatabase.existingSecret.databaseKey != "" {
					valueFrom: secretKeyRef: {name: #dbSecretRef, key: #in.database.externalDatabase.existingSecret.databaseKey}
				}
				if #in.database.externalDatabase.existingSecret.databaseKey == "" {
					value: #in.database.externalDatabase.database
				}
			}
		},
		if #in.database.externalDatabase.enabled && #in.database.externalDatabase.type == "postgresql" {
			{name: "POSTGRES_USER", valueFrom: secretKeyRef: {name: #dbSecretRef, key: #in.database.externalDatabase.existingSecret.usernameKey}}
		},
		if #in.database.externalDatabase.enabled && #in.database.externalDatabase.type == "postgresql" {
			{name: "POSTGRES_PASSWORD", valueFrom: secretKeyRef: {name: #dbSecretRef, key: #in.database.externalDatabase.existingSecret.passwordKey}}
		},

		// External DB - MySQL
		if #in.database.externalDatabase.enabled && #in.database.externalDatabase.type == "mysql" {
			{
				name: "MYSQL_HOST"
				if #in.database.externalDatabase.existingSecret.hostKey != "" {
					valueFrom: secretKeyRef: {name: #dbSecretRef, key: #in.database.externalDatabase.existingSecret.hostKey}
				}
				if #in.database.externalDatabase.existingSecret.hostKey == "" {
					value: #in.database.externalDatabase.host
				}
			}
		},
		if #in.database.externalDatabase.enabled && #in.database.externalDatabase.type == "mysql" {
			{
				name: "MYSQL_DATABASE"
				if #in.database.externalDatabase.existingSecret.databaseKey != "" {
					valueFrom: secretKeyRef: {name: #dbSecretRef, key: #in.database.externalDatabase.existingSecret.databaseKey}
				}
				if #in.database.externalDatabase.existingSecret.databaseKey == "" {
					value: #in.database.externalDatabase.database
				}
			}
		},
		if #in.database.externalDatabase.enabled && #in.database.externalDatabase.type == "mysql" {
			{name: "MYSQL_USER", valueFrom: secretKeyRef: {name: #dbSecretRef, key: #in.database.externalDatabase.existingSecret.usernameKey}}
		},
		if #in.database.externalDatabase.enabled && #in.database.externalDatabase.type == "mysql" {
			{name: "MYSQL_PASSWORD", valueFrom: secretKeyRef: {name: #dbSecretRef, key: #in.database.externalDatabase.existingSecret.passwordKey}}
		},

		// Admin
		{name: "NEXTCLOUD_ADMIN_USER", valueFrom: secretKeyRef: {name: #ncSecretRef, key: #in.nextcloud.existingSecret.usernameKey}},
		{name: "NEXTCLOUD_ADMIN_PASSWORD", valueFrom: secretKeyRef: {name: #ncSecretRef, key: #in.nextcloud.existingSecret.passwordKey}},

		// Trusted Domains
		{
			name: "NEXTCLOUD_TRUSTED_DOMAINS"
			if len(#in.nextcloud.trustedDomains) > 0 {
				value: strings.Join(#in.nextcloud.trustedDomains, " ")
			}
			if len(#in.nextcloud.trustedDomains) == 0 {
				#fullname: (#NextcloudFullname & {#in: #in}).out
				value:     #in.nextcloud.host + _metricsSuffix
				_metricsSuffix: *"" | string
				if #in.metrics.enabled {
					_metricsSuffix: " \(#fullname).\(#in.metadata.namespace).svc.cluster.local"
				}
			}
		},

		if #in.nextcloud.update != 0 {
			{name: "NEXTCLOUD_UPDATE", value: strconv.FormatInt(#in.nextcloud.update, 10)}
		},

		{name: "NEXTCLOUD_DATA_DIR", value: #in.nextcloud.datadir},
		{name: "MAINTENANCE_WINDOW_START", value: "\( #in.nextcloud.maintenanceWindowStart )"},
		{name: "NEXTCLOUD_FORCE_STS", value: "\( #in.nextcloud.forceSTSSet )"},
		{name: "TRUSTED_PROXIES", value: strings.Join(#in.nextcloud.trustedProxies, " ")},
		{name: "NEXTCLOUD_BRUTEFORCE_PROTECTION", value: "\( #in.nextcloud.bruteForceProtection )"},
		if len(#in.nextcloud.bruteForceWhitelistedIps) > 0 {
			{name: "NEXTCLOUD_BRUTEFORCE_WHITELISTED_IPS", value: strings.Join(#in.nextcloud.bruteForceWhitelistedIps, " ")}
		},

		// Mail
		if #in.nextcloud.mail.enabled {
			{name: "MAIL_FROM_ADDRESS", value: #in.nextcloud.mail.fromAddress}
		},
		if #in.nextcloud.mail.enabled {
			{name: "MAIL_DOMAIN", value: #in.nextcloud.mail.domain}
		},
		if #in.nextcloud.mail.enabled {
			{name: "SMTP_SECURE", value: #in.nextcloud.mail.smtp.secure}
		},
		if #in.nextcloud.mail.enabled {
			{name: "SMTP_PORT", value: strconv.FormatInt(#in.nextcloud.mail.smtp.port, 10)}
		},
		if #in.nextcloud.mail.enabled {
			{name: "SMTP_AUTHTYPE", value: #in.nextcloud.mail.smtp.authtype}
		},
		if #in.nextcloud.mail.enabled {
			{name: "SMTP_HOST", valueFrom: secretKeyRef: {name: #ncSecretRef, key: #in.nextcloud.existingSecret.smtpHostKey}}
		},
		if #in.nextcloud.mail.enabled {
			{name: "SMTP_NAME", valueFrom: secretKeyRef: {name: #ncSecretRef, key: #in.nextcloud.existingSecret.smtpUsernameKey}}
		},
		if #in.nextcloud.mail.enabled {
			{name: "SMTP_PASSWORD", valueFrom: secretKeyRef: {name: #ncSecretRef, key: #in.nextcloud.existingSecret.smtpPasswordKey}}
		},

		// Redis
		if #in.redis.enabled {
			{name: "REDIS_HOST", value: #in.redis.primaryHost}
		},
		if #in.redis.enabled {
			{name: "REDIS_HOST_PORT", value: strconv.FormatInt(#in.redis.port, 10)}
		},
		if #in.redis.enabled && #in.redis.auth.enabled {
			{name: "REDIS_HOST_PASSWORD", value: #in.redis.auth.password}
		},

		// External Redis
		if !#in.redis.enabled && #in.externalRedis.enabled {
			{name: "REDIS_HOST", value: #in.externalRedis.host}
		},
		if !#in.redis.enabled && #in.externalRedis.enabled {
			{name: "REDIS_HOST_PORT", value: #in.externalRedis.port}
		},
		if !#in.redis.enabled && #in.externalRedis.enabled && #in.externalRedis.password != "" {
			{name: "REDIS_HOST_PASSWORD", value: #in.externalRedis.password}
		},

		// S3
		if #in.nextcloud.objectStore.s3.enabled {
			{name: "OBJECTSTORE_S3_SSL", value: strconv.FormatBool(#in.nextcloud.objectStore.s3.ssl)}
		},
		if #in.nextcloud.objectStore.s3.enabled {
			{name: "OBJECTSTORE_S3_USEPATH_STYLE", value: strconv.FormatBool(#in.nextcloud.objectStore.s3.usePathStyle)}
		},
		if #in.nextcloud.objectStore.s3.enabled && #in.nextcloud.objectStore.s3.legacyAuth {
			{name: "OBJECTSTORE_S3_LEGACYAUTH", value: strconv.FormatBool(#in.nextcloud.objectStore.s3.legacyAuth)}
		},
		if #in.nextcloud.objectStore.s3.enabled {
			{name: "OBJECTSTORE_S3_AUTOCREATE", value: strconv.FormatBool(#in.nextcloud.objectStore.s3.autoCreate)}
		},
		if #in.nextcloud.objectStore.s3.enabled {
			{name: "OBJECTSTORE_S3_REGION", value: #in.nextcloud.objectStore.s3.region}
		},
		if #in.nextcloud.objectStore.s3.enabled {
			{name: "OBJECTSTORE_S3_PORT", value: #in.nextcloud.objectStore.s3.port}
		},
		if #in.nextcloud.objectStore.s3.enabled {
			{name: "OBJECTSTORE_S3_STORAGE_CLASS", value: #in.nextcloud.objectStore.s3.storageClass}
		},
		if #in.nextcloud.objectStore.s3.enabled && #in.nextcloud.objectStore.s3.prefix != "" {
			{name: "OBJECTSTORE_S3_OBJECT_PREFIX", value: #in.nextcloud.objectStore.s3.prefix}
		},
		if #in.nextcloud.objectStore.s3.enabled {
			{
				name: "OBJECTSTORE_S3_HOST"
				if #in.nextcloud.objectStore.s3.existingSecret != "" && #in.nextcloud.objectStore.s3.secretKeys.host != "" {
					valueFrom: secretKeyRef: {name: #in.nextcloud.objectStore.s3.existingSecret, key: #in.nextcloud.objectStore.s3.secretKeys.host}
				}
				if #in.nextcloud.objectStore.s3.existingSecret == "" || #in.nextcloud.objectStore.s3.secretKeys.host == "" {
					value: #in.nextcloud.objectStore.s3.host
				}
			}
		},
		if #in.nextcloud.objectStore.s3.enabled {
			{
				name: "OBJECTSTORE_S3_BUCKET"
				if #in.nextcloud.objectStore.s3.existingSecret != "" && #in.nextcloud.objectStore.s3.secretKeys.bucket != "" {
					valueFrom: secretKeyRef: {name: #in.nextcloud.objectStore.s3.existingSecret, key: #in.nextcloud.objectStore.s3.secretKeys.bucket}
				}
				if #in.nextcloud.objectStore.s3.existingSecret == "" || #in.nextcloud.objectStore.s3.secretKeys.bucket == "" {
					value: #in.nextcloud.objectStore.s3.bucket
				}
			}
		},
		if #in.nextcloud.objectStore.s3.enabled {
			{
				name: "OBJECTSTORE_S3_KEY"
				if #in.nextcloud.objectStore.s3.existingSecret != "" && #in.nextcloud.objectStore.s3.secretKeys.accessKey != "" {
					valueFrom: secretKeyRef: {name: #in.nextcloud.objectStore.s3.existingSecret, key: #in.nextcloud.objectStore.s3.secretKeys.accessKey}
				}
				if #in.nextcloud.objectStore.s3.existingSecret == "" || #in.nextcloud.objectStore.s3.secretKeys.accessKey == "" {
					value: #in.nextcloud.objectStore.s3.accessKey
				}
			}
		},
		if #in.nextcloud.objectStore.s3.enabled {
			{
				name: "OBJECTSTORE_S3_SECRET"
				if #in.nextcloud.objectStore.s3.existingSecret != "" && #in.nextcloud.objectStore.s3.secretKeys.secretKey != "" {
					valueFrom: secretKeyRef: {name: #in.nextcloud.objectStore.s3.existingSecret, key: #in.nextcloud.objectStore.s3.secretKeys.secretKey}
				}
				if #in.nextcloud.objectStore.s3.existingSecret == "" || #in.nextcloud.objectStore.s3.secretKeys.secretKey == "" {
					value: #in.nextcloud.objectStore.s3.secretKey
				}
			}
		},
		if #in.nextcloud.objectStore.s3.enabled {
			{
				name: "OBJECTSTORE_S3_SSE_C_KEY"
				if #in.nextcloud.objectStore.s3.existingSecret != "" && #in.nextcloud.objectStore.s3.secretKeys.sse_c_key != "" {
					valueFrom: secretKeyRef: {name: #in.nextcloud.objectStore.s3.existingSecret, key: #in.nextcloud.objectStore.s3.secretKeys.sse_c_key}
				}
				if #in.nextcloud.objectStore.s3.existingSecret == "" || #in.nextcloud.objectStore.s3.secretKeys.sse_c_key == "" {
					value: #in.nextcloud.objectStore.s3.sse_c_key
				}
			}
		},

		// Swift
		if #in.nextcloud.objectStore.swift.enabled {
			{name: "OBJECTSTORE_SWIFT_AUTOCREATE", value: strconv.FormatBool(#in.nextcloud.objectStore.swift.autoCreate)}
		},
		if #in.nextcloud.objectStore.swift.enabled {
			{name: "OBJECTSTORE_SWIFT_USER_NAME", value: #in.nextcloud.objectStore.swift.user.name}
		},
		if #in.nextcloud.objectStore.swift.enabled {
			{name: "OBJECTSTORE_SWIFT_USER_PASSWORD", value: #in.nextcloud.objectStore.swift.user.password}
		},
		if #in.nextcloud.objectStore.swift.enabled {
			{name: "OBJECTSTORE_SWIFT_USER_DOMAIN", value: #in.nextcloud.objectStore.swift.user.domain}
		},
		if #in.nextcloud.objectStore.swift.enabled {
			{name: "OBJECTSTORE_SWIFT_PROJECT_NAME", value: #in.nextcloud.objectStore.swift.project.name}
		},
		if #in.nextcloud.objectStore.swift.enabled {
			{name: "OBJECTSTORE_SWIFT_PROJECT_DOMAIN", value: #in.nextcloud.objectStore.swift.project.domain}
		},
		if #in.nextcloud.objectStore.swift.enabled {
			{name: "OBJECTSTORE_SWIFT_SERVICE_NAME", value: #in.nextcloud.objectStore.swift.service}
		},
		if #in.nextcloud.objectStore.swift.enabled {
			{name: "OBJECTSTORE_SWIFT_REGION", value: #in.nextcloud.objectStore.swift.region}
		},
		if #in.nextcloud.objectStore.swift.enabled {
			{name: "OBJECTSTORE_SWIFT_URL", value: #in.nextcloud.objectStore.swift.url}
		},
		if #in.nextcloud.objectStore.swift.enabled {
			{name: "OBJECTSTORE_SWIFT_CONTAINER_NAME", value: #in.nextcloud.objectStore.swift.container}
		},

		for env in #in.nextcloud.extraEnv {env},
	]
}

// ── Volume Mounts ──

// #NextcloudVolumeMounts mirrors {{- include "nextcloud.volumeMounts" . }}
#NextcloudVolumeMounts: {
	#in: #Config

	out: [
		{
			name:      "nextcloud-main"
			mountPath: "/var/www/"
			#subPath:  #in.persistence.subPath
			if #subPath == "" {
				subPath: "root"
			}
			if #subPath != "" {
				subPath: "\(#subPath)/root"
			}
		},
		{
			name:      "nextcloud-main"
			mountPath: "/var/www/html"
			#subPath:  #in.persistence.subPath
			if #subPath == "" {
				subPath: "html"
			}
			if #subPath != "" {
				subPath: "\(#subPath)/html"
			}
		},
		if #in.persistence.enabled && #in.persistence.nextcloudData.enabled {
			{
				name:      "nextcloud-data"
				mountPath: #in.nextcloud.datadir
				#subPath:  #in.persistence.nextcloudData.subPath
				if #subPath == "" {
					subPath: "data"
				}
				if #subPath != "" {
					subPath: "\(#subPath)/data"
				}
			}
		},
		if !#in.persistence.enabled || !#in.persistence.nextcloudData.enabled {
			{
				name:      "nextcloud-main"
				mountPath: #in.nextcloud.datadir
				#subPath:  #in.persistence.subPath
				if #subPath == "" {
					subPath: "data"
				}
				if #subPath != "" {
					subPath: "\(#subPath)/data"
				}
			}
		},
		{
			name:      "nextcloud-main"
			mountPath: "/var/www/html/config"
			#subPath:  #in.persistence.subPath
			if #subPath == "" {
				subPath: "config"
			}
			if #subPath != "" {
				subPath: "\(#subPath)/config"
			}
		},
		{
			name:      "nextcloud-main"
			mountPath: "/var/www/html/custom_apps"
			#subPath:  #in.persistence.subPath
			if #subPath == "" {
				subPath: "custom_apps"
			}
			if #subPath != "" {
				subPath: "\(#subPath)/custom_apps"
			}
		},
		{
			name:      "nextcloud-main"
			mountPath: "/var/www/tmp"
			#subPath:  #in.persistence.subPath
			if #subPath == "" {
				subPath: "tmp"
			}
			if #subPath != "" {
				subPath: "\(#subPath)/tmp"
			}
		},
		{
			name:      "nextcloud-main"
			mountPath: "/var/www/html/themes"
			#subPath:  #in.persistence.subPath
			if #subPath == "" {
				subPath: "themes"
			}
			if #subPath != "" {
				subPath: "\(#subPath)/themes"
			}
		},
		for k, _ in #in.nextcloud.configs {
			{name: "nextcloud-config", mountPath: "/var/www/html/config/\(k)", subPath: k}
		},
		for k, v in #in.nextcloud.defaultConfigs if v {
			{name: "nextcloud-config", mountPath: "/var/www/html/config/\(k)", subPath: k}
		},
		for k, _ in #in.nextcloud.phpConfigs {
			{
				name: "nextcloud-phpconfig"
				if #in.nginx.enabled {
					mountPath: "/usr/local/etc/php-fpm.d/\(k)"
				}
				if !#in.nginx.enabled {
					mountPath: "/usr/local/etc/php/conf.d/\(k)"
				}
				subPath: k
			}
		},
	]
}

// #NextcloudVolumes mirrors lines 351-399 of deployment.yaml
#NextcloudVolumes: {
	#in: #Config

	out: [...corev1.#Volume] & [
		{
			name: "nextcloud-main"
			if #in.persistence.enabled && #in.persistence.hostPath != "" {
				hostPath: {path: #in.persistence.hostPath, type: "Directory"}
			}
			if #in.persistence.enabled && #in.persistence.hostPath == "" && #in.persistence.existingClaim != "" {
				persistentVolumeClaim: claimName: #in.persistence.existingClaim
			}
			if #in.persistence.enabled && #in.persistence.hostPath == "" && #in.persistence.existingClaim == "" {
				persistentVolumeClaim: claimName: "\(#in.metadata.name)-nextcloud"
			}
			if !#in.persistence.enabled {
				emptyDir: {}
			}
		},
		if #in.persistence.enabled && #in.persistence.nextcloudData.enabled {
			{
				name: "nextcloud-data"
				if #in.persistence.nextcloudData.hostPath != "" {
					hostPath: {path: #in.persistence.nextcloudData.hostPath, type: "Directory"}
				}
				if #in.persistence.nextcloudData.hostPath == "" && #in.persistence.nextcloudData.existingClaim != "" {
					persistentVolumeClaim: claimName: #in.persistence.nextcloudData.existingClaim
				}
				if #in.persistence.nextcloudData.hostPath == "" && #in.persistence.nextcloudData.existingClaim == "" {
					persistentVolumeClaim: claimName: "\(#in.metadata.name)-nextcloud-data"
				}
			}
		},
		if len([for k, _ in #in.nextcloud.configs {k}]) > 0 || len([for k, v in #in.nextcloud.defaultConfigs if v {k}]) > 0 {
			{name: "nextcloud-config", configMap: name: "\(#in.metadata.name)-config"}
		},
		if len([for k, _ in #in.nextcloud.phpConfigs {k}]) > 0 {
			{name: "nextcloud-phpconfig", configMap: name: "\(#in.metadata.name)-phpconfig"}
		},
		if #in.nginx.enabled {
			{name: "nextcloud-nginx-config", configMap: name: "\(#in.metadata.name)-nginxconfig"}
		},
		if len([for k, v in #in.nextcloud.hooks if v != "" {k}]) > 0 {
			{
				name: "nextcloud-hooks"
				configMap: {name: "\(#in.metadata.name)-hooks", defaultMode: 0o755}
			}
		},
	]
}
