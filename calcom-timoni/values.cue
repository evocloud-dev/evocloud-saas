// Reference: https://github.com/Pyrrha/calcom-helm/blob/main/charts/calcom/values.yaml
package main

// Values defines the user-supplied values for the Cal.com instance.
values: {
	replicaCount: 1

	image: {
		repository: "calcom/cal.com"
		tag:        "v6.2.0"
		pullPolicy: "IfNotPresent"
	}

	imagePullSecrets: []
	nameOverride:     ""
	fullnameOverride: ""

	podAnnotations: {}

	podSecurityContext: {}

	securityContext: {
		runAsUser:              10001 
		runAsGroup:             10001 
		runAsNonRoot:           true
		readOnlyRootFilesystem: true 
		capabilities: {
			drop: ["ALL"] 
		}
	}

	secretRef: ""

	secret: {
		enabled: true
		data: {
			DATABASE_URL:            "postgresql://user:password@postgresql:5432/calcom"
			NEXT_PUBLIC_WEBAPP_URL:  "http://localhost:3000"
			NEXTAUTH_SECRET:         "changeme"
			CALENDSO_ENCRYPTION_KEY: "changeme"
		    AB_TEST_BUCKET_PROBABILITY: "0" 
		}
	}

	postgresql: {
		enabled: true
		image: {
			repository: "postgres"
			tag:        "18-alpine"
			pullPolicy: "IfNotPresent"
		}
		auth: {
			username: "user"
			password: "password"
			database: "calcom"
		}
		storage: {
			size:         "10Gi"
			storageClass: "standard"
		}
		resources: {
			requests: {
				cpu:    "100m" 
				memory: "256Mi" 
			}
			limits: {
				cpu:    "500m" 
				memory: "512Mi"
			}
		}
	}

	service: main: {
		type: "ClusterIP"
		ports: http: port: 3000
	}

	ingress: main: {
		enabled: false
		className: ""
		annotations: {}
		hosts: [
			{
				host: "example.org"
				paths: [
					{
						path:     "/"
						pathType: "ImplementationSpecific"
					},
				]
			},
		]
		tls: []
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

	autoscaling: {
		enabled:                           true
		minReplicas:                       1
		maxReplicas:                       10
		targetCPUUtilizationPercentage:    80
		targetMemoryUtilizationPercentage: 80
	}

	nodeSelector: {}

	tolerations: []

	affinity: {}
}