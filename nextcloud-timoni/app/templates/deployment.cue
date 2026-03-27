package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

// #Deployment is the literal CUE translation of charts/nextcloud/templates/deployment.yaml.
// Field ordering and conditional logic mirrors the Helm template line-by-line.
#Deployment: appsv1.#Deployment & {
	#in: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"

	// metadata — mirrors lines 4-14 of deployment.yaml
	metadata: #in.metadata & {
		labels: {
			"app.kubernetes.io/component": "app"
			if #in.deploymentLabels != _|_ {
				for k, v in #in.deploymentLabels {"\(k)": v}
			}
		}
		if #in.deploymentAnnotations != _|_ && len(#in.deploymentAnnotations) > 0 {
			annotations: #in.deploymentAnnotations
		}
	}

	spec: appsv1.#DeploymentSpec & {
		// {{- if not .Values.hpa.enabled }} replicas: {{ .Values.replicaCount }}
		if !#in.hpa.enabled {
			replicas: #in.replicas
		}

		selector: matchLabels: #in.selector.labels & {
			"app.kubernetes.io/component": "app"
		}

		template: {
			metadata: {
				labels: #in.metadata.labels & {
					"app.kubernetes.io/component": "app"
					if #in.podLabels != _|_ {
						for k, v in #in.podLabels {"\(k)": v}
					}
				}
				// annotations — mirrors line 34 onwards
				annotations: {
					if #in.podAnnotations != _|_ {
						for k, v in #in.podAnnotations {"\(k)": v}
					}
				}
			}

			spec: corev1.#PodSpec & {
				// {{- with .Values.image.pullSecrets }}
				if #in.imagePullSecrets != _|_ {
					imagePullSecrets: #in.imagePullSecrets
				}

				// {{- if .Values.rbac.enabled }}
				if #in.rbac.enabled {
					serviceAccountName: #in.rbac.serviceAccount.name
				}

				// Init containers — mirrors lines 287-337
				// {{- if or .Values.mariadb.enabled .Values.postgresql.enabled }}
				if #in.database.mariadb.enabled || #in.database.postgresql.enabled {
					initContainers: [
						if #in.database.mariadb.enabled {
							{
								name:  "mariadb-isalive"
								image: #in.database.mariadb.image
								env: [
									{
										name: "MYSQL_USER"
										valueFrom: secretKeyRef: {
											name: #in.dbSecretRef
											key:  #in.database.externalDatabase.existingSecret.usernameKey
										}
									},
									{
										name: "MYSQL_PASSWORD"
										valueFrom: secretKeyRef: {
											name: #in.dbSecretRef
											key:  #in.database.externalDatabase.existingSecret.passwordKey
										}
									},
								]
								command: [
									"sh", "-c",
									"until mysql --host=\(#in.database.mariadb.primaryHost) --user=${MYSQL_USER} --password=${MYSQL_PASSWORD} --execute=\"SELECT 1;\"; do echo waiting for mysql; sleep 2; done;",
								]
							}
						},
						if !#in.database.mariadb.enabled && #in.database.postgresql.enabled {
							{
								name:  "postgresql-isready"
								image: #in.database.postgresql.image
								env: [
									{
										name:  "POSTGRES_USER"
										value: #in.database.postgresql.auth.username
									},
									{
										name:  "POSTGRES_HOST"
										value: #in.database.postgresql.primaryHost
									},
								]
								command: [
									"sh", "-c",
									"until pg_isready -h ${POSTGRES_HOST} -U ${POSTGRES_USER} ; do sleep 2 ; done",
								]
							}
						},
					]
				}

				// Containers — mirrors line 51 onwards
				containers: [
					// ── MAIN NEXTCLOUD CONTAINER — mirrors lines 52-141 ─────────────────────
					{
						name:            "nextcloud"
						image:           #in.image.reference
						imagePullPolicy: #in.image.pullPolicy

						// {{- with .Values.lifecycle }}
						if #in.lifecycle != _|_ {
							lifecycle: #in.lifecycle
						}

						// {{- include "nextcloud.env" . }}
						_in: #in
						env: (#NextcloudEnv & {
							#in: _in
						}).out

						resources: #in.resources

						// {{- with .Values.nextcloud.securityContext }}
						if #in.securityContext != _|_ {
							securityContext: #in.securityContext
						}

						// {{- include "nextcloud.volumeMounts" . }}
						volumeMounts: (#NextcloudVolumeMounts & {#in: _in}).out

						// {{- if not .Values.nginx.enabled }}
						if !#in.nginx.enabled {
							ports: [
								{name: "http", containerPort: #in.nextcloud.containerPort, protocol: "TCP"},
							]
							if #in.livenessProbe.enabled {
								livenessProbe: corev1.#Probe & {
									httpGet: {
										path: "/status.php"
										port: #in.nextcloud.containerPort
										httpHeaders: [
											{name: "Host", value: "localhost"},
										]
									}
									initialDelaySeconds: #in.livenessProbe.initialDelaySeconds
									periodSeconds:       #in.livenessProbe.periodSeconds
									timeoutSeconds:      #in.livenessProbe.timeoutSeconds
									successThreshold:    #in.livenessProbe.successThreshold
									failureThreshold:    #in.livenessProbe.failureThreshold
								}
							}
							if #in.readinessProbe.enabled {
								readinessProbe: corev1.#Probe & {
									httpGet: {
										path: "/status.php"
										port: #in.nextcloud.containerPort
										httpHeaders: [
											{name: "Host", value: "localhost"},
										]
									}
									initialDelaySeconds: #in.readinessProbe.initialDelaySeconds
									periodSeconds:       #in.readinessProbe.periodSeconds
									timeoutSeconds:      #in.readinessProbe.timeoutSeconds
									successThreshold:    #in.readinessProbe.successThreshold
									failureThreshold:    #in.readinessProbe.failureThreshold
								}
							}
							if #in.startupProbe.enabled {
								startupProbe: corev1.#Probe & {
									httpGet: {
										path: "/status.php"
										port: #in.nextcloud.containerPort
										httpHeaders: [
											{name: "Host", value: "localhost"},
										]
									}
									initialDelaySeconds: #in.startupProbe.initialDelaySeconds
									periodSeconds:       #in.startupProbe.periodSeconds
									timeoutSeconds:      #in.startupProbe.timeoutSeconds
									successThreshold:    #in.startupProbe.successThreshold
									failureThreshold:    #in.startupProbe.failureThreshold
								}
							}
						}
					},

					// ── NGINX SIDECAR — mirrors lines 142-242 ─────────────────────────────
					// {{- if .Values.nginx.enabled }}
					if #in.nginx.enabled {
						{
							name:            "nextcloud-nginx"
							image:           #in.nginx.image
							imagePullPolicy: #in.nginx.imagePullPolicy
							ports: [
								{name: "http", protocol: "TCP", containerPort: #in.nextcloud.containerPort},
							]
							if #in.livenessProbe.enabled {
								livenessProbe: corev1.#Probe & {
									httpGet: {
										path: "/status.php"
										port: #in.nextcloud.containerPort
										httpHeaders: [
											{name: "Host", value: "localhost"},
										]
									}
									initialDelaySeconds: #in.livenessProbe.initialDelaySeconds
									periodSeconds:       #in.livenessProbe.periodSeconds
									timeoutSeconds:      #in.livenessProbe.timeoutSeconds
									successThreshold:    #in.livenessProbe.successThreshold
									failureThreshold:    #in.livenessProbe.failureThreshold
								}
							}
							if #in.readinessProbe.enabled {
								readinessProbe: corev1.#Probe & {
									httpGet: {
										path: "/status.php"
										port: #in.nextcloud.containerPort
										httpHeaders: [
											{name: "Host", value: "localhost"},
										]
									}
									initialDelaySeconds: #in.readinessProbe.initialDelaySeconds
									periodSeconds:       #in.readinessProbe.periodSeconds
									timeoutSeconds:      #in.readinessProbe.timeoutSeconds
									successThreshold:    #in.readinessProbe.successThreshold
									failureThreshold:    #in.readinessProbe.failureThreshold
								}
							}
							if #in.startupProbe.enabled {
								startupProbe: corev1.#Probe & {
									httpGet: {
										path: "/status.php"
										port: #in.nextcloud.containerPort
										httpHeaders: [
											{name: "Host", value: "localhost"},
										]
									}
									initialDelaySeconds: #in.startupProbe.initialDelaySeconds
									periodSeconds:       #in.startupProbe.periodSeconds
									timeoutSeconds:      #in.startupProbe.timeoutSeconds
									successThreshold:    #in.startupProbe.successThreshold
									failureThreshold:    #in.startupProbe.failureThreshold
								}
							}
							env: #in.nginx.extraEnv
							resources: #in.nginx.resources
							if #in.nginx.securityContext != _|_ {
								securityContext: #in.nginx.securityContext
							}
							volumeMounts: [
								{name: "nextcloud-main", mountPath: "/var/www/",             subPath: "root"},
								{name: "nextcloud-main", mountPath: "/var/www/html",         subPath: "html"},
								if #in.persistence.enabled && #in.persistence.nextcloudData.enabled {
									{name: "nextcloud-data", mountPath: #in.nextcloud.datadir, subPath: "data"}
								},
								if !#in.persistence.enabled || !#in.persistence.nextcloudData.enabled {
									{name: "nextcloud-main", mountPath: #in.nextcloud.datadir, subPath: "data"}
								},
								{name: "nextcloud-main",         mountPath: "/var/www/html/config",      subPath: "config"},
								{name: "nextcloud-main",         mountPath: "/var/www/html/custom_apps", subPath: "custom_apps"},
								{name: "nextcloud-main",         mountPath: "/var/www/tmp",              subPath: "tmp"},
								{name: "nextcloud-main",         mountPath: "/var/www/html/themes",      subPath: "themes"},
								{name: "nextcloud-nginx-config", mountPath: "/etc/nginx/conf.d/"},
							]
						}
					},

					// ── CRON SIDECAR — mirrors lines 243-276 ──────────────────────────────
					// {{- if and .Values.cronjob.enabled (eq .Values.cronjob.type "sidecar") }}
					if #in.cronjob.enabled && #in.cronjob.type == "sidecar" {
						{
							name:            "nextcloud-cron"
							image:           #in.image.reference
							imagePullPolicy: #in.image.pullPolicy
							command: ["/cron.sh"]
							_in: #in
							env:          (#NextcloudEnv & {#in: _in}).out
							volumeMounts: (#NextcloudVolumeMounts & {#in: _in}).out
						}
					},
				]

				// volumes — mirrors lines 351-399
				_in: #in
				volumes: (#NextcloudVolumes & {#in: _in}).out

				
// Pod security context — mirrors lines 400-414
				securityContext: corev1.#PodSecurityContext & {
					if #in.podSecurityContext != _|_ {
						#in.podSecurityContext
					}
					if #in.podSecurityContext == _|_ {
						if #in.nginx.enabled  {fsGroup: 82}
						if !#in.nginx.enabled {fsGroup: 33}
					}
				}

				// Scheduling — mirrors lines 280-286, 339-350
				if #in.nodeSelector != _|_ {
					nodeSelector: #in.nodeSelector
				}
				if #in.tolerations != _|_ {
					tolerations: #in.tolerations
				}
				if #in.affinity != _|_ {
					affinity: #in.affinity
				}
				if #in.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: #in.topologySpreadConstraints
				}
				if #in.priorityClassName != "" {
					priorityClassName: #in.priorityClassName
				}
				if #in.dnsConfig != _|_ {
					dnsConfig: #in.dnsConfig
				}
			}
		}
	}
}

