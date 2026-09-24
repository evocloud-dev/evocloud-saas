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

	nameOverride:     *"" | string
	fullnameOverride: *"" | string

	podSecurityContext?: corev1.#PodSecurityContext

	server: {
		enabled: *true | bool
		image: timoniv1.#Image & {
			repository: *"docker.io/opensign/opensignserver" | string
			tag:        *"main" | string
			digest:     *"" | string
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
	}

	client: {
		enabled: *true | bool
		image: timoniv1.#Image & {
			repository: *"docker.io/opensign/opensign" | string
			tag:        *"main" | string
			digest:     *"" | string
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
	}

	mongodb: {
		enabled: *true | bool
		image: timoniv1.#Image & {
			repository: *"docker.io/library/mongo" | string
			tag:        *"7.0" | string
			digest:     *"" | string
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
	}

	caddy: {
		enabled: *true | bool
		image: timoniv1.#Image & {
			repository: *"docker.io/library/caddy" | string
			tag:        *"2.11.4" | string
			digest:     *"" | string
		}
		serviceType: *"LoadBalancer" | "NodePort" | "ClusterIP"
		hostUrl:     *"https://localhost:3001" | string
		caddyfile:   string
		resources:   timoniv1.#ResourceRequirements
		persistence: {
			enabled:      *true | bool
			storageClass: *"" | string
			accessMode:   *"ReadWriteOnce" | "ReadOnlyMany" | "ReadWriteMany"
			dataSize:     *"1Gi" | string
			configSize:   *"1Gi" | string
		}
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
		}

		if config.mongodb.enabled {
			if config.mongodb.persistence.enabled {
				pvcMongo: #MongoPVC & {#config: config}
			}
			deployMongo: #MongoDeployment & {#config: config}
			svcMongo:    #MongoService & {#config:    config}
		}

		if config.caddy.enabled {
			cmCaddy: #CaddyConfigMap & {#config: config}
			if config.caddy.persistence.enabled {
				pvcCaddyData:   #CaddyDataPVC & {#config:   config}
				pvcCaddyConfig: #CaddyConfigPVC & {#config: config}
			}
			deployCaddy: #CaddyDeployment & {#config: config}
			svcCaddy:    #CaddyService & {#config:    config}
		}

		envSecret: #EnvSecret & {#config: config}
	}
}
