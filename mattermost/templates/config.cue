package templates

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Config defines the schema and defaults for the Instance values.
#Config: {
	// The kubeVersion is a required field, set at apply-time
	// via timoni.cue by querying the user's Kubernetes API.
	kubeVersion!: string
	// Using the kubeVersion you can enforce a minimum Kubernetes minor version.
	// By default, the minimum Kubernetes version is set to 1.20.
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.20.0"}

	// The moduleVersion is set from the user-supplied module version.
	// This field is used for the `app.kubernetes.io/version` label.
	moduleVersion!: string

	// The Kubernetes metadata common to all resources.
	// The `metadata.name` and `metadata.namespace` fields are
	// set from the user-supplied instance name and namespace.
	metadata: timoniv1.#Metadata & {#Version: moduleVersion}

	// The labels allows adding `metadata.labels` to all resources.
	// The `app.kubernetes.io/name` and `app.kubernetes.io/version` labels
	// are automatically generated and can't be overwritten.
	metadata: labels: timoniv1.#Labels

	// The annotations allows adding `metadata.annotations` to all resources.
	metadata: annotations?: timoniv1.#Annotations

	// The selector allows adding label selectors to Deployments and Services.
	// The `app.kubernetes.io/name` label selector is automatically generated
	// from the instance name and can't be overwritten.
	selector: timoniv1.#Selector & {#Name: metadata.name}

	// The image allows setting the container image repository,
	// tag, digest and pull policy.
	// The default image repository, tag and digest are set in `images.cue`.
	image!: timoniv1.#Image

	// Workload mirroring Helm values.yaml
	workload: main: podSpec: containers: main: {
		env: {
			TIMEZONE:                   *"UTC" | string
			TZ:                         *"UTC" | string
			UMASK:                      *"0022" | string
			UMASK_SET:                  *"0022" | string
			NVIDIA_VISIBLE_DEVICES:     *"void" | string
			S6_READ_ONLY_ROOT:          *"1" | string
			MM_SQLSETTINGS_DRIVERNAME:  *"postgres" | string
			MM_BLEVESETTINGS_INDEXDIR:  *"/mattermost/bleve-indexes" | string
			MM_SERVICESETTINGS_SITEURL: *"https://test.example.com" | string
			MM_SQLSETTINGS_DATASOURCE?: string
			[string]:                   string
		}
	}

	// Service mirroring Helm values.yaml
	service: main: {
		enabled?:                  bool
		annotations?:              timoniv1.#Annotations
		publishNotReadyAddresses?: bool
		type:                      *corev1.#ServiceTypeClusterIP | corev1.#ServiceType
		ports: main: {
			port:       *10239 | int & >0 & <=65535
			targetPort: *8065 | int & >0 & <=65535
			protocol:   *"TCP" | string
		}
	}

	// Persistence mirroring Helm values.yaml (all 6 PVCs)
	persistence: {
		config: #PersistenceItem & {
			mountPath: *"/mattermost/config" | string
		}
		data: #PersistenceItem & {
			mountPath: *"/mattermost/data" | string
		}
		logs: #PersistenceItem & {
			mountPath: *"/mattermost/logs" | string
		}
		plugins: #PersistenceItem & {
			mountPath: *"/mattermost/plugins" | string
		}
		clientplugins: #PersistenceItem & {
			mountPath: *"/mattermost/client/plugins" | string
		}
		bleveindexes: #PersistenceItem & {
			mountPath: *"/mattermost/bleve-indexes" | string
		}
		[string]: #PersistenceItem
	}

	// CNPG mirroring Helm values.yaml
	cnpg: main: {
		enabled:   *true | bool
		user:      *"mattermost" | string
		password:  *"mattermost" | string
		database:  *"mattermost" | string
		instances: *2 | int & >0
		image: {
			repository: *"ghcr.io/cloudnative-pg/postgresql" | string
			tag:        *"18.6" | string
			digest:     *"sha256:899d3ed526b659d77935dde0e6bf2d69dbbf17d3d8c6486ca8cfd04bd3c18533" | string
			reference:  *"\(repository):\(tag)@\(digest)" | string
		}
		storage: size:    *"100Gi" | string
		walStorage: size: *"100Gi" | string
	}

	// Deployment spec settings mirroring Helm
	replicas:                      *1 | int & >0
	revisionHistoryLimit:          *3 | int
	automountServiceAccountToken: *false | bool
	runtimeClassName?:             string
	enableServiceLinks:            *false | bool
	terminationGracePeriodSeconds: *60 | int

	// Resources mirroring Helm (requests & limits)
	resources: timoniv1.#ResourceRequirements & {
		requests: {
			cpu:    *"75m" | timoniv1.#CPUQuantity
			memory: *"200Mi" | timoniv1.#MemoryQuantity
		}
		limits: {
			cpu:    *"1500m" | timoniv1.#CPUQuantity
			memory: *"2400Mi" | timoniv1.#MemoryQuantity
		}
	}

	securityContext: corev1.#SecurityContext & {
		allowPrivilegeEscalation: *false | true
		privileged:               *false | true
		runAsNonRoot:             *true | bool
		runAsUser:                *568 | int
		runAsGroup:               *568 | int
		readOnlyRootFilesystem:   *true | bool
		seccompProfile: {
			type: *"RuntimeDefault" | string
		}
		capabilities: {
			drop: *["ALL"] | [...string]
			add: *[] | [...string]
		}
	}

	// Probes configuration mirroring Helm
	probes: {
		startup: #ProbeConfig & {
			initialDelaySeconds: 10
			failureThreshold:    60
			successThreshold:    1
			timeoutSeconds:      3
			periodSeconds:       5
		}
		liveness: #ProbeConfig & {
			initialDelaySeconds: 12
			failureThreshold:    5
			successThreshold:    1
			timeoutSeconds:      5
			periodSeconds:       15
		}
		readiness: #ProbeConfig & {
			initialDelaySeconds: 10
			failureThreshold:    4
			successThreshold:    2
			timeoutSeconds:      5
			periodSeconds:       12
		}
	}

	// Pod optional settings.
	podAnnotations?: {[string]: string}
	podSecurityContext: corev1.#PodSecurityContext & {
		fsGroup:             *568 | int
		fsGroupChangePolicy: *"OnRootMismatch" | string
		supplementalGroups:  *[568] | [...int]
	}
	imagePullSecrets?: [...timoniv1.#ObjectReference]
	tolerations?: [...corev1.#Toleration]
	topologySpreadConstraints?: [...corev1.#TopologySpreadConstraint]

	// Pods are scheduled on Linux nodes by default.
	nodeSelector: *{"kubernetes.io/os": "linux"} | {[string]: string}

	// Affinity rules
	affinity: timoniv1.#AffinityValues & {
		podAntiAffinity: timoniv1.#AffinityPreset | corev1.#PodAntiAffinity
		nodeAffinity?:   corev1.#NodeAffinity
		podAffinity?:    corev1.#PodAffinity
	}
}

#ProbeConfig: {
	enabled:             *true | bool
	path:                *"/" | string
	initialDelaySeconds: int
	periodSeconds:       int
	timeoutSeconds:      int
	failureThreshold:    int
	successThreshold:    int
}

#PersistenceItem: {
	enabled:        *true | bool
	mountPath!:     string
	subPath?:       string
	readOnly:       *false | bool
	existingClaim?: string
	size:           *"100Gi" | timoniv1.#MemoryQuantity | string
	storageClass?:  string
	accessMode:     *"ReadWriteOnce" | "ReadOnlyMany" | "ReadWriteMany"
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		sa:     #ServiceAccount & {#config: config}
		svc:    #Service & {#config:        config}
		deploy: #Deployment & {#config:     config}

		if config.cnpg.main.enabled {
			"secret-cnpg-user": #CNPGUserSecret & {#config: config}
			"secret-cnpg-urls": #CNPGUrlsSecret & {#config: config}
			"cluster-cnpg":     #CNPGCluster & {#config: config}
		}

		for name, p in config.persistence if p.enabled && p.size != "" && p.existingClaim == _|_ {
			"\(name)-pvc": #PersistentVolumeClaim & {
				#config: config
				#name:   name
				#item:   p
			}
		}
	}
}
