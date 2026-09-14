package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#NginxDeployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-nginx"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: appsv1.#DeploymentSpec & {
		replicas:             #config.workload.nginx.replicas
		revisionHistoryLimit: #config.workload.nginx.revisionHistoryLimit
		strategy: type:       "Recreate"
		selector: matchLabels: {
			"pod.name":                  "nginx"
			"app.kubernetes.io/name":     #config.metadata.name
			"app.kubernetes.io/instance": #config.metadata.name
		}
		template: {
			metadata: {
				labels: #config.metadata.labels & {
					"pod.name":           "nginx"
					"pod.lifecycle":      "permanent"
					"truecharts.org/pvc": "assets_modules_themes_uploads"
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           "default"
				automountServiceAccountToken: false
				if #config.runtimeClassName != _|_ && #config.runtimeClassName != "" {
					runtimeClassName:             #config.runtimeClassName
				}
				hostNetwork:                  false
				hostPID:                      false
				hostIPC:                      false
				shareProcessNamespace:        false
				enableServiceLinks:           false
				restartPolicy:                "Always"
				nodeSelector:                 #config.nodeSelector
				affinity: podAffinity: requiredDuringSchedulingIgnoredDuringExecution: [
					{
						topologyKey: "kubernetes.io/hostname"
						labelSelector: matchExpressions: [
							{
								key:      "truecharts.org/pvc"
								operator: "In"
								values: ["assets_modules_themes_uploads"]
							},
						]
					},
				]
				topologySpreadConstraints: [
					{
						maxSkew:           1
						whenUnsatisfiable: "ScheduleAnyway"
						topologyKey:       "kubernetes.io/hostname"
						labelSelector: matchLabels: {
							"pod.name":                   "nginx"
							"app.kubernetes.io/name":     #config.metadata.name
							"app.kubernetes.io/instance": #config.metadata.name
						}
						nodeAffinityPolicy: "Honor"
						nodeTaintsPolicy:   "Honor"
					},
				]
				dnsPolicy: "ClusterFirst"
				dnsConfig: options: [
					{
						name:  "ndots"
						value: "1"
					},
				]
				terminationGracePeriodSeconds: 60
				securityContext: {
					fsGroup:             #config.podSecurityContext.fsGroup
					fsGroupChangePolicy: #config.podSecurityContext.fsGroupChangePolicy
					supplementalGroups:  #config.podSecurityContext.supplementalGroups
					sysctls: [
						{
							name:  "net.ipv4.ip_unprivileged_port_start"
							value: "80"
						},
					]
				}
				hostUsers: true
				containers: [
					{
						name:            "humhub"
						image:           #config.nginxImage.repository + ":" + #config.nginxImage.tag
						imagePullPolicy: #config.nginxImage.pullPolicy
						tty:             false
						stdin:           false
						ports: [
							{
								name:          "main"
								containerPort: #config.service.main.ports.main.targetPort
								protocol:      "TCP"
							},
						]
						volumeMounts: [
							if #config.persistence.assets.enabled {
								{
									name:      "assets"
									mountPath: #config.persistence.assets.mountPath
									readOnly:  false
								}
							},
							{
								name:      "devshm"
								mountPath: "/dev/shm"
								readOnly:  false
							},
							if #config.persistence.modules.enabled {
								{
									name:      "modules"
									mountPath: #config.persistence.modules.mountPath
									readOnly:  false
								}
							},
							{
								name:      "shared"
								mountPath: "/shared"
								readOnly:  false
							},
							if #config.persistence.themes.enabled {
								{
									name:      "themes"
									mountPath: #config.persistence.themes.mountPath
									readOnly:  false
								}
							},
							{
								name:      "tmp"
								mountPath: "/tmp"
								readOnly:  false
							},
							if #config.persistence.uploads.enabled {
								{
									name:      "uploads"
									mountPath: #config.persistence.uploads.mountPath
									readOnly:  false
								}
							},
							{
								name:      "varlogs"
								mountPath: "/var/logs"
								readOnly:  false
							},
							{
								name:      "varrun"
								mountPath: "/var/run"
								readOnly:  false
							},
						]
						livenessProbe: {
							httpGet: {
								port:   #config.workload.nginx.podSpec.containers.nginx.probes.liveness.port
								path:   #config.workload.nginx.podSpec.containers.nginx.probes.liveness.path
								scheme: "HTTP"
							}
							initialDelaySeconds: 12
							failureThreshold:    5
							successThreshold:    1
							timeoutSeconds:      5
							periodSeconds:       15
						}
						readinessProbe: {
							httpGet: {
								port:   #config.workload.nginx.podSpec.containers.nginx.probes.readiness.port
								path:   #config.workload.nginx.podSpec.containers.nginx.probes.readiness.path
								scheme: "HTTP"
							}
							initialDelaySeconds: 10
							failureThreshold:    4
							successThreshold:    2
							timeoutSeconds:      5
							periodSeconds:       12
						}
						startupProbe: {
							tcpSocket: port: #config.workload.nginx.podSpec.containers.nginx.probes.startup.port
							initialDelaySeconds: 10
							failureThreshold:    60
							successThreshold:    1
							timeoutSeconds:      3
							periodSeconds:       5
						}
						resources: #config.resources
						securityContext: {
							runAsNonRoot:             #config.securityContext.container.runAsNonRoot
							runAsUser:                #config.securityContext.container.runAsUser
							runAsGroup:               #config.securityContext.container.runAsGroup
							readOnlyRootFilesystem:   #config.securityContext.container.readOnlyRootFilesystem
							allowPrivilegeEscalation: #config.securityContext.container.allowPrivilegeEscalation
							privileged:               #config.securityContext.container.privileged
							seccompProfile: type: "RuntimeDefault"
							capabilities: {
								add:  #config.nginxCapabilities.add
								drop: #config.nginxCapabilities.drop
							}
						}
						env: [
							{name: "TZ", value: #config.envDefaults.tz},
							{name: "UMASK", value: #config.envDefaults.umask},
							{name: "UMASK_SET", value: #config.envDefaults.umask},
							{name: "NVIDIA_VISIBLE_DEVICES", value: #config.envDefaults.nvidiaVisibleDevices},
							{name: "PUID", value: #config.envDefaults.puid},
							{name: "USER_ID", value: #config.envDefaults.puid},
							{name: "UID", value: #config.envDefaults.puid},
							{name: "PGID", value: #config.envDefaults.pgid},
							{name: "GROUP_ID", value: #config.envDefaults.pgid},
							{name: "GID", value: #config.envDefaults.pgid},
							{name: "HUMHUB_REVERSEPROXY_WHITELIST", value: #config.humhub.nginx.whitelist},
							{name: "NGINX_CLIENT_MAX_BODY_SIZE", value: #config.humhub.nginx.max_client_body_size},
							{name: "NGINX_KEEPALIVE_TIMEOUT", value: "\(#config.humhub.nginx.keep_alive_timeout)"},
							{name: "NGINX_UPSTREAM", value: "\(#config.metadata.name)-backend:\(#config.service.backend.ports.backend.port)"},
						]
					},
				]
				initContainers: [
					{
						name:            "\(#config.metadata.name)-system-mariadb-wait"
						image:           #config.mariadb.waitImage.repository + ":" + #config.mariadb.waitImage.tag
						imagePullPolicy: #config.mariadb.waitImage.pullPolicy
						tty:             false
						stdin:           false
						command: [
							"/bin/sh",
							"-c",
							#"""
							/bin/bash <<'EOF'
							echo "Executing DB waits..."
							until
							  mysqladmin -uroot -h"${MARIADB_HOST}" -p"${MARIADB_ROOT_PASSWORD}" ping \
							  && mysqladmin -uroot -h"${MARIADB_HOST}" -p"${MARIADB_ROOT_PASSWORD}" status;
							  do sleep 2;
							done
							EOF
							"""#,
						]
						volumeMounts: [
							{name: "devshm", mountPath: "/dev/shm", readOnly: false},
							{name: "shared", mountPath: "/shared", readOnly: false},
							{name: "tmp", mountPath: "/tmp", readOnly: false},
							{name: "varlogs", mountPath: "/var/logs", readOnly: false},
							{name: "varrun", mountPath: "/var/run", readOnly: false},
						]
						resources: #config.initResources
						securityContext: {
							runAsNonRoot:             #config.initSecurityContext.runAsNonRoot
							runAsUser:                #config.initSecurityContext.runAsUser
							runAsGroup:               #config.initSecurityContext.runAsGroup
							readOnlyRootFilesystem:   #config.initSecurityContext.readOnlyRootFilesystem
							allowPrivilegeEscalation: #config.initSecurityContext.allowPrivilegeEscalation
							privileged:               #config.initSecurityContext.privileged
							seccompProfile: type: "RuntimeDefault"
							capabilities: {
								add: ["NET_BIND_SERVICE"]
								drop: ["ALL"]
							}
						}
						env: [
							{name: "TZ", value: #config.envDefaults.tz},
							{name: "UMASK", value: #config.envDefaults.umask},
							{name: "UMASK_SET", value: #config.envDefaults.umask},
							{name: "NVIDIA_VISIBLE_DEVICES", value: #config.envDefaults.nvidiaVisibleDevices},
							{name: "S6_READ_ONLY_ROOT", value: "1"},
							{
								name: "MARIADB_HOST"
								valueFrom: secretKeyRef: {
									name: #config.mariadb.credsSecretName
									key:  "plainhost"
								}
							},
							{name: "MARIADB_ROOT_PASSWORD", value: #config.mariadb.rootPassword},
						]
					},
					{
						name:            "\(#config.metadata.name)-system-redis-wait"
						image:           #config.redis.waitImage.repository + ":" + #config.redis.waitImage.tag
						imagePullPolicy: #config.redis.waitImage.pullPolicy
						tty:             false
						stdin:           false
						command: [
							"/bin/sh",
							"-c",
							#"""
							/bin/bash <<'EOF'
							echo "Executing DB waits..."
							[[ -n "$REDIS_PASSWORD" ]] && export REDISCLI_AUTH="$REDIS_PASSWORD";
							export LIVE=false;
							until "$LIVE";
							do
							  response=$(
							      timeout -s 3 2 \
							      valkey-cli \
							        -h "$REDIS_HOST" \
							        -p "$REDIS_PORT" \
							        ping
							    )
							  if [ "$response" == "PONG" ] || [ "$response" == "LOADING Redis is loading the dataset in memory" ]; then
							    LIVE=true
							    echo "$response"
							    echo "Redis Responded, ending initcontainer and starting main container(s)..."
							  else
							    echo "$response"
							    echo "Redis not responding... Sleeping for 10 sec..."
							    sleep 10
							  fi;
							done
							EOF
							"""#,
						]
						volumeMounts: [
							{name: "devshm", mountPath: "/dev/shm", readOnly: false},
							{name: "shared", mountPath: "/shared", readOnly: false},
							{name: "tmp", mountPath: "/tmp", readOnly: false},
							{name: "varlogs", mountPath: "/var/logs", readOnly: false},
							{name: "varrun", mountPath: "/var/run", readOnly: false},
						]
						resources: #config.initResources
						securityContext: {
							runAsNonRoot:             #config.initSecurityContext.runAsNonRoot
							runAsUser:                #config.initSecurityContext.runAsUser
							runAsGroup:               #config.initSecurityContext.runAsGroup
							readOnlyRootFilesystem:   #config.initSecurityContext.readOnlyRootFilesystem
							allowPrivilegeEscalation: #config.initSecurityContext.allowPrivilegeEscalation
							privileged:               #config.initSecurityContext.privileged
							seccompProfile: type: "RuntimeDefault"
							capabilities: {
								add: ["NET_BIND_SERVICE"]
								drop: ["ALL"]
							}
						}
						env: [
							{name: "TZ", value: #config.envDefaults.tz},
							{name: "UMASK", value: #config.envDefaults.umask},
							{name: "UMASK_SET", value: #config.envDefaults.umask},
							{name: "NVIDIA_VISIBLE_DEVICES", value: #config.envDefaults.nvidiaVisibleDevices},
							{name: "S6_READ_ONLY_ROOT", value: "1"},
							{
								name: "REDIS_HOST"
								valueFrom: secretKeyRef: {
									name: #config.redis.credsSecretName
									key:  "plainhost"
								}
							},
							{name: "REDIS_PASSWORD", value: #config.redis.password},
							{name: "REDIS_PORT", value: "\(#config.redis.port)"},
						]
					},
				]
				volumes: [
					{
						name: "devshm"
						emptyDir: {
							medium:    "Memory"
							sizeLimit: #config.emptyDirMemoryLimit
						}
					},
					{
						name:     "shared"
						emptyDir: {}
					},
					{
						name: "tmp"
						emptyDir: {
							medium:    "Memory"
							sizeLimit: #config.emptyDirMemoryLimit
						}
					},
					{
						name: "varlogs"
						emptyDir: {
							medium:    "Memory"
							sizeLimit: #config.emptyDirMemoryLimit
						}
					},
					{
						name: "varrun"
						emptyDir: {
							medium:    "Memory"
							sizeLimit: #config.emptyDirMemoryLimit
						}
					},
					if #config.persistence.assets.enabled {
						{
							name: "assets"
							persistentVolumeClaim: claimName: #config.persistence.assets.name
						}
					},
					if #config.persistence.modules.enabled {
						{
							name: "modules"
							persistentVolumeClaim: claimName: #config.persistence.modules.name
						}
					},
					if #config.persistence.themes.enabled {
						{
							name: "themes"
							persistentVolumeClaim: claimName: #config.persistence.themes.name
						}
					},
					if #config.persistence.uploads.enabled {
						{
							name: "uploads"
							persistentVolumeClaim: claimName: #config.persistence.uploads.name
						}
					},
				]
			}
		}
	}
}
