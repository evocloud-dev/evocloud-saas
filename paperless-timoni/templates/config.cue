package templates

import (
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Config defines the schema and defaults for the Instance values.
#Config: {
	// The kubeVersion is a required field, set at apply-time
	// via timoni.cue by querying the user's Kubernetes API.
	kubeVersion!: string
	// Using the kubeVersion you can enforce a minimum Kubernetes minor version.
	// By default, the minimum Kubernetes version is set to 1.22.
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.22.0"}

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

	// The service values mirror the upstream Helm chart values.
	service: {
		main: ports: http: port: *8000 | int & >0 & <=65535
	}

	// The ingress values mirror the upstream Helm chart values and common defaults.
	ingress: {
		main: {
			enabled: *false | bool
			primary: *true | bool
			nameOverride?: string
			annotations: *{} | {[string]: string}
			labels:      *{} | {[string]: string}
			ingressClassName: *"" | string
			hosts: *[
				{
					host: "chart-example.local"
					paths: [{
						path:     *"/" | string
						pathType: *"Prefix" | "Exact" | "ImplementationSpecific"
						service: *{} | {
							name: *"" | string
							port: *0 | int & >=0 & <=65535
						}
					}]
				},
			] | [...{
				host: string
				paths: [...{
					path:     *"/" | string
					pathType: *"Prefix" | "Exact" | "ImplementationSpecific"
					service: *{} | {
						name: *"" | string
						port: *0 | int & >=0 & <=65535
					}
				}]
			}]
			tls: *[] | [...{
				secretName?: string
				hosts: [...string]
			}]
		}
	}

	// Environment variables passed to the Paperless container.
	env: *{} | {[string]: null | string | bool | int | number}

	// Security context applied to the Paperless container and pod.
	securityContext: {
		runAsUser?:             int
		runAsGroup?:            int
		fsGroup?:               int
		runAsNonRoot?:          bool
		readOnlyRootFilesystem: *false | bool
		capabilities: {
			drop: *[] | [...string]
			add:  *[] | [...string]
		}
	}

	// Resources applied to the Paperless container.
	resources: {
		requests: {
			cpu:    *"100m" | string
			memory: *"256Mi" | string
		}
		limits: {
			cpu:    *"1000m" | string
			memory: *"1Gi" | string
		}
	}

	// Persistence mirrors the upstream Helm chart's volume options.
	persistence: {
		data: {
			enabled:    *false | bool
			retain:     *true | bool
			mountPath:  *"/usr/src/paperless/data" | string
			storageClass?: string
			accessMode: *"ReadWriteOnce" | string
			size:       *"1Gi" | string
			emptyDir: enabled: *false | bool
		}
		media: {
			enabled:    *false | bool
			retain:     *true | bool
			mountPath:  *"/usr/src/paperless/media" | string
			storageClass?: string
			accessMode: *"ReadWriteOnce" | string
			size:       *"8Gi" | string
			emptyDir: enabled: *false | bool
		}
		export: {
			enabled:    *true | bool
			retain:     *true | bool
			mountPath:  *"/usr/src/paperless/export" | string
			storageClass?: string
			accessMode: *"ReadWriteOnce" | string
			size:       *"1Gi" | string
			emptyDir: enabled: *false | bool
		}
		consume: {
			enabled:    *true | bool
			retain:     *true | bool
			mountPath:  *"/usr/src/paperless/consume" | string
			storageClass?: string
			accessMode: *"ReadWriteOnce" | string
			size:       *"4Gi" | string
			emptyDir: enabled: *false | bool
		}
	}

	postgresql: {
		enabled: *false | bool
		image: {
			repository: *"docker.io/postgres" | string
			tag:        *"16-alpine" | string
			pullPolicy: *"IfNotPresent" | string
		}
		auth: {
			database:         *"paperless" | string
			username:         *"postgres" | string
			postgresPassword: *"changeme" | string
			existingSecret?: string
			password?: string
		}
		primary: {
			persistence: {
				enabled: *false | bool
				retain:  *true | bool
				storageClass?: string
				accessMode: *"ReadWriteOnce" | string
				size:       *"8Gi" | string
			}
			resources: {
				requests: {
					cpu:    *"100m" | string
					memory: *"256Mi" | string
				}
				limits: {
					cpu:    *"1000m" | string
					memory: *"1Gi" | string
				}
			}
		}
	}

	mariadb: {
		enabled: *false | bool
		auth: {
			database:     *"paperless" | string
			username:     *"paperless" | string
			password:     *"changeme" | string
			rootPassword: *"changeme" | string
			existingSecret?: string
		}
	}

	redis: {
		enabled: *true | bool
		image: {
			repository: *"docker.io/redis" | string
			tag:        *"7-alpine" | string
			pullPolicy: *"IfNotPresent" | string
		}
		auth: {
			enabled:                   *true | bool
			username:                  *"" | string
			password:                  *"changeme" | string
			existingSecret?:           string
			existingSecretPasswordKey: *"redis-password" | string
		}
		master: {
			persistence: {
				enabled: *false | bool
				retain:  *true | bool
				storageClass?: string
				accessMode: *"ReadWriteOnce" | string
				size:       *"8Gi" | string
			}
			resources: {
				requests: {
					cpu:    *"50m" | string
					memory: *"64Mi" | string
				}
				limits: {
					cpu:    *"250m" | string
					memory: *"256Mi" | string
				}
			}
		}
		replica: replicaCount: *0 | int
	}
	test: {
		enabled: bool | *false
	}
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		svc: #Service & {#config: config}
		deploy: #Deployment & {#config: config}
		if config.ingress.main.enabled {
			ingress: #Ingress & {#config: config}
		}
		if config.persistence.data.enabled && !config.persistence.data.emptyDir.enabled {
			pvcData: #PersistentVolumeClaim & {#config: config, #volumeName: "data"}
		}
		if config.persistence.media.enabled && !config.persistence.media.emptyDir.enabled {
			pvcMedia: #PersistentVolumeClaim & {#config: config, #volumeName: "media"}
		}
		if config.persistence.consume.enabled && !config.persistence.consume.emptyDir.enabled {
			pvcConsume: #PersistentVolumeClaim & {#config: config, #volumeName: "consume"}
		}
		if config.persistence.export.enabled && !config.persistence.export.emptyDir.enabled {
			pvcExport: #PersistentVolumeClaim & {#config: config, #volumeName: "export"}
		}
		if config.redis.enabled {
			if config.redis.auth.existingSecret == _|_ {
				redisSecret: #RedisSecret & {#config: config}
			}
			redisSvc:         #RedisService & {#config: config}
			redisHeadlessSvc: #RedisHeadlessService & {#config: config}
			redisDeploy:      #RedisDeployment & {#config: config}
			if config.redis.master.persistence.enabled {
				redisPVC: #RedisPersistentVolumeClaim & {#config: config}
			}
		}
		if config.postgresql.enabled {
			if config.postgresql.auth.existingSecret == _|_ {
				postgresqlSecret: #PostgreSQLSecret & {#config: config}
			}
			postgresqlSvc:         #PostgreSQLService & {#config: config}
			postgresqlHeadlessSvc: #PostgreSQLHeadlessService & {#config: config}
			postgresqlDeploy:      #PostgreSQLDeployment & {#config: config}
			if config.postgresql.primary.persistence.enabled {
				postgresqlPVC: #PostgreSQLPersistentVolumeClaim & {#config: config}
			}
		}
	}
}