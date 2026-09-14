package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#MariaDBPassinit: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      #config.mariadb.passinitConfigMapName
		namespace: #config.metadata.namespace
		labels:    #config.mariadb.labels
	}
	data: {
		"passinit.sql": """
			ALTER USER root@'%' IDENTIFIED VIA mysql_native_password USING PASSWORD("\(#config.mariadb.rootPassword)");
			ALTER USER \(#config.mariadb.mariadbUsername)@'%' IDENTIFIED VIA mysql_native_password USING PASSWORD("\(#config.mariadb.password)");
			FLUSH PRIVILEGES;
			"""
	}
}

#MariaDBDeployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      #config.mariadb.serviceName
		namespace: #config.metadata.namespace
		labels:    #config.mariadb.labels
	}
	spec: appsv1.#DeploymentSpec & {
		replicas:             #config.mariadb.replicas
		revisionHistoryLimit: #config.mariadb.revisionHistoryLimit
		strategy: type:       #config.mariadb.strategyType
		selector: matchLabels: {
			"pod.name":                  "main"
			"app.kubernetes.io/name":     "mariadb"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		template: {
			metadata: {
				labels: #config.mariadb.labels & {
					"pod.lifecycle":              "permanent"
					"pod.name":                   "main"
					"truecharts.org/pvc":         "data"
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:            "default"
				automountServiceAccountToken:  false
				if #config.runtimeClassName != _|_ && #config.runtimeClassName != "" {
					runtimeClassName:              #config.runtimeClassName
				}
				enableServiceLinks:            false
				hostNetwork:                   false
				hostPID:                       false
				hostIPC:                       false
				shareProcessNamespace:         false
				restartPolicy:                 "Always"
				nodeSelector:                  #config.nodeSelector
				affinity: podAffinity: requiredDuringSchedulingIgnoredDuringExecution: [
					{
						topologyKey: "kubernetes.io/hostname"
						labelSelector: matchExpressions: [
							{
								key:      "truecharts.org/pvc"
								operator: "In"
								values: ["data"]
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
							"pod.name":                   "main"
							"app.kubernetes.io/name":     "mariadb"
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
				terminationGracePeriodSeconds: #config.mariadb.terminationGracePeriodSeconds
				securityContext: {
					fsGroup:             #config.mariadb.securityContext.fsGroup
					fsGroupChangePolicy: #config.mariadb.securityContext.fsGroupChangePolicy
					supplementalGroups: [#config.mariadb.securityContext.fsGroup]
					sysctls: []
				}
				hostUsers: true
				containers: [
					{
						name:            "\(#config.metadata.name)-mariadb"
						image:           #config.mariadb.image.repository + ":" + #config.mariadb.image.tag
						imagePullPolicy: #config.mariadb.image.pullPolicy
						tty:             false
						stdin:           false
						ports: [
							{
								name:          "main"
								containerPort: #config.mariadb.port
								protocol:      "TCP"
							},
						]
						volumeMounts: [
							if #config.mariadb.persistence.enabled {
								{
									name:      "data"
									mountPath: "/bitnami/mariadb"
									readOnly:  false
								}
							},
							{
								name:      "devshm"
								mountPath: "/dev/shm"
								readOnly:  false
							},
							{
								name:      "passinit"
								mountPath: "/init/passinit.sql"
								subPath:   "passinit.sql"
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
							exec: command:       #config.mariadb.probes.liveness.command
							initialDelaySeconds: #config.mariadb.probes.liveness.initialDelaySeconds
							failureThreshold:    #config.mariadb.probes.liveness.failureThreshold
							successThreshold:    #config.mariadb.probes.liveness.successThreshold
							timeoutSeconds:      #config.mariadb.probes.liveness.timeoutSeconds
							periodSeconds:       #config.mariadb.probes.liveness.periodSeconds
						}
						readinessProbe: {
							exec: command:       #config.mariadb.probes.readiness.command
							initialDelaySeconds: #config.mariadb.probes.readiness.initialDelaySeconds
							failureThreshold:    #config.mariadb.probes.readiness.failureThreshold
							successThreshold:    #config.mariadb.probes.readiness.successThreshold
							timeoutSeconds:      #config.mariadb.probes.readiness.timeoutSeconds
							periodSeconds:       #config.mariadb.probes.readiness.periodSeconds
						}
						startupProbe: {
							exec: command:       #config.mariadb.probes.startup.command
							initialDelaySeconds: #config.mariadb.probes.startup.initialDelaySeconds
							failureThreshold:    #config.mariadb.probes.startup.failureThreshold
							successThreshold:    #config.mariadb.probes.startup.successThreshold
							timeoutSeconds:      #config.mariadb.probes.startup.timeoutSeconds
							periodSeconds:       #config.mariadb.probes.startup.periodSeconds
						}
						resources: {
							requests: {
								cpu:    #config.mariadb.resources.requests.cpu
								memory: #config.mariadb.resources.requests.memory
							}
							limits: {
								cpu:    #config.mariadb.resources.limits.cpu
								memory: #config.mariadb.resources.limits.memory
							}
						}
						securityContext: {
							runAsNonRoot:             #config.mariadb.securityContext.container.runAsNonRoot
							runAsUser:                #config.mariadb.securityContext.container.runAsUser
							runAsGroup:               #config.mariadb.securityContext.container.runAsGroup
							readOnlyRootFilesystem:   #config.mariadb.securityContext.container.readOnlyRootFilesystem
							allowPrivilegeEscalation: #config.mariadb.securityContext.container.allowPrivilegeEscalation
							privileged:               #config.mariadb.securityContext.container.privileged
							seccompProfile: type: "RuntimeDefault"
							capabilities: {
								add:  #config.mariadb.securityContext.capabilities.add
								drop: #config.mariadb.securityContext.capabilities.drop
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
							{name: "MARIADB_DATABASE", value: #config.mariadb.mariadbDatabase},
							{name: "MARIADB_EXTRA_FLAGS", value: "--init-file=/init/passinit.sql"},
							{name: "MARIADB_PASSWORD", value: #config.mariadb.password},
							{name: "MARIADB_ROOT_PASSWORD", value: #config.mariadb.rootPassword},
							{name: "MARIADB_USER", value: #config.mariadb.mariadbUsername},
						]
					},
				]
				volumes: [
					{
						name: "passinit"
						configMap: {
							name:     #config.mariadb.passinitConfigMapName
							optional: false
							items: [{
								key:  "passinit.sql"
								path: "passinit.sql"
							}]
						}
					},
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
					{
						name: "data"
						persistentVolumeClaim: claimName: #config.mariadb.dataPvcName
					},
				]
			}
		}
	}
}

#MariaDBService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #config.mariadb.serviceName
		namespace: #config.metadata.namespace
		labels:    #config.mariadb.labels & {
			"service.name": "main"
		}
	}
	spec: corev1.#ServiceSpec & {
		type:                     corev1.#ServiceTypeClusterIP
		publishNotReadyAddresses: false
		ports: [
			{
				port:       #config.mariadb.port
				protocol:   "TCP"
				name:       "main"
				targetPort: #config.mariadb.port
			},
		]
		selector: {
			"pod.name":                  "main"
			"app.kubernetes.io/name":     "mariadb"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
}

#MariaDBPVC: corev1.#PersistentVolumeClaim & {
	#config: #Config

	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      #config.mariadb.dataPvcName
		namespace: #config.metadata.namespace
		labels:    #config.mariadb.labels
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: ["ReadWriteOnce"]
		resources: requests: storage: #config.mariadb.persistence.size
	}
}
