package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#Config: {
	metadata: {
		name:      string | *"my-listmonk"
		namespace: string | *"default"
	}
	moduleVersion: string | *"6.0.0"
	kubeVersion:   string | *"1.29.0"

	replicaCount: int | *1

	image: {
		repository: string | *"listmonk/listmonk"
		pullPolicy: string | *"IfNotPresent"
		tag:        string | *"v6.1.0"
	}

	imagePullSecrets: [...corev1.#LocalObjectReference]
	nameOverride:     string | *""
	fullnameOverride: string | *""

	serviceAccount: {
		create:      bool | *true
		annotations: {[string]: string}
		name:        string | *""
	}

	podAnnotations: {[string]: string}
	podSecurityContext: corev1.#PodSecurityContext | *{
		runAsUser:           10001
		runAsGroup:          10001
		fsGroup:             10001
	}
	securityContext: corev1.#SecurityContext | *{
		runAsUser:                10001
		runAsGroup:               10001
		runAsNonRoot:             true
		allowPrivilegeEscalation: false
		readOnlyRootFilesystem:   true
		capabilities: {
			drop: ["ALL"]
		}
	}

	service: {
		type: string | *"ClusterIP"
		port: int | *9000
	}

	ingress: {
		enabled:   bool | *false
		className: string | *""
		annotations: {[string]: string}
		hosts: [...{
			host: string
			paths: [...{
				path:     string
				pathType: string
			}]
		}]
		tls: [...{
			secretName: string
			hosts: [...string]
		}]
	}

	resources: corev1.#ResourceRequirements | *{
		limits: {
			cpu:    "500m"
			memory: "512Mi"
		}
		requests: {
			cpu:    "100m"
			memory: "128Mi"
		}
	}

	autoscaling: {
		enabled:                        bool | *false
		minReplicas:                    int | *1
		maxReplicas:                    int | *3
		targetCPUUtilizationPercentage: int | *80
	}

	podDisruptionBudget: {
		enabled:      bool | *true
		minAvailable: int | string | *0
	}

	nodeSelector: {[string]: string}
	tolerations: [...corev1.#Toleration]
	affinity: corev1.#Affinity

	livenessProbe: {
		enabled: bool | *true
		httpGet: {
			path: string | *"/health"
			port: int | *9000
		}
		initialDelaySeconds: int | *60
		periodSeconds:       int | *10
		timeoutSeconds:      int | *5
		failureThreshold:    int | *3
	}

	readinessProbe: {
		enabled: bool | *true
		httpGet: {
			path: string | *"/health"
			port: int | *9000
		}
		initialDelaySeconds: int | *30
		periodSeconds:       int | *10
		timeoutSeconds:      int | *5
		failureThreshold:    int | *3
	}

	startupProbe: {
		enabled: bool | *true
		httpGet: {
			path: string | *"/health"
			port: int | *9000
		}
		initialDelaySeconds: int | *10
		periodSeconds:       int | *5
		timeoutSeconds:      int | *3
		failureThreshold:    int | *30
	}

	admin: {
		username: string | *"admin"
		password: string | *"change-me"
	}

	app: {
		address: string | *"0.0.0.0:9000"
		lang:    string | *"en"
	}

	database: {
		host:           string | *"listmonk-postgres"
		port:           int | *5432
		name:           string | *"listmonk"
		user:           string | *"listmonk"
		password:       string | *"change-me-postgres"
		sslMode:        string | *"disable"
		maxOpen:        int | *25
		maxIdle:        int | *25
		maxLifetime:    string | *"300s"
		existingSecret: string | *""
		passwordKey:    string | *"password"
	}

	postgres: {
		enabled: bool | *true
		image: {
			repository: string | *"postgres"
			tag:        string | *"18"
		}
		migration: {
			enabled: bool | *true
			image:   string | *"registry.k8s.io/kubectl:v1.36.1"
		}
		podDisruptionBudget: {
			enabled:      bool | *true
			minAvailable: int | string | *1
		}
		waitForDatabase: bool | *true
		storage: {
			size:         string | *"4Gi"
			storageClass: string | *""
		}
		resources: corev1.#ResourceRequirements | *{
			requests: {
				cpu:    "100m"
				memory: "256Mi"
			}
			limits: {
				cpu:    "500m"
				memory: "1Gi"
			}
		}
		podSecurityContext: corev1.#PodSecurityContext | *{}
		securityContext:    corev1.#SecurityContext | *{}
		volumePermissions: {
			enabled:   bool | *true
			resources: corev1.#ResourceRequirements | *{
				requests: {
					cpu:    "10m"
					memory: "32Mi"
				}
				limits: {
					cpu:    "50m"
					memory: "64Mi"
				}
			}
		}
	}

	smtp: {
		enabled:        bool | *false
		existingSecret: string | *""
		host:           string | *"smtp.example.com"
		port:           int | *587
		username:       string | *"user@example.com"
		password:       string | *"change-me"
		from:           string | *"noreply@example.com"
		authProtocol:   string | *"login"
		tlsEnabled:     bool | *true
		tlsSkipVerify:  bool | *false
		maxConns:       int | *10
		idleTimeout:    string | *"15s"
		waitTimeout:    string | *"5s"
		maxMsgRetries:  int | *2
		helloHostname:  string | *""
	}

	init: {
		enabled:   bool | *true
		runAsHook: bool | *false
	}

	storage: {
		enabled: bool | *false
		storageClass: string | *""
		accessMode: string | *"ReadWriteOnce"
		size: string | *"5Gi"
		existingClaim: string | *""
		annotations: {[string]: string} | *{}
	}

	test: {
		enabled: bool | *false
		image: {
			repository: string | *"curlimages/curl"
			tag:        string | *"latest"
			pullPolicy: string | *"IfNotPresent"
		}
	}
}

#Instance: {
	config: #Config

	#helpers: #Helpers & {#config: config}

	objects: {
		"configmap": #ConfigMap & {#config: config, #helpers: #helpers}
		"deployment": #Deployment & {#config: config, #helpers: #helpers}
		if config.ingress.enabled {
			"ingress": #Ingress & {#config: config, #helpers: #helpers}
		}
		if config.init.enabled {
			"job-init": #JobInit & {#config: config, #helpers: #helpers}
		}
		if config.podDisruptionBudget.enabled {
			"pdb-listmonk": (#PodDisruptionBudget & {#config: config, #helpers: #helpers}).listmonk
		}
		if config.postgres.enabled && config.postgres.podDisruptionBudget.enabled {
			"pdb-postgres": (#PodDisruptionBudget & {#config: config, #helpers: #helpers}).postgres
		}
		if config.postgres.enabled && config.postgres.migration.enabled {
			#pmj: #PostgresMigrationJob & {#config: config, #helpers: #helpers}
			"pmj-job":         #pmj.job
			"pmj-sa":          #pmj.sa
			"pmj-role":        #pmj.role
			"pmj-rolebinding": #pmj.rolebinding
		}
		if config.postgres.enabled && config.database.existingSecret == "" {
			"postgres-secret": #PostgresSecret & {#config: config, #helpers: #helpers}
		}
		if config.postgres.enabled {
			"postgres-service": #PostgresService & {#config: config, #helpers: #helpers}
			"postgres-statefulset": #PostgresStatefulSet & {#config: config, #helpers: #helpers}
		}
		if config.smtp.enabled && config.smtp.existingSecret == "" {
			"secret": #Secret & {#config: config, #helpers: #helpers}
		}
		if config.storage.enabled && config.storage.existingClaim == "" {
			"pvc": #PVC & {#config: config, #helpers: #helpers}
		}
		"service": #Service & {#config: config, #helpers: #helpers}
		if config.serviceAccount.create {
			"serviceaccount": #ServiceAccount & {#config: config, #helpers: #helpers}
		}
	}

	tests: {
		if config.test.enabled {
			"test-job": #TestJob & {#config: config}
		}
	}
}
