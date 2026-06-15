package templates

import timoniv1 "timoni.sh/core/v1alpha1"

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

	// The image values mirror the upstream Helm chart values.
	image: {
		repository: string
		tag:        string
		pullPolicy: *"IfNotPresent" | string
	}


	resources: {
		requests: {
			cpu: *"200m" | string
			memory: *"256Mi" | string
		}
		limits: {
			cpu:  *"500m" | string
		    memory: *"512Mi" | string
		}
	}

	// The service values mirror the upstream Helm chart values.
	service: {
		main: ports: http: port: *8000 | int & >0 & <=65535
	}

	// The ingress values mirror the upstream Helm chart values.
	ingress: {
		main: enabled: *false | bool
	}

	// Environment variables passed to the Readeck container.
	env: *{} | {[string]: string}

	securityContext: {
		runAsUser:             *"1000" | int
		runAsGroup:            *"1000" | int
		fsGroup:               *1000 | int
	    runAsNonRoot:          *true | bool
		readOnlyRootFilesystem: *true | bool
		capabilities: {
			drop: ["ALL"]
		}
	}


	// Persistence mirrors the upstream Helm chart's volume options.
	persistence: {
		data: {
			enabled:   *true | bool
			mountPath: *"/readeck" | string
			accessMode: "ReadWriteOnce"
			size:      *"100Mi" | string
			emptyDir: enabled: false
		}
	}

	test: {
		enabled: bool | *false
	}
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		svc:    #Service & {#config: config}
		deploy: #Deployment & {#config: config}
		if config.persistence.data.enabled {
			pvc: #PersistentVolumeClaim & {#config: config}
		}
	}

	test: {}
}