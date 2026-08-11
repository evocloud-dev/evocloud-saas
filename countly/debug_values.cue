@if(debug)

package main

// Values used by debug_tool.cue.
// Debug example 'cue cmd -t debug -t name=test -t namespace=test -t mv=1.0.0 -t kv=1.28.0 build'.
values: {
	nameOverride:     ""
	fullnameOverride: ""
	hostname:         "localhost"

	api: {
		image: {
			registry:   "docker.io"
			repository: "countly/api"
			tag:        "25.05.4"
			pullPolicy: "Always"
		}
		imagePullSecrets: []
		podAnnotations: {}
		podSecurityContext: {}
		priorityClassName:    ""
		replicaCount:         1
		revisionHistoryLimit: 10
		resources: {
			limits: {
				memory: "2Gi"
			}
			requests: {
				cpu:    "200m"
				memory: "400Mi"
			}
		}
		securityContext: {}
		serviceAccount: {
			create:      true
			annotations: {}
			name:        ""
		}
		service: {
			type: "ClusterIP"
			port: 3000
		}
		route: {
			main: {
				enabled:         false
				apiVersion:      "gateway.networking.k8s.io/v1"
				kind:            "HTTPRoute"
				annotations:     {}
				labels:          {}
				hostnames:       []
				parentRefs:      []
				matches: [
					{
						path: {
							type:  "PathPrefix"
							value: "/i"
						}
					},
					{
						path: {
							type:  "PathPrefix"
							value: "/i/*"
						}
					},
					{
						path: {
							type:  "PathPrefix"
							value: "/o"
						}
					},
					{
						path: {
							type:  "PathPrefix"
							value: "/o/*"
						}
					},
				]
				filters:         []
				additionalRules: []
				httpsRedirect:   false
				timeouts:        {}
			}
		}
		autoscaling: {
			enabled:                           false
			minReplicas:                       1
			maxReplicas:                       100
			targetCPUUtilizationPercentage:    80
			targetMemoryUtilizationPercentage: 80
		}
		livenessProbe: {
			failureThreshold:    6
			initialDelaySeconds: 60
			periodSeconds:       30
			successThreshold:    1
			timeoutSeconds:      2
		}
		readinessProbe: {
			failureThreshold:    6
			initialDelaySeconds: 60
			periodSeconds:       30
			successThreshold:    1
			timeoutSeconds:      2
		}
		nodeSelector: {}
		tolerations:  []
		affinity:     {}
		selectorLabels: {}
		extraEnv:     []
	}

	frontend: {
		image: {
			registry:   "docker.io"
			repository: "countly/frontend"
			tag:        "25.05.4"
			pullPolicy: "Always"
		}
		imagePullSecrets: []
		podAnnotations: {}
		podSecurityContext: {}
		priorityClassName:    ""
		replicaCount:         1
		revisionHistoryLimit: 10
		resources: {
			limits: {
				cpu:    "500m"
				memory: "500Mi"
			}
			requests: {
				cpu:    "100m"
				memory: "100Mi"
			}
		}
		securityContext: {}
		serviceAccount: {
			create:      true
			annotations: {}
			name:        ""
		}
		service: {
			type: "ClusterIP"
			port: 3000
		}
		route: {
			main: {
				enabled:         false
				apiVersion:      "gateway.networking.k8s.io/v1"
				kind:            "HTTPRoute"
				annotations:     {}
				labels:          {}
				hostnames:       []
				parentRefs:      []
				matches: [
					{
						path: {
							type:  "PathPrefix"
							value: "/"
						}
					},
					{
						path: {
							type:  "PathPrefix"
							value: "/images/"
						}
					},
				]
				filters:         []
				additionalRules: []
				httpsRedirect:   false
				timeouts:        {}
			}
		}
		autoscaling: {
			enabled:                           false
			minReplicas:                       1
			maxReplicas:                       100
			targetCPUUtilizationPercentage:    80
			targetMemoryUtilizationPercentage: 80
		}
		livenessProbe: {
			failureThreshold:    6
			initialDelaySeconds: 60
			periodSeconds:       30
			successThreshold:    1
			timeoutSeconds:      2
		}
		readinessProbe: {
			failureThreshold:    6
			initialDelaySeconds: 60
			periodSeconds:       30
			successThreshold:    1
			timeoutSeconds:      2
		}
		nodeSelector: {}
		tolerations:  []
		affinity:     {}
		selectorLabels: {}
		extraEnv:     []
	}

	extraEnv: []

	config: {
		api: {
			filestorage: "gridfs"
			mail: {
				enabled: false
				auth: {
					existingSecret: ""
					password:       ""
					username:       ""
				}
				from: ""
				host: ""
				port: 0
			}
			workerCount: "1"
		}
		nodeOptions: "--max-old-space-size=2048"
		plugins:     "mobile,web,desktop,plugins,density,locale,browser,sources,views,logger,systemlogs,populator,reports,crashes,push,star-rating,slipping-away-users,compare,server-stats,dbviewer,times-of-day,compliance-hub,alerts,onboarding,consolidate,remote-config,hooks,dashboards,sdk,data-manager,guides"
	}

	mongodb: {
		enabled:        true
		architecture:   "standalone"
		// WARNING: MongoDB versions are strictly incompatible with Linux kernel 
		// versions 6.19 through 7.0.13 due to an upstream TCMalloc bug clashing 
		// with CET Shadow Stack, resulting in an immediate startup crash loop.
		// SOLUTION: To fix this permanently on modern host systems without runtime hacks, 
		// we downgraded the image tag to MongoDB 7.0. Alternatively, the host Linux 
		// kernel can be upgraded to version 7.0.14 or later to resolve the bug natively.
		// OFFICIAL REFERENCE: https://www.mongodb.com/docs/manual/administration/production-notes/
		image: {
			registry:   "docker.io"
			repository: "library/mongo"
			tag:        "7.0"
			pullPolicy: "IfNotPresent"
		}
		auth: {
			enabled:  false
			database: "countly"
			password: "countly"
			username: "countly"
		}
		useStatefulSet: true
	}

	externalMongodb: {
		auth: {
			database: "countly"
		}
		hostname: ""
		port:     27017
	}
}
