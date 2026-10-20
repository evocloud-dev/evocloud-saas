package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#Deployment: appsv1.#Deployment & {
	#config: #Config

	// The affinity rules generated from the affinity values;
	// the anti-affinity presets match the instance selector labels.
	_affinity: timoniv1.#Affinity & {
		#Values:      #config.affinity
		#MatchLabels: #config.selector.labels
	}

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata:   #config.metadata
	spec: appsv1.#DeploymentSpec & {
		replicas:             #config.replicas
		revisionHistoryLimit: 3
		strategy: {
			type: "Recreate"
		}
		selector: matchLabels: #config.selector.labels
		template: {
			metadata: {
				labels: #config.metadata.labels & #config.selector.labels & {
					"pod.lifecycle":      "permanent"
					"pod.name":           "main"
					"truecharts.org/pvc": "config_data"
				}
				if #config.podAnnotations != _|_ {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           "default"
				automountServiceAccountToken: false
				hostNetwork:                  false
				hostPID:                      false
				hostIPC:                      false
				shareProcessNamespace:        false
				enableServiceLinks:           false
				restartPolicy:                "Always"
				nodeSelector:                 #config.nodeSelector
				if #config.affinity.podAffinity != _|_ || #config.affinity.nodeAffinity != _|_ {
					affinity: _affinity
				}
				if #config.affinity.podAffinity == _|_ && #config.affinity.nodeAffinity == _|_ {
					affinity: {
						podAffinity: {
							requiredDuringSchedulingIgnoredDuringExecution: [
								{
									topologyKey: "kubernetes.io/hostname"
									labelSelector: {
										matchExpressions: [
											{
												key:      "truecharts.org/pvc"
												operator: "In"
												values: [
													"config_data",
												]
											},
										]
									}
								},
							]
						}
					}
				}
				if #config.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: #config.topologySpreadConstraints
				}
				if #config.topologySpreadConstraints == _|_ {
					topologySpreadConstraints: [
						{
							maxSkew:           1
							whenUnsatisfiable: "ScheduleAnyway"
							topologyKey:       "kubernetes.io/hostname"
							labelSelector: {
								matchLabels: #config.selector.labels
							}
							nodeAffinityPolicy: "Honor"
							nodeTaintsPolicy:   "Honor"
						},
					]
				}
				dnsPolicy: "ClusterFirst"
				dnsConfig: {
					options: [
						{
							name:  "ndots"
							value: "1"
						},
					]
				}
				terminationGracePeriodSeconds: 60
				securityContext:               #config.securityContext.pod
				hostUsers:                     true
				containers: [
					{
						name:            #config.metadata.name
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
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
							if #config.persistence.config.enabled {
								{
									name:      "config"
									mountPath: #config.persistence.config.mountPath
									readOnly:  false
								}
							},
							if #config.persistence.data.enabled {
								{
									name:      "data"
									mountPath: #config.persistence.data.mountPath
									readOnly:  false
								}
							},
							{
								name:      "devshm"
								mountPath: "/dev/shm"
								readOnly:  false
							},
							{
								name:      "shared"
								mountPath: "/shared"
								readOnly:  false
							},
							{
								name:      "tmp"
								mountPath: "/tmp"
								readOnly:  false
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
								port:   #config.service.main.ports.main.targetPort
								path:   "/"
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
								port:   #config.service.main.ports.main.targetPort
								path:   "/"
								scheme: "HTTP"
							}
							initialDelaySeconds: 10
							failureThreshold:    4
							successThreshold:    2
							timeoutSeconds:      5
							periodSeconds:       12
						}
						startupProbe: {
							httpGet: {
								port:   #config.service.main.ports.main.targetPort
								path:   "/"
								scheme: "HTTP"
							}
							initialDelaySeconds: 10
							failureThreshold:    60
							successThreshold:    1
							timeoutSeconds:      3
							periodSeconds:       5
						}
						resources:       #config.resources
						securityContext: #config.securityContext.container
						env: [
							{
								name:  "TZ"
								value: #config.semaphore.tz
							},
							{
								name:  "UMASK"
								value: #config.semaphore.umask
							},
							{
								name:  "UMASK_SET"
								value: #config.semaphore.umask
							},
							{
								name:  "NVIDIA_VISIBLE_DEVICES"
								value: "void"
							},
							{
								name:  "PUID"
								value: #config.semaphore.puid
							},
							{
								name:  "USER_ID"
								value: #config.semaphore.puid
							},
							{
								name:  "UID"
								value: #config.semaphore.puid
							},
							{
								name:  "PGID"
								value: #config.semaphore.pgid
							},
							{
								name:  "GROUP_ID"
								value: #config.semaphore.pgid
							},
							{
								name:  "GID"
								value: #config.semaphore.pgid
							},
							{
								name: "SEMAPHORE_ACCESS_KEY_ENCRYPTION"
								valueFrom: {
									secretKeyRef: {
										key:  #config.workload.main.podSpec.containers.main.env.SEMAPHORE_ACCESS_KEY_ENCRYPTION.secretKeyRef.key
										name: "\(#config.metadata.name)-\(#config.workload.main.podSpec.containers.main.env.SEMAPHORE_ACCESS_KEY_ENCRYPTION.secretKeyRef.name)"
									}
								}
							},
							{
								name:  "SEMAPHORE_ADMIN"
								value: #config.workload.main.podSpec.containers.main.env.SEMAPHORE_ADMIN
							},
							{
								name:  "SEMAPHORE_ADMIN_EMAIL"
								value: #config.workload.main.podSpec.containers.main.env.SEMAPHORE_ADMIN_EMAIL
							},
							{
								name:  "SEMAPHORE_ADMIN_NAME"
								value: #config.workload.main.podSpec.containers.main.env.SEMAPHORE_ADMIN_NAME
							},
							{
								name:  "SEMAPHORE_ADMIN_PASSWORD"
								value: #config.workload.main.podSpec.containers.main.env.SEMAPHORE_ADMIN_PASSWORD
							},
							{
								name:  "SEMAPHORE_DB"
								value: #config.workload.main.podSpec.containers.main.env.SEMAPHORE_DB
							},
							{
								name:  "SEMAPHORE_DB_DIALECT"
								value: #config.workload.main.podSpec.containers.main.env.SEMAPHORE_DB_DIALECT
							},
							{
								name: "SEMAPHORE_DB_HOST"
								valueFrom: {
									secretKeyRef: {
										key:  #config.workload.main.podSpec.containers.main.env.SEMAPHORE_DB_HOST.secretKeyRef.key
										name: "\(#config.metadata.name)-\(#config.workload.main.podSpec.containers.main.env.SEMAPHORE_DB_HOST.secretKeyRef.name)"
									}
								}
							},
							{
								name: "SEMAPHORE_DB_PASS"
								valueFrom: {
									secretKeyRef: {
										key:  #config.workload.main.podSpec.containers.main.env.SEMAPHORE_DB_PASS.secretKeyRef.key
										name: "\(#config.metadata.name)-\(#config.workload.main.podSpec.containers.main.env.SEMAPHORE_DB_PASS.secretKeyRef.name)"
									}
								}
							},
							{
								name:  "SEMAPHORE_DB_PORT"
								value: "\(#config.workload.main.podSpec.containers.main.env.SEMAPHORE_DB_PORT)"
							},
							{
								name:  "SEMAPHORE_DB_USER"
								value: #config.workload.main.podSpec.containers.main.env.SEMAPHORE_DB_USER
							},
							{
								name:  "SEMAPHORE_LDAP_ACTIVATED"
								value: #config.workload.main.podSpec.containers.main.env.SEMAPHORE_LDAP_ACTIVATED
							},
							{
								name:  "SEMAPHORE_LDAP_NEEDTLS"
								value: #config.workload.main.podSpec.containers.main.env.SEMAPHORE_LDAP_NEEDTLS
							},
							{
								name:  "SEMAPHORE_PLAYBOOK_PATH"
								value: #config.workload.main.podSpec.containers.main.env.SEMAPHORE_PLAYBOOK_PATH
							},
						]
					},
				]
				if #config.cnpg.main.enabled {
					initContainers: [
						{
							name:            "\(#config.metadata.name)-system-cnpg-wait"
							image:           #config.cnpg.main.waitImage.reference
							imagePullPolicy: #config.cnpg.main.waitImage.pullPolicy
							tty:             false
							stdin:           false
							command: [
								"/bin/sh",
								"-c",
								"/bin/sh <<'EOF'\necho \"Executing DB waits...\"\necho \"Testing Database availability on [CNPG RW]\"\nuntil\n  echo \"Testing database on url: [\(#config.metadata.name)-cnpg-main-rw]\"\n  pg_isready -U \(#config.cnpg.main.user) -d \(#config.cnpg.main.database) -h \(#config.metadata.name)-cnpg-main-rw\n  do sleep 5\ndone\necho \"Database available on url: [\(#config.metadata.name)-cnpg-main-rw]\"\necho \"Done executing DB waits...\"\nEOF",
							]
							volumeMounts: [
								{
									name:      "devshm"
									mountPath: "/dev/shm"
									readOnly:  false
								},
								{
									name:      "shared"
									mountPath: "/shared"
									readOnly:  false
								},
								{
									name:      "tmp"
									mountPath: "/tmp"
									readOnly:  false
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
							resources:       #config.cnpg.main.waitResources
							securityContext: #config.securityContext.initContainer
							env: [
								{
									name:  "TZ"
									value: #config.semaphore.tz
								},
								{
									name:  "UMASK"
									value: #config.semaphore.umask
								},
								{
									name:  "UMASK_SET"
									value: #config.semaphore.umask
								},
								{
									name:  "NVIDIA_VISIBLE_DEVICES"
									value: "void"
								},
								{
									name:  "S6_READ_ONLY_ROOT"
									value: "1"
								},
							]
						},
					]
				}
				volumes: [
					{
						name: "devshm"
						emptyDir: {
							medium:    "Memory"
							sizeLimit: "2400Mi"
						}
					},
					{
						name: "shared"
						emptyDir: {}
					},
					{
						name: "tmp"
						emptyDir: {
							medium:    "Memory"
							sizeLimit: "2400Mi"
						}
					},
					{
						name: "varlogs"
						emptyDir: {
							medium:    "Memory"
							sizeLimit: "2400Mi"
						}
					},
					{
						name: "varrun"
						emptyDir: {
							medium:    "Memory"
							sizeLimit: "2400Mi"
						}
					},
					if #config.persistence.config.enabled {
						{
							name: "config"
							persistentVolumeClaim: {
								claimName: "\(#config.metadata.name)-config"
							}
						}
					},
					if #config.persistence.data.enabled {
						{
							name: "data"
							persistentVolumeClaim: {
								claimName: "\(#config.metadata.name)-data"
							}
						}
					},
				]
				if #config.tolerations != _|_ {
					tolerations: #config.tolerations
				}
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
			}
		}
	}
}
