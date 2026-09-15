package templates

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Config defines the schema and defaults mirroring values.yaml exactly.
#Config: {
	// Timoni injected runtime metadata
	kubeVersion!: string
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.20.0"}
	moduleVersion!: string

	metadata: timoniv1.#Metadata & {#Version: moduleVersion}
	metadata: labels: timoniv1.#Labels
	metadata: labels: {
		"app.kubernetes.io/instance": metadata.name
		"app.kubernetes.io/name":     metadata.name
		"release":                    metadata.name
	}
	metadata: annotations?: timoniv1.#Annotations
	selector: timoniv1.#Selector & {#Name: metadata.name}

	// Node selector for scheduling
	nodeSelector: *{"kubernetes.io/arch": "amd64"} | {[string]: string}

	// Scheduling affinity
	affinity: *{
		podAffinity: requiredDuringSchedulingIgnoredDuringExecution: [
			{
				topologyKey: "kubernetes.io/hostname"
				labelSelector: matchExpressions: [
					{
						key:      "truecharts.org/pvc"
						operator: "In"
						values: ["code"]
					},
				]
			},
		]
	} | corev1.#Affinity

	// Topology spread constraints
	topologySpreadConstraints: *[
		{
			maxSkew:           1
			whenUnsatisfiable: "ScheduleAnyway"
			topologyKey:       "kubernetes.io/hostname"
			labelSelector: matchLabels: {
				"pod.name":                   "main"
				"app.kubernetes.io/name":     metadata.name
				"app.kubernetes.io/instance": metadata.name
			}
			nodeAffinityPolicy: "Honor"
			nodeTaintsPolicy:   "Honor"
		},
	] | [...corev1.#TopologySpreadConstraint]

	// DNS and termination settings
	dnsPolicy: *"ClusterFirst" | string
	dnsConfig: *{
		options: [
			{
				name:  "ndots"
				value: "1"
			},
		]
	} | corev1.#PodDNSConfig
	terminationGracePeriodSeconds: *60 | int

	// Pod spec options
	serviceAccountName:           *"default" | string
	automountServiceAccountToken: *false | bool
	enableServiceLinks:           *false | bool
	hostNetwork:                  *false | bool
	hostPID:                      *false | bool
	hostIPC:                      *false | bool
	shareProcessNamespace:        *false | bool
	restartPolicy:                *"Always" | string
	hostUsers:                    *true | bool

	// Runtime class name (optional)
	runtimeClassName: *"" | string

	// Common environment and container defaults
	envDefaults: {
		tz:                   *"UTC" | string
		umask:                *"0022" | string
		nvidiaVisibleDevices: *"void" | string
		puid:                 *"568" | string
		pgid:                 *"568" | string
	}
	emptyDirMemoryLimit: *"2400Mi" | string
	podSecurityContext: {
		fsGroup:             *568 | int
		fsGroupChangePolicy: *"OnRootMismatch" | string
		supplementalGroups:  *[568] | [...int]
	}
	resources: {
		requests: {
			cpu:    *"75m" | string
			memory: *"200Mi" | string
		}
		limits: {
			cpu:    *"1500m" | string
			memory: *"2400Mi" | string
		}
	}

	// 1. image
	image: {
		pullPolicy: *"IfNotPresent" | "Always" | "Never"
		repository: *"ghcr.io/linuxserver/cloud9" | string
		tag:        *"version-1.29.2@sha256:45c5fe102ff3390bcd4ea58db99023b7ea099a8462f5727973ec329bd4a8d6b4" | string
	}

	// 2. securityContext
	securityContext: {
		container: {
			runAsNonRoot:             *false | bool
			readOnlyRootFilesystem:   *false | bool
			runAsUser:                *0 | int
			runAsGroup:               *0 | int
			allowPrivilegeEscalation: *false | bool
			privileged:               *false | bool
			seccompProfile: {
				type: *"RuntimeDefault" | string
			}
			capabilities: {
				drop: *["ALL"] | [...string]
				add:  *["CHOWN", "SETUID", "SETGID", "FOWNER", "DAC_OVERRIDE"] | [...string]
			}
		}
	}

	// 3. service
	service: {
		main: {
			ports: {
				main: {
					protocol:   *"http" | string
					targetPort: *8000 | int
					port:       *10070 | int
				}
			}
		}
	}

	// 4. workload
	workload: {
		main: {
			replicas:             *1 | int
			revisionHistoryLimit: *3 | int
			podSpec: {
				containers: {
					main: {
						probes: {
							liveness: {
								enabled:             *true | bool
								type:                *"http" | string
								path:                *"/" | string
								initialDelaySeconds: *12 | int
								periodSeconds:       *15 | int
								timeoutSeconds:      *5 | int
								failureThreshold:    *5 | int
								successThreshold:    *1 | int
							}
							readiness: {
								enabled:             *true | bool
								type:                *"http" | string
								path:                *"/" | string
								initialDelaySeconds: *10 | int
								periodSeconds:       *12 | int
								timeoutSeconds:      *5 | int
								failureThreshold:    *4 | int
								successThreshold:    *2 | int
							}
							startup: {
								enabled:             *true | bool
								type:                *"http" | string
								path:                *"/" | string
								initialDelaySeconds: *10 | int
								periodSeconds:       *5 | int
								timeoutSeconds:      *3 | int
								failureThreshold:    *60 | int
								successThreshold:    *1 | int
							}
						}
						env: {[string]: bool | string | int}
					}
				}
			}
		}
	}

	// 5. persistence
	persistence: {
		code: {
			name:       *"\(metadata.name)-code" | string
			enabled:    *true | bool
			mountPath:  *"/code" | string
			size:       *"100Gi" | string
			accessMode: *"ReadWriteOnce" | string
		}
	}

	// 6. Gateway API route
	route: {
		enabled:      *false | bool
		annotations?: {[string]: string}
		parentRefs?: [...{
			name:         string
			namespace?:   string
			group?:       string
			kind?:        string
			sectionName?: string
			port?:        int
		}]
		hostnames?: [...string]
		path:     *"/" | string
		pathType: *"PathPrefix" | "Exact" | string
	}

	podAnnotations?: {[string]: string}

	test: {
		enabled: *false | bool
	}
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		svc:        #MainService & {#config: config}
		deployMain: #MainDeployment & {#config: config}

		if config.persistence.code.enabled {
			pvcCode: #CodePVC & {#config: config}
		}

		if config.route.enabled {
			httpRoute: #HTTPRoute & {#config: config}
		}
	}

	tests: {}
}
