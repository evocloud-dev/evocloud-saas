package templates

import (
	"list"
	"strings"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#Deployment: appsv1.#Deployment & {
	#config: #Config

	_affinity: timoniv1.#Affinity & {
		#Values:      #config.affinity
		#MatchLabels: #config.selector.labels
	}

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "sonarqube"
	}
	metadata: {
		name: #config.fullname
		if #config.annotations != _|_ {
			annotations: #config.annotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: #config.replicaCount
		strategy: type: "Recreate"
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "sonarqube"
		}
		template: {
			metadata: {
				labels: #config.selector.labels & {
					"app.kubernetes.io/component": "sonarqube"
					if #config.podLabels != _|_ {
						#config.podLabels
					}
				}
				if #config.podAnnotations != _|_ {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				automountServiceAccountToken: #config.serviceAccount.automountServiceAccountToken
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}

				serviceAccountName: [
					if #config.serviceAccount.create {
						if #config.serviceAccount.name != "" {
							#config.serviceAccount.name
						}
						if #config.serviceAccount.name == "" {
							#config.fullname
						}
					},
					if !#config.serviceAccount.create {
						if #config.serviceAccount.name != "" {
							#config.serviceAccount.name
						}
						if #config.serviceAccount.name == "" {
							"default"
						}
					},
				][0]

				if #config.podSecurityContext != _|_ {
					securityContext: #config.podSecurityContext
				}

				terminationGracePeriodSeconds: #config.terminationGracePeriodSeconds

				let databaseMode = #config.databaseMode
				let hasWait = #config.waitForDatabase.enabled && databaseMode == "postgresql"
				let hasPlugins = #config.plugins.enabled || #config.communityBranchPlugin.enabled
				let _postgresqlPortString = "\(#config.postgresqlPort)"

				initContainers: list.Concat([
					[
						if hasWait {
							name:            "wait-for-database"
							image:           "\(#config.waitForDatabase.image.repository):\(#config.waitForDatabase.image.tag)"
							imagePullPolicy: #config.waitForDatabase.image.pullPolicy
							command: ["sh", "-ec"]
							args: [
								"""
								attempts=$(((\(#config.waitForDatabase.timeoutSeconds) + 1) / 2))
								attempt=0
								until nc -z "\(#config.postgresqlHost)" \(_postgresqlPortString); do
								  attempt=$((attempt + 1))
								  if [ "${attempt}" -ge "${attempts}" ]; then
								    echo "PostgreSQL did not become reachable before timeout" >&2
								    exit 1
								  fi
								  sleep 2
								done
								""",
							]
							if #config.securityContext != _|_ {
								securityContext: #config.securityContext
							}
							resources: #config.waitForDatabase.resources
						},
					],
					[
						if hasPlugins {
							name:            "install-plugins"
							image:           "\(#config.plugins.image.repository):\(#config.plugins.image.tag)"
							imagePullPolicy: #config.plugins.image.pullPolicy
							command: ["sh", "-ec"]
							let _installCmd = [
								"set -eu",
								"mkdir -p /extensions/plugins",
								for p in #config.plugins.install {
									"wget -O \"/extensions/plugins/\(p.name).jar\" \(p.url)"
								},
								if #config.communityBranchPlugin.enabled {
									"""
									rm -f /extensions/plugins/sonarqube-community-branch-plugin-*.jar
									branch_plugin="/extensions/plugins/\(#config.communityBranchJarName)"
									wget -O "${branch_plugin}" "\(#config.communityBranchJarUrl)"
									mkdir -p /web
									wget -O /tmp/sonarqube-webapp.zip "\(#config.communityBranchWebappUrl)"
									unzip -o /tmp/sonarqube-webapp.zip -d /web
									rm -f /tmp/sonarqube-webapp.zip
									chmod g=u "${branch_plugin}"
									find /web -mindepth 1 -exec chmod g=u {} +
									"""
								},
								if !#config.communityBranchPlugin.enabled {
									"rm -f /extensions/plugins/sonarqube-community-branch-plugin-*.jar"
								},
							]
							args: [strings.Join(_installCmd, "\n")]
							if #config.securityContext != _|_ {
								securityContext: #config.securityContext
							}
							resources: #config.plugins.resources
							volumeMounts: list.Concat([
								[
									{
										name:      "extensions"
										mountPath: "/extensions"
									},
								],
								[
									if #config.communityBranchPlugin.enabled {
										name:      "webapp"
										mountPath: "/web"
									}
								],
								[
									if #config.communityBranchPlugin.enabled {
										name:      "tmp"
										mountPath: "/tmp"
									}
								],
							])
						},
					],
					#config.extraInitContainers,
				])

				containers: list.Concat([
					[
						{
							name:            "sonarqube"
							image:           #config.image.reference
							imagePullPolicy: #config.image.pullPolicy
							if #config.securityContext != _|_ {
								securityContext: #config.securityContext
							}

							let _monitoringEnv = [
								if #config.sonarqube.monitoringPasscode != "" || #config.sonarqube.existingMonitoringPasscodeSecret != "" || #config.externalSecrets.monitoringPasscode.enabled {
									name: "SONAR_WEB_SYSTEMPASSCODE"
									valueFrom: secretKeyRef: {
										name: #config.monitoringSecretName
										key:  #config.monitoringSecretKey
									}
								},
							]

							let _dbEnv = [
								if databaseMode == "external" {
									name:  "SONAR_JDBC_URL"
									value: #config.database.external.jdbcUrl
								},
								if databaseMode == "external" {
									name:  "SONAR_JDBC_USERNAME"
									value: #config.database.external.username
								},
								if databaseMode == "external" {
									name: "SONAR_JDBC_PASSWORD"
									valueFrom: secretKeyRef: {
										name: #config.databaseSecretName
										key:  #config.databaseSecretKey
									}
								},
								if databaseMode == "postgresql" {
									name:  "SONAR_JDBC_URL"
									value: #config.postgresqlJdbcUrl
								},
								if databaseMode == "postgresql" {
									name:  "SONAR_JDBC_USERNAME"
									value: #config.postgresql.auth.username
								},
								if databaseMode == "postgresql" {
									name: "SONAR_JDBC_PASSWORD"
									valueFrom: secretKeyRef: {
										name: #config.databaseSecretName
										key:  #config.databaseSecretKey
									}
								},
							]

							env: list.Concat([
								[
									{
										name:  "SONAR_WEB_JAVAOPTS"
										value: #config.sonarqube.webJavaOpts
									},
									{
										name:  "SONAR_CE_JAVAOPTS"
										value: #config.sonarqube.ceJavaOpts
									},
									{
										name:  "SONAR_SEARCH_JAVAOPTS"
										value: #config.sonarqube.searchJavaOpts
									},
									{
										name:  "SONAR_WEB_PORT"
										value: "\( #config.containerPorts.http )"
									},
									{
										name:  "SONAR_ES_BOOTSTRAP_CHECKS_DISABLE"
										value: "\( #config.sonarqube.esBootstrapChecksDisable )"
									},
								],
								_dbEnv,
								_monitoringEnv,
								#config.sonarqube.extraEnv,
							])

							if len(#config.sonarqube.extraEnvFrom) > 0 {
								envFrom: #config.sonarqube.extraEnvFrom
							}

							ports: [
								{
									name:          "http"
									containerPort: #config.containerPorts.http
									protocol:      "TCP"
								},
							]

							if #config.startupProbe.enabled {
								startupProbe: {
									httpGet: {
										path: #config.startupProbePath
										port: "http"
									}
									initialDelaySeconds: #config.startupProbe.initialDelaySeconds
									periodSeconds:       #config.startupProbe.periodSeconds
									timeoutSeconds:      #config.startupProbe.timeoutSeconds
									failureThreshold:    #config.startupProbe.failureThreshold
								}
							}

							if #config.livenessProbe.enabled {
								livenessProbe: {
									httpGet: {
										path: #config.livenessProbePath
										port: "http"
									}
									initialDelaySeconds: #config.livenessProbe.initialDelaySeconds
									periodSeconds:       #config.livenessProbe.periodSeconds
									timeoutSeconds:      #config.livenessProbe.timeoutSeconds
									failureThreshold:    #config.livenessProbe.failureThreshold
								}
							}

							if #config.readinessProbe.enabled {
								readinessProbe: {
									exec: command: [
										"sh",
										"-ec",
										"curl -fsS \"http://127.0.0.1:${SONAR_WEB_PORT}\(#config.readinessProbePath)\" | grep -q '\"status\":\"UP\"'",
									]
									initialDelaySeconds: #config.readinessProbe.initialDelaySeconds
									periodSeconds:       #config.readinessProbe.periodSeconds
									timeoutSeconds:      #config.readinessProbe.timeoutSeconds
									failureThreshold:    #config.readinessProbe.failureThreshold
								}
							}

							resources: #config.resources

							volumeMounts: list.Concat([
								[
									{
										name:      "data"
										mountPath: "/opt/sonarqube/data"
									},
									{
										name:      "extensions"
										mountPath: "/opt/sonarqube/extensions"
									},
									{
										name:      "logs"
										mountPath: "/opt/sonarqube/logs"
									},
									{
										name:      "temp"
										mountPath: "/opt/sonarqube/temp"
									},
									{
										name:      "tmp"
										mountPath: "/tmp"
									},
									{
										name:      "config"
										mountPath: "/opt/sonarqube/conf/sonar.properties"
										subPath:   "sonar.properties"
										readOnly:  true
									},
								],
								[
									if #config.communityBranchPlugin.enabled {
										name:      "webapp"
										mountPath: "/opt/sonarqube/web"
									}
								],
								#config.extraVolumeMounts,
							])
						},
					],
					#config.extraContainers,
				])

				volumes: list.Concat([
					[
						{
							name: "data"
							if #config.persistence.data.enabled {
								if #config.persistence.data.existingClaim != "" {
									persistentVolumeClaim: claimName: #config.persistence.data.existingClaim
								}
								if #config.persistence.data.existingClaim == "" {
									persistentVolumeClaim: claimName: "\( #config.fullname )-data"
								}
							}
							if !#config.persistence.data.enabled {
								emptyDir: {}
							}
						},
						{
							name: "extensions"
							if #config.persistence.extensions.enabled {
								if #config.persistence.extensions.existingClaim != "" {
									persistentVolumeClaim: claimName: #config.persistence.extensions.existingClaim
								}
								if #config.persistence.extensions.existingClaim == "" {
									persistentVolumeClaim: claimName: "\( #config.fullname )-extensions"
								}
							}
							if !#config.persistence.extensions.enabled {
								emptyDir: {}
							}
						},
						{
							name: "logs"
							if #config.persistence.logs.enabled {
								if #config.persistence.logs.existingClaim != "" {
									persistentVolumeClaim: claimName: #config.persistence.logs.existingClaim
								}
								if #config.persistence.logs.existingClaim == "" {
									persistentVolumeClaim: claimName: "\( #config.fullname )-logs"
								}
							}
							if !#config.persistence.logs.enabled {
								emptyDir: {}
							}
						},
						{
							name: "temp"
							emptyDir: {}
						},
						{
							name: "tmp"
							emptyDir: {}
						},
						{
							name: "config"
							configMap: {
								name: "\( #config.fullname )-config"
								items: [
									{
										key:  "sonar.properties"
										path: "sonar.properties"
									},
								]
							}
						},
					],
					[
						if #config.communityBranchPlugin.enabled {
							name: "webapp"
							emptyDir: {}
						}
					],
					#config.extraVolumes,
				])

				if #config.nodeSelector != _|_ {
					nodeSelector: #config.nodeSelector
				}
				if _affinity.#Enabled {
					affinity: _affinity
				}
				if #config.tolerations != _|_ {
					tolerations: #config.tolerations
				}
				if #config.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: #config.topologySpreadConstraints
				}
				if #config.priorityClassName != "" {
					priorityClassName: #config.priorityClassName
				}
			}
		}
	}
}
