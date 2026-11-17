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
	metadata: labels: timoniv1.#Labels

	// The annotations allows adding `metadata.annotations` to all resources.
	metadata: annotations?: timoniv1.#Annotations

	// The selector allows adding label selectors to Deployments and Services.
	selector: timoniv1.#Selector & {#Name: metadata.name}

	nameOverride:     *"" | string
	fullnameOverride: *"" | string

	podSecurityContext?: corev1.#PodSecurityContext

	existingSecret: *"" | string

	server: {
		enabled: *true | bool
		image: timoniv1.#Image & {
			repository: *"docker.io/opensign/opensignserver" | string
			tag:        *"main" | string
			digest:     *"sha256:674fa8393122cb550d5c2fa4ddae5e13989387f27d63db98e6c23272849a551e" | string
		}
		replicas: *1 | int & >0
		port:     *8080 | int & >0 & <=65535
		env: {[string]: string}
		resources:       timoniv1.#ResourceRequirements
		securityContext: corev1.#SecurityContext
		persistence: {
			enabled:      *true | bool
			storageClass: *"" | string
			accessMode:   *"ReadWriteOnce" | "ReadOnlyMany" | "ReadWriteMany"
			size:         *"5Gi" | string
		}
		serviceAccount: {
			create: *true | bool
			name:   *"" | string
		}
		probes: {
			startup: {
				enabled:             *true | bool
				initialDelaySeconds: *10 | int
				periodSeconds:       *5 | int
				timeoutSeconds:      *3 | int
				failureThreshold:    *30 | int
			}
			liveness: {
				enabled:             *true | bool
				initialDelaySeconds: *30 | int
				periodSeconds:       *15 | int
				timeoutSeconds:      *5 | int
				failureThreshold:    *3 | int
			}
			readiness: {
				enabled:             *true | bool
				initialDelaySeconds: *15 | int
				periodSeconds:       *10 | int
				timeoutSeconds:      *5 | int
				failureThreshold:    *3 | int
			}
		}
	}

	client: {
		enabled: *true | bool
		image: timoniv1.#Image & {
			repository: *"docker.io/opensign/opensign" | string
			tag:        *"main" | string
			digest:     *"sha256:093910c698c135e272a794ec1df81324c584b0c1011bb95da0c04ff22adb45ac" | string
		}
		replicas: *1 | int & >0
		port:     *3000 | int & >0 & <=65535
		env: {[string]: string}
		resources:       timoniv1.#ResourceRequirements
		securityContext: corev1.#SecurityContext
		serviceAccount: {
			create: *true | bool
			name:   *"" | string
		}
		autoscaling: {
			enabled:                           *false | bool
			minReplicas:                       *1 | int
			maxReplicas:                       *5 | int
			targetCPUUtilizationPercentage:    *80 | int
			targetMemoryUtilizationPercentage: *80 | int
		}
		podDisruptionBudget: {
			enabled:        *false | bool
			minAvailable:   *"" | string
			maxUnavailable: *"1" | string
		}
		probes: {
			startup: {
				enabled:             *true | bool
				initialDelaySeconds: *5 | int
				periodSeconds:       *5 | int
				timeoutSeconds:      *3 | int
				failureThreshold:    *30 | int
			}
			liveness: {
				enabled:             *true | bool
				initialDelaySeconds: *20 | int
				periodSeconds:       *15 | int
				timeoutSeconds:      *5 | int
				failureThreshold:    *3 | int
			}
			readiness: {
				enabled:             *true | bool
				initialDelaySeconds: *10 | int
				periodSeconds:       *10 | int
				timeoutSeconds:      *5 | int
				failureThreshold:    *3 | int
			}
		}
	}

	mongodb: {
		enabled: *true | bool
		image: timoniv1.#Image & {
			repository: *"docker.io/library/mongo" | string
			tag:        *"9.0.8" | string
			digest:     *"sha256:20af90d0f14159e5532a4929608bc7cd9ecd718d3bae9d2f5457f4f0c509e3dc" | string
		}
		port: *27017 | int & >0 & <=65535
		resources:          timoniv1.#ResourceRequirements
		securityContext:    corev1.#SecurityContext
		podSecurityContext?: corev1.#PodSecurityContext
		persistence: {
			enabled:      *true | bool
			storageClass: *"" | string
			accessMode:   *"ReadWriteOnce" | "ReadOnlyMany" | "ReadWriteMany"
			size:         *"10Gi" | string
		}
		serviceAccount: {
			create: *true | bool
			name:   *"" | string
		}
		probes: {
			liveness: {
				enabled:             *true | bool
				initialDelaySeconds: *20 | int
				periodSeconds:       *15 | int
				timeoutSeconds:      *5 | int
				failureThreshold:    *3 | int
			}
			readiness: {
				enabled:             *true | bool
				initialDelaySeconds: *10 | int
				periodSeconds:       *10 | int
				timeoutSeconds:      *5 | int
				failureThreshold:    *3 | int
			}
		}
	}

	externalMongodb: {
		enabled:              *false | bool
		uri:                  *"" | string
		existingSecret:       *"" | string
		existingSecretKey:    *"uri" | string
		existingSecretUriKey: *"" | string
	}

	gateway: {
		enabled:     *false | bool
		annotations: *{} | {[string]: string}
		parentRefs:  *[
			{
				name:      "eg"
				namespace: "envoy-gateway-system"
			},
		] | [...{
			name:        string
			namespace?:  string
			sectionName?: string
			group?:      string
			kind?:       string
			port?:       int
		}]
		hostnames: *["opensign.example.com"] | [...string]
	}

	backup: {
		enabled:                    *false | bool
		schedule:                   *"0 2 * * *" | string
		suspend:                    *false | bool
		concurrencyPolicy:          *"Forbid" | "Allow" | "Replace"
		successfulJobsHistoryLimit: *3 | int
		failedJobsHistoryLimit:     *3 | int
		backoffLimit:               *1 | int
		archivePrefix:              *"opensign" | string
		images: {
			mongodb:  *"docker.io/library/mongo:9.0.8" | string
			uploader: *"docker.io/helmforge/mc:1.0.0" | string
		}
		resources: timoniv1.#ResourceRequirements
		s3: {
			endpoint:                   *"" | string
			bucket:                     *"" | string
			prefix:                     *"opensign" | string
			createBucketIfNotExists:    *true | bool
			existingSecret:             *"" | string
			existingSecretAccessKeyKey: *"access-key" | string
			existingSecretSecretKeyKey: *"secret-key" | string
			accessKey:                  *"" | string
			secretKey:                  *"" | string
		}
	}

	test?: {
		enabled: *false | bool
		image?:  timoniv1.#Image
	}

	config: {
		publicUrl: *"http://localhost:3000" | string
		apiUrl:    *"http://localhost:8080/app" | string
	}

	externalSecrets: {
		enabled:    *false | bool
		apiVersion: *"external-secrets.io/v1" | string
		name:       *"" | string
		secretStoreRef: {
			name: *"" | string
			kind: *"SecretStore" | string
		}
		target: {
			name:           *"" | string
			creationPolicy: *"Owner" | string
			template?:      {...}
		}
		refreshInterval: *"1h" | string
		data:            *[] | [...]
		dataFrom:        *[] | [...]
		annotations:     *{} | {[string]: string}
	}

	envSecret: {[string]: string}
}

#Instance: {
	config: #Config

	objects: {
		if config.server.enabled {
			if config.server.serviceAccount.create {
				saServer: #ServerServiceAccount & {#config: config}
			}
			if config.server.persistence.enabled {
				pvcServer: #ServerPVC & {#config: config}
			}
			deployServer: #ServerDeployment & {#config: config}
			svcServer:    #ServerService & {#config:    config}
		}

		if config.client.enabled {
			if config.client.serviceAccount.create {
				saClient: #ClientServiceAccount & {#config: config}
			}
			deployClient: #ClientDeployment & {#config: config}
			svcClient:    #ClientService & {#config:    config}
			if config.client.autoscaling.enabled {
				hpaClient: #ClientHPA & {#config: config}
			}
			if config.client.podDisruptionBudget.enabled {
				pdbClient: #ClientPDB & {#config: config}
			}
		}

		if config.mongodb.enabled && !config.externalMongodb.enabled {
			if config.mongodb.serviceAccount.create {
				saMongo: #MongoServiceAccount & {#config: config}
			}
			if config.mongodb.persistence.enabled {
				pvcMongo: #MongoPVC & {#config: config}
			}
			deployMongo: #MongoDeployment & {#config: config}
			svcMongo:    #MongoService & {#config:    config}
		}

		if config.gateway.enabled {
			httpRoute: #HTTPRoute & {#config: config}
		}

		if config.backup.enabled {
			backupConfigMap: #BackupConfigMap & {#config: config}
			backupCronJob:   #BackupCronJob & {#config:   config}
		}

		if config.externalSecrets.enabled {
			externalSecret: #ExternalSecret & {#config: config}
		}

		if config.existingSecret == "" && !config.externalSecrets.enabled {
			envSecret: #EnvSecret & {#config: config}
		}
	}

	tests: {}
}
