package templates

import (
	"list"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#Deployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata:   #config.metadata
	spec: appsv1.#DeploymentSpec & {
		replicas: #config.replicaCount
		selector: matchLabels: #config.selector.labels
		template: {
			metadata: {
				labels: #config.selector.labels
				if #config.podAnnotations != _|_ {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:            #config.metadata.name
				automountServiceAccountToken:  #config.serviceAccount.automountServiceAccountToken
				terminationGracePeriodSeconds: #config.terminationGracePeriodSeconds
				initContainers: list.Concat([
					[
						if #config.database.waitForConnection.enabled {
							name:    "wait-for-db"
							image:   "docker.io/library/busybox:1.37"
							command: ["sh", "-ec", "until nc -z -w2 \"${DB_HOST}\" \"${DB_PORT}\"; do echo \"waiting for database ${DB_HOST}:${DB_PORT}\"; sleep 2; done"]
							env: [
								{
									name:  "DB_HOST"
									value: _dbHost
								},
								{
									name:  "DB_PORT"
									value: "\(_dbPort)"
								},
							]
						},
					],
					#config.extraInitContainers,
				])
				containers: list.Concat([
					[
						{
							name:            #config.metadata.name
							image:           #config.image.reference
							imagePullPolicy: #config.image.pullPolicy
							ports: [
								{
									name:          "http"
									containerPort: #config.apache.port
									protocol:      "TCP"
								},
							]
							env: list.Concat([
								[
									{
										name:  "MATOMO_DATABASE_HOST"
										value: _dbHost
									},
									{
										name:  "MATOMO_DATABASE_PORT"
										value: "\(_dbPort)"
									},
									{
										name:  "MATOMO_DATABASE_NAME"
										value: _dbName
									},
									{
										name:  "MATOMO_DATABASE_USER"
										value: _dbUser
									},
									{
										name:  "MATOMO_DATABASE_PASSWORD"
										value: _dbPassword
									},
								],
								#config.matomo.extraEnv,
							])
							if #config.matomo.extraEnvFrom != _|_ {
								envFrom: #config.matomo.extraEnvFrom
							}
							livenessProbe: {
								httpGet: {
									path: "/matomo.php"
									port: "http"
								}
							}
							readinessProbe: {
								httpGet: {
									path: "/matomo.php"
									port: "http"
								}
							}
							if #config.startupProbe.enabled {
								startupProbe: {
									httpGet: {
										path: #config.startupProbe.path
										port: "http"
									}
									initialDelaySeconds: #config.startupProbe.initialDelaySeconds
									periodSeconds:       #config.startupProbe.periodSeconds
									timeoutSeconds:      #config.startupProbe.timeoutSeconds
									failureThreshold:    #config.startupProbe.failureThreshold
								}
							}
							volumeMounts: list.Concat([
								[
									{
										mountPath: "/var/www/html"
										name:      "matomo-data"
									},
									if #config.php.ini != _|_ {
										{
											mountPath: "/usr/local/etc/php/conf.d/custom.ini"
											name:      "php-config"
											subPath:   "custom.ini"
										}
									},
									{
										mountPath: "/etc/apache2/ports.conf"
										name:      "php-config"
										subPath:   "ports.conf"
										readOnly:  true
									},
									{
										mountPath: "/etc/apache2/sites-available/000-default.conf"
										name:      "php-config"
										subPath:   "000-default.conf"
										readOnly:  true
									},
								],
								#config.extraVolumeMounts,
							])
							resources: #config.resources
							if #config.securityContext != _|_ {
								securityContext: #config.securityContext
							}
						},
					],
					#config.extraContainers,
				])
				volumes: list.Concat([
					[
						{
							name: "matomo-data"
							persistentVolumeClaim: claimName: #config.metadata.name
						},
						if #config.php.ini != _|_ {
							{
								name: "php-config"
								configMap: name: "\(#config.metadata.name)-php-config"
							}
						},
					],
					#config.extraVolumes,
				])
				if #config.podSecurityContext != _|_ {
					securityContext: #config.podSecurityContext
				}
				if #config.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: #config.topologySpreadConstraints
				}
				if #config.affinity != _|_ {
					affinity: #config.affinity
				}
				if #config.tolerations != _|_ {
					tolerations: #config.tolerations
				}
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
			}
		}
	}

	_dbHost: [
		if #config.database.external.host != "" { #config.database.external.host },
		#config.metadata.name + "-mysql",
	][0]

	_dbPort: [
		if #config.database.external.port != 0 { #config.database.external.port },
		3306,
	][0]

	_dbName: [
		if #config.database.external.name != "" { #config.database.external.name },
		#config.mysql.auth.database,
	][0]

	_dbUser: [
		if #config.database.external.username != "" { #config.database.external.username },
		#config.mysql.auth.username,
	][0]

	_dbPassword: [
		if #config.database.external.password != "" { #config.database.external.password },
		#config.mysql.auth.password,
	][0]
}
