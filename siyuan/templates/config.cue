package templates

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#Config: {
	// The kubeVersion is set at apply-time by Timoni
	kubeVersion!: string
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.26.0"}

	// The moduleVersion is set from the user-supplied module version
	moduleVersion!: string

	// Common metadata
	metadata: timoniv1.#Metadata & {#Version: moduleVersion}

	// Labels applied to all resources
	metadata: labels: timoniv1.#Labels & {
		"app.kubernetes.io/part-of": "helmforge"
		for k, v in commonLabels {
			(k): v
		}
	}

	// Annotations applied to all resources
	metadata: annotations?: timoniv1.#Annotations

	// Selector labels
	selector: timoniv1.#Selector & {#Name: metadata.name}

	// -- Override the chart name used in resource names.
	nameOverride: *"" | string

	// -- Override the complete resource name.
	fullnameOverride: *"" | string

	// -- Extra resource labels; selector labels are reserved.
	commonLabels: *{} | {[!~"^(app\\.kubernetes\\.io/name|app\\.kubernetes\\.io/instance)$"]: string}

	// -- Exactly one writer per workspace, including RWX volumes.
	replicaCount: *1 | 1
	replicas:     replicaCount

	// -- Image.
	image!: timoniv1.#Image

	// -- Registry credentials for a private mirror.
	imagePullSecrets: *[] | [...timoniv1.#ObjectReference]

	// -- Auth.
	auth: {
		// -- Native administrative access code. Empty generates and retains 32 random alphanumeric characters.
		accessCode: *"" | string
		// -- Existing access-code Secret; do not combine with an inline code.
		existingSecret: *"" | string
		// -- Key containing the native access code, distinct from an API token.
		accessCodeKey: *"access-code" | string
	}

	// Derived auth secret name
	authSecretName: string
	if auth.existingSecret != "" {
		authSecretName: auth.existingSecret
	}
	if auth.existingSecret == "" {
		authSecretName: "\(metadata.name)-auth"
	}

	// -- Native kernel HTTP listener.
	server: {
		// -- Container listen port; Service and probes follow this value.
		port: *6806 | int & >0 & <=65535
	}

	// -- Additional environment entries; chart-managed security variables cannot be overridden.
	extraEnv: *[] | [...corev1.#EnvVar & {
		name: string & !~"^(SIYUAN_ACCESS_AUTH_CODE.*|SIYUAN_OIDC_.*|HOME|RUN_IN_CONTAINER|SIYUAN_WORKSPACE_PATH)$"
	}]

	// -- Additional envFrom Secret/ConfigMap references.
	envFrom: *[] | [...corev1.#EnvFromSource]

	// -- Service Account.
	serviceAccount: {
		// -- Create a dedicated ServiceAccount with no API permissions.
		create: *true | bool
		// -- Existing or overridden ServiceAccount name.
		name: *"" | string
		// -- ServiceAccount annotations.
		annotations?: timoniv1.#Annotations
		// -- Automount Service Account Token.
		automountServiceAccountToken: *false | bool
	}

	// Derived service account name
	serviceAccountName: string
	if serviceAccount.create {
		if serviceAccount.name != "" {
			serviceAccountName: serviceAccount.name
		}
		if serviceAccount.name == "" {
			serviceAccountName: metadata.name
		}
	}
	if !serviceAccount.create {
		if serviceAccount.name != "" {
			serviceAccountName: serviceAccount.name
		}
		if serviceAccount.name == "" {
			serviceAccountName: "default"
		}
	}

	// -- Service.
	service: {
		// -- Kubernetes Service type.
		type: *"ClusterIP" | "NodePort" | "LoadBalancer"
		// -- Service HTTP port.
		port: *6806 | int & >0 & <=65535
		// -- Service annotations.
		annotations?: timoniv1.#Annotations
		// -- Service IP family policy; empty uses cluster default.
		ipFamilyPolicy: *"" | "SingleStack" | "PreferDualStack" | "RequireDualStack"
		// -- Requested address families; RequireDualStack needs a dual-stack cluster.
		ipFamilies: *[] | [...string]
	}

	// -- Gateway.
	gatewayAPI: {
		// -- Render canonical Gateway API HTTPRoutes.
		enabled: *false | bool
		// -- GatewayClass name.
		gatewayClassName: *"" | string
		// -- Route definitions with parentRefs, hostnames, rules, labels and annotations.
		httpRoutes: *[...] | [...{
			name?:        string
			labels?:      timoniv1.#Labels
			annotations?: timoniv1.#Annotations
			parentRefs!:  [...]
			hostnames?:   [...string]
			rules?:       [...]
		}]
	}

	// -- External Secrets.
	externalSecrets: {
		// -- Enabled.
		enabled: *false | bool
		// -- Default operator refresh interval.
		refreshInterval: *"1h" | string
		// -- Items.
		items: *[...] | [...]
	}

	// -- Probes.
	probes: {
		// -- Wait for native kernel boot completion before liveness starts.
		startup: #ProbeConfig & {
			// -- Enabled.
			enabled: *true | bool
			// -- Path.
			path: *"/api/system/bootProgress" | string
			// -- Require native boot progress 100 before startup/readiness succeeds.
			requireBootComplete: *true | bool
			// -- Period Seconds.
			periodSeconds: *5 | (int & >0)
			// -- Timeout Seconds.
			timeoutSeconds: *2 | (int & >0)
			// -- Failure Threshold.
			failureThreshold: *60 | (int & >0)
		}
		// -- Check local HTTP availability without requiring external services.
		liveness: #ProbeConfig & {
			// -- Enabled.
			enabled: *true | bool
			// -- Path.
			path: *"/api/system/version" | string
			// -- Require native boot progress 100 before startup/readiness succeeds.
			requireBootComplete: *false | bool
			// -- Period Seconds.
			periodSeconds: *20 | (int & >0)
			// -- Timeout Seconds.
			timeoutSeconds: *3 | (int & >0)
			// -- Failure Threshold.
			failureThreshold: *3 | (int & >0)
		}
		// -- Require complete kernel initialization before admitting traffic.
		readiness: #ProbeConfig & {
			// -- Enabled.
			enabled: *true | bool
			// -- Path.
			path: *"/api/system/bootProgress" | string
			// -- Require native boot progress 100 before startup/readiness succeeds.
			requireBootComplete: *true | bool
			// -- Period Seconds.
			periodSeconds: *10 | (int & >0)
			// -- Timeout Seconds.
			timeoutSeconds: *3 | (int & >0)
			// -- Failure Threshold.
			failureThreshold: *3 | (int & >0)
		}
	}

	// -- Resource sizing for indexing and workspace operations; increase memory for large collections.
	resources: timoniv1.#ResourceRequirements & {
		// -- Requests.
		requests: {
			// -- Cpu.
			cpu: *"100m" | timoniv1.#CPUQuantity
			// -- Memory.
			memory: *"256Mi" | timoniv1.#MemoryQuantity
		}
		// -- Limits.
		limits: {
			// -- Cpu.
			cpu: *"1000m" | timoniv1.#CPUQuantity
			// -- Memory.
			memory: *"1Gi" | timoniv1.#MemoryQuantity
		}
	}

	// -- Non-root pod identity and CSI-assisted ownership for the workspace.
	podSecurityContext: corev1.#PodSecurityContext & {
		// -- Run As Non Root.
		runAsNonRoot: *true | bool
		// -- Run As User.
		runAsUser: *1000 | int
		// -- Run As Group.
		runAsGroup: *1000 | int
		// -- Fs Group.
		fsGroup: *1000 | int
		// -- Fs Group Change Policy.
		fsGroupChangePolicy: *"OnRootMismatch" | "Always"
		// -- Seccomp Profile.
		seccompProfile: {
			// -- Type.
			type: *"RuntimeDefault" | "Localhost" | "Unconfined"
		}
	}

	// -- Restricted container privileges; all configuration and assets are read-only.
	securityContext: corev1.#SecurityContext & {
		// -- Allow Privilege Escalation.
		allowPrivilegeEscalation: *false | bool
		// -- Read Only Root Filesystem.
		readOnlyRootFilesystem: *true | bool
		// -- Capabilities.
		capabilities: {
			// -- Drop.
			drop: *["ALL"] | [...string]
		}
	}

	// -- Pod labels; immutable selector labels cannot be overridden.
	podLabels: *{} | {[!~"^(app\\.kubernetes\\.io/name|app\\.kubernetes\\.io/instance)$"]: string}

	// -- Pod annotations, e.g. for an external Secret reloader.
	podAnnotations: *{} | {[string]: string}

	// -- Node selection constraints.
	nodeSelector: *{} | {[string]: string}

	// -- Scheduling tolerations.
	tolerations: *[] | [...corev1.#Toleration]

	// -- Pod affinity or anti-affinity.
	affinity?: corev1.#Affinity

	// -- Topology spreading across nodes or zones.
	topologySpreadConstraints: *[] | [...corev1.#TopologySpreadConstraint]

	// -- Scheduling priority class.
	priorityClassName: *"" | string

	// -- Grace period for HTTP shutdown.
	terminationGracePeriodSeconds: *30 | int & >0

	// -- Complete workspace storage, including configuration, data, history and encrypted content.
	persistence: {
		// -- Persist the complete workspace. Disable only for disposable tests.
		enabled: *true | bool
		// -- Pre-existing workspace PVC, never created or deleted by this chart.
		existingClaim: *"" | string
		// -- StorageClass name; empty uses cluster default, dash disables dynamic provisioning.
		storageClass: *"" | string
		// -- Workspace claim capacity.
		size: *"10Gi" | string
		// -- PVC access mode. Even ReadWriteMany must have exactly one application writer.
		accessModes: *["ReadWriteOnce"] | [...string]
		// -- Keep the generated PVC on Helm uninstall; this does not protect against namespace deletion.
		retain: *true | bool
		// -- Annotations.
		annotations?: timoniv1.#Annotations
	}

	// Derived claim name
	claimName: string
	if persistence.existingClaim != "" {
		claimName: persistence.existingClaim
	}
	if persistence.existingClaim == "" {
		claimName: metadata.name
	}

	// -- Native OIDC admission to this single administrative workspace. Local access-code login remains available.
	oidc: {
		// -- Enable native OIDC alongside the local administrative access-code login.
		enabled: *false | bool
		// -- Standard custom OIDC provider contract. Provider-specific OAuth adapters are not exposed.
		provider: *"custom" | string
		// -- Issuer URL used for discovery, JWKS and token exchange. Permit its destinations in egress policy.
		issuerURL: *"" | string
		// -- Registered OIDC client identifier.
		clientID: *"" | string
		// -- Inline client credential stored only in Secret; prefer existingSecret for GitOps.
		clientSecret: *"" | string
		// -- Existing Secret containing the client credential; cannot be combined with inline clientSecret.
		existingSecret: *"" | string
		// -- Key containing the OIDC client credential.
		clientSecretKey: *"client-secret" | string
		// -- Scopes requested during authorization; include openid.
		scopes: *["openid", "profile", "email"] | [...string]
		// -- Exact HTTPS callback ending in /api/system/oidc/callback. Register the same URL in the provider.
		redirectURL: *"" | string
		// -- Grant workspace administration to every authenticated identity. Keep false and configure claimRules.
		allowAll: *false | bool
		// -- AND across rules, OR across values. Use equals for exact top-level claim admission.
		claimRules: *[...] | [...{
			claim:    string
			operator: string
			values:   [...string]
		}]
	}

	// Derived OIDC secret name
	oidcSecretName: string
	if oidc.existingSecret != "" {
		oidcSecretName: oidc.existingSecret
	}
	if oidc.existingSecret == "" {
		oidcSecretName: "\(metadata.name)-oidc"
	}

	// -- Optional companion containers; set their security contexts, probes and resources explicitly.
	extraContainers: *[] | [...corev1.#Container]

	// Validations mirroring Helm's _helpers.tpl
	// 1. auth: cannot mix existingSecret and accessCode
	if auth.existingSecret != "" {
		auth: accessCode: ""
	}

	// 2. persistence: existingClaim requires persistence.enabled
	if !persistence.enabled {
		persistence: existingClaim: ""
	}

	// 4. externalSecrets: items required when enabled
	if externalSecrets.enabled {
		externalSecrets: items: [_, ...]
	}

	// 5. gatewayAPI: parentRefs required
	if gatewayAPI.enabled {
		gatewayAPI: httpRoutes: [...{
			parentRefs: [_, ...]
		}]
	}

	// 6. oidc: validations
	if oidc.enabled {
		oidc: {
			issuerURL:   string & !=""
			clientID:    string & !=""
			redirectURL: string & =~"^https://[^/?#]+/api/system/oidc/callback$"
			if oidc.clientSecret != "" {
				existingSecret: ""
			}
			if oidc.existingSecret != "" {
				clientSecret: ""
			}
			if oidc.clientSecret == "" && oidc.existingSecret == "" {
				clientSecret: _|_
			}
			if !oidc.allowAll {
				claimRules: [_, ...]
			}
		}
	}
}

#ProbeConfig: {
	enabled:              *true | bool
	path:                 string
	requireBootComplete?: bool
	periodSeconds:        int & >0
	timeoutSeconds:       int & >0
	failureThreshold:     int & >0
	initialDelaySeconds?: int & >=0
	successThreshold?:    int & >0
}

// Instance outputs the Kubernetes objects
#Instance: {
	config: #Config

	objects: {
		deploy: #Deployment & {#config: config}
		svc:    #Service & {#config: config}

		if config.serviceAccount.create {
			sa: #ServiceAccount & {#config: config}
		}
		if config.persistence.enabled && config.persistence.existingClaim == "" {
			pvc: #PersistentVolumeClaim & {#config: config}
		}
		if config.auth.existingSecret == "" {
			authSecret: #Secret & {#config: config}
		}
		if config.oidc.enabled && config.oidc.existingSecret == "" {
			oidcSecret: #OIDCSecret & {#config: config}
		}
		if config.gatewayAPI.enabled {
			for i, route in config.gatewayAPI.httpRoutes {
				"httproute-\(i)": #HTTPRoute & {
					#config: config
					#route:  route
					#index:  i
				}
			}
		}
		if config.externalSecrets.enabled {
			for i, item in config.externalSecrets.items {
				"externalsecret-\(i)": #ExternalSecret & {
					#config: config
					#item:   item
				}
			}
		}
	}
}
