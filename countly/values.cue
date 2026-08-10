// Reference: https://github.com/helmforgedev/charts/blob/main/charts/countly/values.yaml

@if(!debug)

package main

values: {
	nameOverride:     ""
	fullnameOverride: ""
	commonLabels: {}

	image: {
		repository: "docker.io/countly/countly-server"
		tag:        "25.05.4"
		pullPolicy: "IfNotPresent"
	}
	imagePullSecrets: []

	countly: {
		apiPort:       3001
		dashboardPort: 6001
		apiWorkers:    4
		timezone:      "UTC"
		plugins:       ""
		extraEnv: []
	}


	externalMongodb: {
		enabled:              false
		uri:                  ""
		existingSecret:       ""
		existingSecretUriKey: "mongodb-uri"
	}

	serviceAccount: {
		create: true
		name:   ""
		annotations: {}
	}

	service: {
		type:           "ClusterIP"
		port:           80
		apiPort:        3001
		annotations: {}
		ipFamilyPolicy: ""
		ipFamilies: []
	}

	ingress: {
		enabled:          false
		ingressClassName: "traefik"
		annotations: {}
		hosts:       []
		tls:         []
	}

	probes: {
		startup: {
			enabled:             true
			initialDelaySeconds: 20
			periodSeconds:       5
			timeoutSeconds:      3
			failureThreshold:    30
		}
		liveness: {
			enabled:             true
			initialDelaySeconds: 0
			periodSeconds:       15
			timeoutSeconds:      5
			failureThreshold:    3
		}
		readiness: {
			enabled:             true
			initialDelaySeconds: 0
			periodSeconds:       10
			timeoutSeconds:      5
			failureThreshold:    3
		}
	}

	resources: {
		requests: {
			cpu:    "200m"
			memory: "1Gi"
		}
		limits: {
			cpu:    "2000m"
			memory: "2Gi"
		}
	}
	podSecurityContext: {}
	securityContext: {
		capabilities: {
			drop: [
				"ALL",
			]
			add: [
				"CHOWN",
				"SETUID",
				"SETGID",
				"NET_BIND_SERVICE",
				"DAC_OVERRIDE",
				"SYS_CHROOT",
			]
		}
	}

	backup: {
		enabled:                    false
		schedule:                   "0 3 * * *"
		suspend:                    false
		concurrencyPolicy:          "Forbid"
		successfulJobsHistoryLimit: 3
		failedJobsHistoryLimit:     3
		backoffLimit:               1
		archivePrefix:              "countly"
		images: {
			mongodb:  "docker.io/library/mongo:7.0"
			uploader: "docker.io/helmforge/mc:1.0.0"
		}
		resources: {}
		s3: {
			endpoint:                       ""
			bucket:                         ""
			prefix:                         "countly"
			createBucketIfNotExists:        true
			existingSecret:                 ""
			existingSecretAccessKeyKey:     "access-key"
			existingSecretSecretKeyKey:     "secret-key"
			accessKey:                      ""
			secretKey:                      ""
		}
		database: {
			uri:          ""
			mongodumpArgs: ""
		}
	}

	nodeSelector: {}
	tolerations:  []
	affinity: {}
	topologySpreadConstraints: []
	priorityClassName:             ""
	terminationGracePeriodSeconds: 30
	podLabels: {}
	podAnnotations: {
		"seccomp.security.alpha.kubernetes.io/pod": "runtime/default"
	}

	extraVolumes: []
	extraVolumeMounts: []
	extraManifests: []

	mongodb: {
		enabled:          true
		architecture:     "standalone"
		// WARNING: MongoDB versions are strictly incompatible with Linux kernel 
	    // versions 6.19 through 7.0.13 due to an upstream TCMalloc bug clashing 
	    // with CET Shadow Stack, resulting in an immediate startup crash loop.
        // SOLUTION: To fix this permanently on modern host systems without runtime hacks, 
	    // we downgraded the image tag to MongoDB 7.0. Alternatively, the host Linux 
	    // kernel can be upgraded to version 7.0.14 or later to resolve the bug natively.
	    // OFFICIAL REFERENCE: https://www.mongodb.com/docs/manual/administration/production-notes/
		image: {
			repository: "docker.io/library/mongo"
			tag:        "7.0"
			pullPolicy: "IfNotPresent"
		}
		auth: {
			enabled:           true
			rootUser:          "root"
			rootPassword:      ""
		}
		podSecurityContext: {
			runAsUser:           65510
			runAsGroup:          65510
			fsGroup:             65510
		}
		securityContext: {
			capabilities: {
				drop: [
					"ALL",
				]
			}
		}
		resources: {
			limits: {
				cpu:    "1000m"
				memory: "2Gi"
			}
			requests: {
				cpu:    "100m"
				memory: "512Mi"
			}
		}
	}

	gateway: {
		enabled: true
		hostnames: []
		parentRefs: []
	}
	externalSecrets: {
		enabled:         false
		apiVersion:      "external-secrets.io/v1"
		refreshInterval: "0"
		secretStoreRef: {
			name: ""
			kind: "ClusterSecretStore"
		}
		target: {
			creationPolicy: "Owner"
		}
		data: []
	}
}
