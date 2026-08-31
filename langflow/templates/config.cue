// SPDX-License-Identifier: Apache-2.0
package templates

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Config defines the schema and defaults for Langflow instance values.
#Config: {
	kubeVersion!: string
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.26.0"}
	moduleVersion!: string

	metadata: timoniv1.#Metadata & {#Version: moduleVersion}
	metadata: labels: timoniv1.#Labels
	metadata: annotations?: timoniv1.#Annotations

	selector: timoniv1.#Selector & {#Name: metadata.name}

	nameOverride:     *"" | string
	fullnameOverride: *"" | string
	commonLabels: {[string]: string}

	image: timoniv1.#Image & {
		repository: *"docker.io/langflowai/langflow" | string
		tag:        *"1.11.1" | string
		pullPolicy: *"IfNotPresent" | string
	}

	imagePullSecrets: *[] | [...corev1.#LocalObjectReference]
	replicaCount:     *1 | int & >=0

	app: {
		port:    *7860 | int & >0 & <=65535
		command: *[] | [...string]
		args:    *[] | [...string]
		env:     *[] | [...corev1.#EnvVar]
		envFrom: *[] | [...corev1.#EnvFromSource]
		extraEnv: *[] | [...corev1.#EnvVar]
	}

	auth: {
		secretKey:            *"" | string
		superuser:            *"" | string
		superuserPassword:    *"" | string
		existingSecret:       *"" | string
		secretKeyKey:         *"secret-key" | string
		superuserKey:         *"superuser" | string
		superuserPasswordKey: *"superuser-password" | string
	}

	database: {
		mode:           *"sqlite" | string
		url:            *"" | string
		existingSecret: *"" | string
		urlKey:         *"database-url" | string
	}

	persistence: {
		enabled:       *true | bool
		size:          *"5Gi" | string
		storageClass:  *"" | string
		accessModes:   *["ReadWriteOnce"] | [...corev1.#PersistentVolumeAccessMode]
		existingClaim: *"" | string
		mountPath:     *"/app/langflow" | string
	}

	serviceAccount: {
		create:                       *false | bool
		name:                         *"" | string
		annotations:                  {[string]: string}
		automountServiceAccountToken: *false | bool
	}

	service: {
		type: *"ClusterIP" | string
		port: *7860 | int & >0 & <=65535
		annotations: {[string]: string}
		ipFamilyPolicy: *"" | string
		ipFamilies:     *[] | [...string]
	}

	gateway: {
		enabled:     *false | bool
		annotations: {[string]: string}
		parentRefs:  *[] | [...{
			name:        string
			namespace?:  string
			group?:      string
			kind?:       string
			sectionName?: string
			port?:       int
		}]
		hostnames: *[] | [...string]
		path:      *"/" | string
		pathType:  *"PathPrefix" | "Exact" | string
	}

	pdb: {
		enabled:      *false | bool
		minAvailable: *1 | int | string
	}

	networkPolicy: {
		enabled: *false | bool
		ingressFrom: *[] | [...{
			namespaceSelector?: corev1.#LabelSelector
			podSelector?:       corev1.#LabelSelector
		}]
		dnsEgressPeers: *[{
			namespaceSelector: matchLabels: "kubernetes.io/metadata.name": "kube-system"
			podSelector: matchLabels: "k8s-app":                           "kube-dns"
		}] | [...{
			namespaceSelector?: corev1.#LabelSelector
			podSelector?:       corev1.#LabelSelector
		}]
		extraEgress: *[] | [...{
			to?: [...{
				ipBlock?: {
					cidr:   string
					except?: [...string]
				}
				namespaceSelector?: corev1.#LabelSelector
				podSelector?:       corev1.#LabelSelector
			}]
			ports?: [...{
				protocol?: *"TCP" | "UDP"
				port?:     int | string
			}]
		}]
	}

	probes: {
		startup: {
			enabled:             *true | bool
			path:                *"/health_check" | string
			initialDelaySeconds: *5 | int
			periodSeconds:       *10 | int
			timeoutSeconds:      *3 | int
			failureThreshold:    *60 | int
		}
		liveness: {
			enabled:             *true | bool
			path:                *"/health_check" | string
			initialDelaySeconds: *0 | int
			periodSeconds:       *20 | int
			timeoutSeconds:      *5 | int
			failureThreshold:    *3 | int
		}
		readiness: {
			enabled:             *true | bool
			path:                *"/health_check" | string
			initialDelaySeconds: *0 | int
			periodSeconds:       *10 | int
			timeoutSeconds:      *5 | int
			failureThreshold:    *6 | int
		}
	}

	resources:          corev1.#ResourceRequirements | *{}
	podSecurityContext: corev1.#PodSecurityContext | *{}
	securityContext:    corev1.#SecurityContext | *{}

	nodeSelector:              {[string]: string}
	tolerations:               *[] | [...corev1.#Toleration]
	affinity:                  corev1.#Affinity | *{}
	topologySpreadConstraints: *[] | [...corev1.#TopologySpreadConstraint]

	priorityClassName:             *"" | string
	terminationGracePeriodSeconds: *30 | int
	podLabels:                     {[string]: string}
	podAnnotations:                {[string]: string}

	extraVolumes:      *[] | [...corev1.#Volume]
	extraVolumeMounts: *[] | [...corev1.#VolumeMount]
	extraManifests:    *[] | [...{...}]
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	name: string | *config.metadata.name
	fullname: string | *{
		if config.fullnameOverride != "" {
			config.fullnameOverride
		}
		if config.fullnameOverride == "" {
			if config.nameOverride != "" {
				"\(name)-\(config.nameOverride)"
			}
			if config.nameOverride == "" {
				name
			}
		}
	}

	serviceAccountName: string | *{
		if !config.serviceAccount.create {
			if config.serviceAccount.name != "" {
				config.serviceAccount.name
			}
			if config.serviceAccount.name == "" {
				"default"
			}
		}
		if config.serviceAccount.create {
			if config.serviceAccount.name != "" {
				config.serviceAccount.name
			}
			if config.serviceAccount.name == "" {
				fullname
			}
		}
	}

	authSecretName: string | *{
		if config.auth.existingSecret != "" {
			config.auth.existingSecret
		}
		if config.auth.existingSecret == "" {
			fullname
		}
	}

	dbSecretName: string | *{
		if config.database.existingSecret != "" {
			config.database.existingSecret
		}
		if config.database.existingSecret == "" {
			"\(fullname)-database"
		}
	}

	objects: {
		if config.serviceAccount.create {
			sa: #ServiceAccountBuilder & {_config: config, _serviceAccountName: serviceAccountName}
		}

		if config.auth.existingSecret == "" {
			secret: #SecretBuilder & {_config: config, _authSecretName: authSecretName}
		}

		if config.database.existingSecret == "" && config.database.url != "" {
			dbSecret: #DatabaseSecretBuilder & {_config: config, _dbSecretName: dbSecretName}
		}

		if config.persistence.enabled && config.persistence.existingClaim == "" {
			pvc: #PVCBuilder & {_config: config, _fullname: fullname}
		}

		deploy: #DeploymentBuilder & {
			_config:             config
			_fullname:           fullname
			_serviceAccountName: serviceAccountName
			_authSecretName:     authSecretName
			_dbSecretName:       dbSecretName
		}

		svc: #ServiceBuilder & {_config: config, _fullname: fullname}

		if config.gateway.enabled {
			httproute: #HTTPRouteBuilder & {_config: config, _fullname: fullname}
		}

		if config.pdb.enabled {
			pdb: #PDBBuilder & {_config: config, _fullname: fullname}
		}

		if config.networkPolicy.enabled {
			networkpolicy: #NetworkPolicyBuilder & {_config: config, _fullname: fullname}
		}

		for i, m in config.extraManifests {
			"extra-\(i)": m
		}
	}
}
