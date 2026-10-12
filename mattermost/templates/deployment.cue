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
	metadata: labels: {
		app: "mattermost-\(#config.moduleVersion)"
	}
	spec: appsv1.#DeploymentSpec & {
		replicas:             #config.replicas
		revisionHistoryLimit: #config.revisionHistoryLimit
		strategy: {
			type: "Recreate"
		}
		selector: {
			matchLabels: {
				"pod.name": "main"
				#config.selector.labels
			}
		}
		template: {
			metadata: {
				labels: {
					app: "mattermost-\(#config.moduleVersion)"
					#config.selector.labels
					"pod.lifecycle": "permanent"
					"pod.name":      "main"
				}
				if #config.podAnnotations != _|_ {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           #config.metadata.name
				automountServiceAccountToken: #config.automountServiceAccountToken
				if #config.runtimeClassName != _|_ {
					runtimeClassName: #config.runtimeClassName
				}
				hostNetwork:           false
				hostPID:               false
				hostIPC:               false
				shareProcessNamespace: false
				enableServiceLinks:    #config.enableServiceLinks
				restartPolicy:         "Always"
				nodeSelector:          #config.nodeSelector
				if _affinity.#Enabled {
					affinity: _affinity
				}
				if #config.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: #config.topologySpreadConstraints
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
				terminationGracePeriodSeconds: #config.terminationGracePeriodSeconds
				if #config.podSecurityContext != _|_ {
					securityContext: #config.podSecurityContext
				}
				hostUsers: true
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
								protocol:      #config.service.main.ports.main.protocol
							},
						]
						volumeMounts: [
							{
								name:      "bleveindexes"
								mountPath: #config.persistence.bleveindexes.mountPath
								readOnly:  #config.persistence.bleveindexes.readOnly
							},
							{
								name:      "clientplugins"
								mountPath: #config.persistence.clientplugins.mountPath
								readOnly:  #config.persistence.clientplugins.readOnly
							},
							{
								name:      "config"
								mountPath: #config.persistence.config.mountPath
								readOnly:  #config.persistence.config.readOnly
							},
							{
								name:      "data"
								mountPath: #config.persistence.data.mountPath
								readOnly:  #config.persistence.data.readOnly
							},
							{
								name:      "devshm"
								mountPath: "/dev/shm"
								readOnly:  false
							},
							{
								name:      "logs"
								mountPath: #config.persistence.logs.mountPath
								readOnly:  #config.persistence.logs.readOnly
							},
							{
								name:      "plugins"
								mountPath: #config.persistence.plugins.mountPath
								readOnly:  #config.persistence.plugins.readOnly
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
								name: "vartmp"
								mountPath: "var/tmp"
								readOnly: false
							},
							{
								name:      "varrun"
								mountPath: "/var/run"
								readOnly:  false
							},
							for name, p in #config.persistence if p.enabled && name != "bleveindexes" && name != "clientplugins" && name != "config" && name != "data" && name != "logs" && name != "plugins" {
								"name":     name
								mountPath: p.mountPath
								readOnly:  p.readOnly
								if p.subPath != _|_ {
									subPath: p.subPath
								}
							},
						]
						if #config.probes.liveness.enabled {
							livenessProbe: {
								httpGet: {
									port:   #config.service.main.ports.main.targetPort
									path:   #config.probes.liveness.path
									scheme: "HTTP"
								}
								initialDelaySeconds: #config.probes.liveness.initialDelaySeconds
								failureThreshold:    #config.probes.liveness.failureThreshold
								successThreshold:    #config.probes.liveness.successThreshold
								timeoutSeconds:      #config.probes.liveness.timeoutSeconds
								periodSeconds:       #config.probes.liveness.periodSeconds
							}
						}
						if #config.probes.readiness.enabled {
							readinessProbe: {
								httpGet: {
									port:   #config.service.main.ports.main.targetPort
									path:   #config.probes.readiness.path
									scheme: "HTTP"
								}
								initialDelaySeconds: #config.probes.readiness.initialDelaySeconds
								failureThreshold:    #config.probes.readiness.failureThreshold
								successThreshold:    #config.probes.readiness.successThreshold
								timeoutSeconds:      #config.probes.readiness.timeoutSeconds
								periodSeconds:       #config.probes.readiness.periodSeconds
							}
						}
						if #config.probes.startup.enabled {
							startupProbe: {
								httpGet: {
									port:   #config.service.main.ports.main.targetPort
									path:   #config.probes.startup.path
									scheme: "HTTP"
								}
								initialDelaySeconds: #config.probes.startup.initialDelaySeconds
								failureThreshold:    #config.probes.startup.failureThreshold
								successThreshold:    #config.probes.startup.successThreshold
								timeoutSeconds:      #config.probes.startup.timeoutSeconds
								periodSeconds:       #config.probes.startup.periodSeconds
							}
						}
						resources:       #config.resources
						securityContext: #config.securityContext
						env: [
							for k, v in #config.workload.main.podSpec.containers.main.env {
								name:  k
								value: v
							},
						]
					},
				]
				if #config.cnpg.main.enabled {
					initContainers: [
						{
							name:            "\(#config.metadata.name)-system-cnpg-wait"
							image:           "oci.trueforge.org/containerforge/postgresql-client:9.6.24@sha256:8ca87491df3145248ee8040ab01ff816a2af13a401c6db950aac371c1b3ebf81"
							imagePullPolicy: "IfNotPresent"
							tty:             false
							stdin:           false
							command: [
								"/bin/sh",
								"-c",
								"/bin/sh <<'EOF'\necho \"Executing DB waits...\"\necho \"Testing Database availability on [CNPG RW]\"\nuntil\n  echo \"Testing database on url: [\(#config.metadata.name)-cnpg-main-rw]\"\n  pg_isready -U \(#config.cnpg.main.user) -d \(#config.cnpg.main.database) -h \(#config.metadata.name)-cnpg-main-rw\n  do sleep 5\ndone\necho \"Database available on url: [\(#config.metadata.name)-cnpg-main-rw]\"\necho \"Done executing DB waits...\"\nEOF",
							]
							volumeMounts: [
								{
									"name":     "devshm"
									mountPath: "/dev/shm"
									readOnly:  false
								},
								{
									"name":     "shared"
									mountPath: "/shared"
									readOnly:  false
								},
								{
									"name":     "tmp"
									mountPath: "/tmp"
									readOnly:  false
								},
								{
									"name":     "varlogs"
									mountPath: "/var/logs"
									readOnly:  false
								},
								{
									"name":     "varrun"
									mountPath: "/var/run"
									readOnly:  false
								},
							]
							resources: {
								requests: {
									cpu:    "10m"
									memory: "50Mi"
								}
								limits: {
									cpu:    "500m"
									memory: "512Mi"
								}
							}
							securityContext: #config.securityContext
							env: [
								{
									name:  "TZ"
									value: "UTC"
								},
								{
									name:  "UMASK"
									value: "0022"
								},
								{
									name:  "UMASK_SET"
									value: "0022"
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
						"name": "devshm"
						emptyDir: {
							medium:    "Memory"
							sizeLimit: "2400Mi"
						}
					},
					{
						"name": "shared"
						emptyDir: {}
					},
					{
						"name": "tmp"
						emptyDir: {
							medium:    "Memory"
							sizeLimit: "2400Mi"
						}
					},
					{
						"name" : "vartmp"
						emptyDir: {
							medium: "Memory"
							sizeLimit: "2400Mi"
						}
					},
					{
						"name": "varlogs"
						emptyDir: {
							medium:    "Memory"
							sizeLimit: "2400Mi"
						}
					},
					{
						"name": "varrun"
						emptyDir: {
							medium:    "Memory"
							sizeLimit: "2400Mi"
						}
					},
					{
						"name": "bleveindexes"
						if #config.persistence.bleveindexes.existingClaim != _|_ {
							persistentVolumeClaim: claimName: #config.persistence.bleveindexes.existingClaim
						}
						if #config.persistence.bleveindexes.existingClaim == _|_ && #config.persistence.bleveindexes.size != "" {
							persistentVolumeClaim: claimName: "\(#config.metadata.name)-bleveindexes"
						}
						if #config.persistence.bleveindexes.existingClaim == _|_ && #config.persistence.bleveindexes.size == "" {
							emptyDir: {}
						}
					},
					{
						"name": "clientplugins"
						if #config.persistence.clientplugins.existingClaim != _|_ {
							persistentVolumeClaim: claimName: #config.persistence.clientplugins.existingClaim
						}
						if #config.persistence.clientplugins.existingClaim == _|_ && #config.persistence.clientplugins.size != "" {
							persistentVolumeClaim: claimName: "\(#config.metadata.name)-clientplugins"
						}
						if #config.persistence.clientplugins.existingClaim == _|_ && #config.persistence.clientplugins.size == "" {
							emptyDir: {}
						}
					},
					{
						"name": "config"
						if #config.persistence.config.existingClaim != _|_ {
							persistentVolumeClaim: claimName: #config.persistence.config.existingClaim
						}
						if #config.persistence.config.existingClaim == _|_ && #config.persistence.config.size != "" {
							persistentVolumeClaim: claimName: "\(#config.metadata.name)-config"
						}
						if #config.persistence.config.existingClaim == _|_ && #config.persistence.config.size == "" {
							emptyDir: {}
						}
					},
					{
						"name": "data"
						if #config.persistence.data.existingClaim != _|_ {
							persistentVolumeClaim: claimName: #config.persistence.data.existingClaim
						}
						if #config.persistence.data.existingClaim == _|_ && #config.persistence.data.size != "" {
							persistentVolumeClaim: claimName: "\(#config.metadata.name)-data"
						}
						if #config.persistence.data.existingClaim == _|_ && #config.persistence.data.size == "" {
							emptyDir: {}
						}
					},
					{
						"name": "logs"
						if #config.persistence.logs.existingClaim != _|_ {
							persistentVolumeClaim: claimName: #config.persistence.logs.existingClaim
						}
						if #config.persistence.logs.existingClaim == _|_ && #config.persistence.logs.size != "" {
							persistentVolumeClaim: claimName: "\(#config.metadata.name)-logs"
						}
						if #config.persistence.logs.existingClaim == _|_ && #config.persistence.logs.size == "" {
							emptyDir: {}
						}
					},
					{
						"name": "plugins"
						if #config.persistence.plugins.existingClaim != _|_ {
							persistentVolumeClaim: claimName: #config.persistence.plugins.existingClaim
						}
						if #config.persistence.plugins.existingClaim == _|_ && #config.persistence.plugins.size != "" {
							persistentVolumeClaim: claimName: "\(#config.metadata.name)-plugins"
						}
						if #config.persistence.plugins.existingClaim == _|_ && #config.persistence.plugins.size == "" {
							emptyDir: {}
						}
					},
					for name, p in #config.persistence if p.enabled && name != "bleveindexes" && name != "clientplugins" && name != "config" && name != "data" && name != "logs" && name != "plugins" {
						"name": name
						if p.existingClaim != _|_ {
							persistentVolumeClaim: claimName: p.existingClaim
						}
						if p.existingClaim == _|_ && p.size != "" {
							persistentVolumeClaim: claimName: "\(#config.metadata.name)-\(name)"
						}
						if p.existingClaim == _|_ && p.size == "" {
							emptyDir: {}
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
