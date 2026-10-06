package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#Deployment: appsv1.#Deployment & {
	#config:          #Config
	#saName:          string
	#pvcName:         string
	#bootstrapSecret: string
	#identitySecret:  string
	#dbHost:          string
	#dbSecret:        string
	#dbKey:           string

	_publicUrl: [
		if #config.server.publicUrl != "" {#config.server.publicUrl},
		"http://\(#config.metadata.name).\(#config.metadata.namespace).svc:\(#config.service.port)",
	][0]

	_dbPort: [
		if #config.postgresql.enabled {"\(#config.postgresql.service.port)"},
		"\(#config.database.port)",
	][0]

	_dbName: [
		if #config.postgresql.enabled {#config.postgresql.auth.database},
		#config.database.name,
	][0]

	_dbUser: [
		if #config.postgresql.enabled {#config.postgresql.auth.username},
		#config.database.username,
	][0]

	_dbTls: "\(!#config.postgresql.enabled && #config.database.tls.enabled)"

	_commonEnv: [
		{name: "NODE_ENV", value: "production"},
		{name: "HOME", value: "/tmp"},
		{name: "APP_URL", value: _publicUrl},
		if #config.oauth.enabled {
			name:  "OAUTH_PROVIDER_NAME"
			value: #config.oauth.name
		},
		if #config.oauth.enabled {
			name:  "OAUTH_CLIENT_ID"
			value: #config.oauth.clientId
		},
		if #config.oauth.enabled {
			name:  "OAUTH_AUTHORIZATION_URL"
			value: #config.oauth.authorizationUrl
		},
		if #config.oauth.enabled {
			name:  "OAUTH_TOKEN_URL"
			value: #config.oauth.tokenUrl
		},
		if #config.oauth.enabled {
			name:  "OAUTH_USER_INFO_URL"
			value: #config.oauth.userInfoUrl
		},
		if #config.oauth.enabled {
			name:  "OAUTH_SCOPES"
			value: #config.oauth.scopes
		},
		if #config.oauth.enabled {
			name: "OAUTH_CLIENT_SECRET"
			valueFrom: secretKeyRef: {
				name: #config.oauth.existingSecret
				key:  #config.oauth.clientSecretKey
			}
		},
		if #config.oauth.enabled && #config.oauth.caSecret != "" {
			name:  "HF_OAUTH_CA"
			value: "/oauth-ca/ca.crt"
		},
		if #config.storage.driver == "s3" {
			name:  "S3_BUCKET"
			value: #config.storage.s3.bucket
		},
		if #config.storage.driver == "s3" {
			name:  "S3_REGION"
			value: #config.storage.s3.region
		},
		if #config.storage.driver == "s3" {
			name:  "S3_FORCE_PATH_STYLE"
			value: "\(#config.storage.s3.forcePathStyle)"
		},
		if #config.storage.driver == "s3" && #config.storage.s3.endpoint != "" {
			name:  "S3_ENDPOINT"
			value: #config.storage.s3.endpoint
		},
		if #config.storage.driver == "s3" {
			name: "S3_ACCESS_KEY_ID"
			valueFrom: secretKeyRef: {
				name: #config.storage.s3.existingSecret
				key:  #config.storage.s3.accessKeyIdKey
			}
		},
		if #config.storage.driver == "s3" {
			name: "S3_SECRET_ACCESS_KEY"
			valueFrom: secretKeyRef: {
				name: #config.storage.s3.existingSecret
				key:  #config.storage.s3.secretAccessKeyKey
			}
		},
		if #config.storage.driver == "s3" && #config.storage.s3.caSecret != "" {
			name:  "HF_S3_CA"
			value: "/s3-ca/ca.crt"
		},
		{name: "HF_DATABASE_HOST", value: #dbHost},
		{name: "HF_DATABASE_PORT", value: _dbPort},
		{name: "HF_DATABASE_NAME", value: _dbName},
		{name: "HF_DATABASE_USERNAME", value: _dbUser},
		{name: "HF_DATABASE_TLS", value: _dbTls},
		{
			name: "HF_DATABASE_PASSWORD"
			valueFrom: secretKeyRef: {
				name: #dbSecret
				key:  #dbKey
			}
		},
		if !#config.postgresql.enabled && #config.database.tls.caSecret != "" {
			name:  "HF_DATABASE_CA"
			value: "/postgres-ca/ca.crt"
		},
		{
			name: "AUTH_SECRET"
			valueFrom: secretKeyRef: {
				name: #identitySecret
				key:  "AUTH_SECRET"
			}
		},
		{
			name: "ENCRYPTION_SECRET"
			valueFrom: secretKeyRef: {
				name: #identitySecret
				key:  "ENCRYPTION_SECRET"
			}
		},
		if #config.smtp.enabled {
			name:  "SMTP_HOST"
			value: #config.smtp.host
		},
		if #config.smtp.enabled {
			name:  "SMTP_PORT"
			value: "\(#config.smtp.port)"
		},
		if #config.smtp.enabled {
			name:  "SMTP_FROM"
			value: #config.smtp.from
		},
		if #config.smtp.enabled {
			name:  "SMTP_USER"
			value: #config.smtp.username
		},
		if #config.smtp.enabled {
			name:  "SMTP_SECURE"
			value: "true"
		},
		if #config.smtp.enabled {
			name: "SMTP_PASS"
			valueFrom: secretKeyRef: {
				name: #config.smtp.existingSecret
				key:  #config.smtp.passwordKey
			}
		},
		if #config.smtp.enabled && #config.smtp.tls.caSecret != "" {
			name:  "HF_SMTP_CA"
			value: "/smtp-ca/ca.crt"
		},
		for e in #config.extraEnv {e},
	]

	_commonMounts: [
		{name: "data", mountPath: "/app/data"},
		{name: "tmp", mountPath: "/tmp"},
		{name: "runtime", mountPath: "/helmforge", readOnly: true},
		if #config.oauth.enabled && #config.oauth.caSecret != "" {
			name:      "oauth-ca"
			mountPath: "/oauth-ca"
			readOnly:  true
		},
		if #config.storage.driver == "s3" && #config.storage.s3.caSecret != "" {
			name:      "s3-ca"
			mountPath: "/s3-ca"
			readOnly:  true
		},
		if #config.smtp.enabled && #config.smtp.tls.caSecret != "" {
			name:      "smtp-ca"
			mountPath: "/smtp-ca"
			readOnly:  true
		},
		if !#config.postgresql.enabled && #config.database.tls.caSecret != "" {
			name:      "postgres-ca"
			mountPath: "/postgres-ca"
			readOnly:  true
		},
	]

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata:   #config.metadata
	spec: appsv1.#DeploymentSpec & {
		replicas: #config.replicaCount
		strategy: type: "Recreate"
		selector: matchLabels: #config.selector.labels
		template: {
			metadata: {
				labels: #config.selector.labels
				if len(#config.podLabels) > 0 {
					labels: #config.podLabels
				}
				if len(#config.podAnnotations) > 0 {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:            #saName
				automountServiceAccountToken:  false
				securityContext:               #config.podSecurityContext
				terminationGracePeriodSeconds: #config.terminationGracePeriodSeconds
				if len(#config.imagePullSecrets) > 0 {
					imagePullSecrets: #config.imagePullSecrets
				}
				if len(#config.nodeSelector) > 0 {
					nodeSelector: #config.nodeSelector
				}
				if len(#config.tolerations) > 0 {
					tolerations: #config.tolerations
				}
				if #config.affinity != _|_ {
					affinity: #config.affinity
				}
				if len(#config.topologySpreadConstraints) > 0 {
					topologySpreadConstraints: #config.topologySpreadConstraints
				}
				if #config.priorityClassName != "" {
					priorityClassName: #config.priorityClassName
				}
				initContainers: [
					{
						name:            "bootstrap"
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						command: ["node", "/helmforge/launcher.mjs", "bootstrap"]
						env: [
							for e in _commonEnv {e},
							{name: "HF_INITIAL_EMAIL", value: #config.bootstrap.email},
							{name: "HF_INITIAL_NAME", value: #config.bootstrap.name},
							{name: "HF_INITIAL_USERNAME", value: #config.bootstrap.username},
							{name: "HF_ADMISSION_HOST", value: "\(#config.metadata.name)-admission"},
						]
						securityContext: #config.securityContext
						resources:       #config.resources
						volumeMounts: [
							for m in _commonMounts {m},
							{name: "bootstrap-auth", mountPath: "/bootstrap-auth", readOnly: true},
							{name: "admission-key", mountPath: "/admission-key", readOnly: true},
						]
					},
				]
				containers: [
					{
						name:            "reactive-resume"
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						command: ["node", "/helmforge/launcher.mjs", "server"]
						env:             _commonEnv
						securityContext: #config.securityContext
						resources:       #config.resources
						ports: [
							{
								name:          "native"
								containerPort: 3010
							},
						]
						startupProbe: {
							httpGet: {
								path: "/api/health"
								port: "native"
							}
							periodSeconds:    #config.probes.startup.periodSeconds
							timeoutSeconds:   #config.probes.startup.timeoutSeconds
							failureThreshold: #config.probes.startup.failureThreshold
						}
						readinessProbe: {
							httpGet: {
								path: "/api/health"
								port: "native"
							}
							periodSeconds:    #config.probes.readiness.periodSeconds
							timeoutSeconds:   #config.probes.readiness.timeoutSeconds
							failureThreshold: #config.probes.readiness.failureThreshold
						}
						livenessProbe: {
							tcpSocket: port: "native"
							periodSeconds:    #config.probes.liveness.periodSeconds
							timeoutSeconds:   #config.probes.liveness.timeoutSeconds
							failureThreshold: #config.probes.liveness.failureThreshold
						}
						volumeMounts: _commonMounts
					},
					{
						name:            "proxy"
						image:           #config.proxy.image.reference
						imagePullPolicy: #config.proxy.image.pullPolicy
						command: ["nginx", "-g", "daemon off;", "-c", "/helmforge/nginx.conf"]
						securityContext: #config.securityContext
						resources:       #config.proxy.resources
						ports: [
							{
								name:          "http"
								containerPort: 3000
							},
						]
						readinessProbe: {
							httpGet: {
								path: "/_proxyhealth"
								port: "http"
							}
						}
						livenessProbe: {
							httpGet: {
								path: "/_proxyhealth"
								port: "http"
							}
						}
						volumeMounts: [
							{
								name:      "runtime"
								mountPath: "/helmforge"
								readOnly:  true
							},
							{
								name:      "proxy-tmp"
								mountPath: "/tmp"
							},
						]
					},
				]
				volumes: [
					if #config.oauth.enabled && #config.oauth.caSecret != "" {
						name: "oauth-ca"
						secret: {
							secretName: #config.oauth.caSecret
							items: [{key: #config.oauth.caKey, path: "ca.crt"}]
						}
					},
					if #config.storage.driver == "s3" && #config.storage.s3.caSecret != "" {
						name: "s3-ca"
						secret: {
							secretName: #config.storage.s3.caSecret
							items: [{key: #config.storage.s3.caKey, path: "ca.crt"}]
						}
					},
					if #config.smtp.enabled && #config.smtp.tls.caSecret != "" {
						name: "smtp-ca"
						secret: {
							secretName: #config.smtp.tls.caSecret
							items: [{key: #config.smtp.tls.caKey, path: "ca.crt"}]
						}
					},
					{
						name: "data"
						persistentVolumeClaim: claimName: #pvcName
					},
					{
						name: "tmp"
						emptyDir: sizeLimit: #config.runtime.temporarySize
					},
					{
						name: "proxy-tmp"
						emptyDir: sizeLimit: "128Mi"
					},
					{
						name: "runtime"
						configMap: name: "\(#config.metadata.name)-runtime"
					},
					{
						name: "bootstrap-auth"
						secret: {
							secretName:  #bootstrapSecret
							defaultMode: 0o440
							items: [{key: #config.bootstrap.passwordKey, path: "password"}]
						}
					},
					{
						name: "admission-key"
						secret: {
							secretName: [
								if #config.admission.existingSecret != "" {#config.admission.existingSecret},
								"\(#config.metadata.name)-admission",
							][0]
							defaultMode: 0o440
						}
					},
					if !#config.postgresql.enabled && #config.database.tls.caSecret != "" {
						name: "postgres-ca"
						secret: {
							secretName: #config.database.tls.caSecret
							items: [{key: #config.database.tls.caKey, path: "ca.crt"}]
						}
					},
				]
			}
		}
	}
}
