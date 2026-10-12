@if(debug)

package main

// Values used by debug_tool.cue.
// Debug example 'cue cmd -t debug -t name=test -t namespace=test -t mv=1.0.6 -t kv=1.28.0 build'.
values: {
	nameOverride:     ""
	fullnameOverride: ""
	commonLabels: {}
	annotations: {}
	podLabels: {}
	podAnnotations: {
		"cluster-autoscaler.kubernetes.io/safe-to-evict": "true"
	}

	hub: {
		replicaCount: 1
		image: {
			repository: "quay.io/jupyterhub/k8s-hub"
			tag:        "4.4.2"
			digest:     ""
		}
		baseUrl: "/"
		dbPath:  "/srv/jupyterhub/jupyterhub.sqlite"
		cookieSecret: {
			existingSecret:    ""
			existingSecretKey: "cookie-secret"
			fileName:          "jupyterhub_cookie_secret"
		}
		logLevel:       "INFO"
		cleanupServers: false
		extraConfig:    ""
		persistence: {
			enabled:       true
			existingClaim: ""
			storageClass:  ""
			accessModes:   *["ReadWriteOnce"] | [...string]
			size:          "10Gi"
		}
		resources: {
			requests: {
				cpu:    "100m"
				memory: "256Mi"
			}
			limits: {
				cpu:    "1000m"
				memory: "1Gi"
			}
		}
	}

	proxy: {
		image: {
			repository: "docker.io/jupyterhub/configurable-http-proxy"
			tag:        "5.3.0"
			digest:     ""
		}
		secretToken:            "41208fbba9f3e4ca1701e6b8c8d8b9e4a3c2d1e0f7b6a5c4d3e2f1a0b9c8d7e6"
		existingSecret:         ""
		existingSecretTokenKey: "proxy-token"
		logLevel:               "warn"
		bind: {
			ip:    ""
			apiIp: ""
		}
		resources: {
			requests: {
				cpu:    "50m"
				memory: "128Mi"
			}
			limits: {
				cpu:    "500m"
				memory: "512Mi"
			}
		}
	}

	auth: {
		type:               "dummy"
		dummyPassword:      ""
		allowInsecureDummy: false
	}

	singleuser: {
		image: {
			name:       "quay.io/jupyter/base-notebook"
			tag:        "2026-10-05"
			pullPolicy: "IfNotPresent"
		}
		cpu: {
			guarantee: 0.1
			limit:     1
		}
		memory: {
			guarantee: "512M"
			limit:     "2G"
		}
		storage: {
			enabled:      false
			capacity:     "10Gi"
			storageClass: ""
			accessModes:  *["ReadWriteOnce"] | [...string]
		}
		startTimeout: 300
		defaultUrl:   "/lab"
		profiles:     *[] | [...]
	}

	imagePullSecrets: *[] | [...]

	service: {
		type:         "ClusterIP"
		annotations: {}
		port:         80
		proxyApiPort: 8001
		ipFamilies:   *[] | [...string]
	}

	gateway: {
		enabled:      false
		apiVersion:   "gateway.networking.k8s.io/v1"
		parentRefs:   *[] | [...]
		hostnames:    *[] | [...string]
		annotations:  {}
		labels:       {}
		rules: *[{
			matches: [{
				path: {
					type:  "PathPrefix"
					value: "/"
				}
			}]
		}] | [...]
	}

	serviceAccount: {
		create:       true
		name:         ""
		annotations:  {}
	}

	rbac: create: true

	metrics: {
		authenticatePrometheus:               true
		allowPublicUnauthenticatedPrometheus: false
		serviceMonitor: {
			enabled:  false
			interval: "30s"
			labels:   {}
		}
	}

	podSecurityContext: {
		fsGroup:             1000
		fsGroupChangePolicy: "OnRootMismatch"
		seccompProfile: type: "RuntimeDefault"
	}

	securityContext: {
		runAsUser:                1000
		runAsGroup:               1000
		runAsNonRoot:             true
		allowPrivilegeEscalation: false
		readOnlyRootFilesystem:   true
		capabilities: drop: *["ALL"] | [...string]
	}

	livenessProbe: {
		initialDelaySeconds: 30
		periodSeconds:       20
		timeoutSeconds:      5
		failureThreshold:    6
	}

	readinessProbe: {
		initialDelaySeconds: 10
		periodSeconds:       10
		timeoutSeconds:      5
		failureThreshold:    6
	}

	startupProbe: {
		initialDelaySeconds: 30
		periodSeconds:       10
		timeoutSeconds:      5
		failureThreshold:    60
	}

	nodeSelector:                  {}
	tolerations:                   *[] | [...]
	affinity:                      {}
	topologySpreadConstraints:     *[] | [...]
	priorityClassName:             ""
	terminationGracePeriodSeconds: 30

	pdb: {
		enabled:      false
		minAvailable: 1
	}

	extraEnv:           *[] | [...]
	extraVolumes:       *[] | [...]
	extraVolumeMounts:  *[] | [...]
	extraManifests:     *[] | [...]

	externalSecrets: {
		enabled:         false
		apiVersion:      "external-secrets.io/v1"
		refreshInterval: "0"
		secretStoreRef: {
			name: ""
			kind: "SecretStore"
		}
		target: creationPolicy: "Owner"
		data:     *[] | [...]
		dataFrom: *[] | [...]
	}
}
