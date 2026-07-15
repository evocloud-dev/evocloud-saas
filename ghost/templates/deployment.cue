package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#Deployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      #config.#serviceName
		namespace: #config.metadata.namespace
		labels:    #config.labels
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: 1
		strategy: type: "Recreate"
		selector: matchLabels: #config.selector.labels
		template: {
			metadata: {
				labels: #config.selector.labels & #config.podLabels
				annotations: {
					"seccomp.security.alpha.kubernetes.io/pod": "runtime/default"
					"container.seccomp.security.alpha.kubernetes.io/ghost": "runtime/default"
					for k, v in #config.podAnnotations {
						"\(k)": v
					}
				}
			}
			spec: corev1.#PodSpec & {
				automountServiceAccountToken: #config.serviceAccount.automountServiceAccountToken
				if len(#config.imagePullSecrets) > 0 {
					imagePullSecrets: #config.imagePullSecrets
				}
				if #config.serviceAccount.create {
					serviceAccountName: #config.#serviceAccountName
				}
				if #config.priorityClassName != "" {
					priorityClassName: #config.priorityClassName
				}
				if len(#config.podSecurityContext) > 0 {
					securityContext: #config.podSecurityContext
				}
				terminationGracePeriodSeconds: #config.terminationGracePeriodSeconds
				initContainers: [{
					name:  "wait-for-db"
					image: "docker.io/library/busybox:1.37"
					command: ["sh", "-c", """
						echo "Waiting for database at \(#config.#dbHost):\(#config.#dbPort)..."
						until nc -z -w2 \(#config.#dbHost) \(#config.#dbPort); do
						  echo "Database not ready, retrying in 2s..."
						  sleep 2
						done
						echo "Database is ready."
						"""]
					if len(#config.waitForDatabase.resources) > 0 {
						resources: #config.waitForDatabase.resources
					}
					if len(#config.securityContext) > 0 {
						securityContext: #config.securityContext
					}
				}]
				containers: [{
					name:            "ghost"
					image:           #config.image.reference
					imagePullPolicy: #config.image.pullPolicy
					ports: [{
						name:          "http"
						containerPort: 2368
						protocol:      "TCP"
					}]
					env: [
						{name: "NODE_ENV", value: "production"},
						if #config.ghost.url != "" {name: "url", value: #config.ghost.url},
						{name: "database__client", value: "mysql"},
						{name: "database__connection__host", value: #config.#dbHost},
						{name: "database__connection__port", value: #config.#dbPort},
						{name: "database__connection__user", value: #config.#dbUsername},
						{
							name: "database__connection__password"
							valueFrom: secretKeyRef: {
								name: #config.#dbSecretName
								key:  #config.#dbSecretPasswordKey
							}
						},
						{name: "database__connection__database", value: #config.#dbName},
						for item in #config.ghost.extraEnv {item},
					]
					if #config.probes.startup.enabled {
						startupProbe: #ProbeSpec & {#probe: #config.probes.startup}
					}
					if #config.probes.liveness.enabled {
						livenessProbe: #ProbeSpec & {#probe: #config.probes.liveness}
					}
					if #config.probes.readiness.enabled {
						readinessProbe: #ProbeSpec & {#probe: #config.probes.readiness}
					}
					if len(#config.resources) > 0 {
						resources: #config.resources
					}
					if len(#config.securityContext) > 0 {
						securityContext: #config.securityContext
					}
					volumeMounts: [
						{name: "content", mountPath: "/var/lib/ghost/content"},
						{name: "tmp-dir", mountPath: "/tmp"},
						for item in #config.extraVolumeMounts {item},
					]
				}]
				volumes: [
					{
						name: "content"
						if #config.persistence.enabled {
							persistentVolumeClaim: claimName: #config.#contentClaimName
						}
						if !#config.persistence.enabled {
							emptyDir: {}
						}
					},
					{
						name: "tmp-dir"
						emptyDir: {}
					},
					for item in #config.extraVolumes {item},
				]
				if len(#config.nodeSelector) > 0 {
					nodeSelector: #config.nodeSelector
				}
				if len(#config.affinity) > 0 {
					affinity: #config.affinity
				}
				if len(#config.tolerations) > 0 {
					tolerations: #config.tolerations
				}
				if len(#config.topologySpreadConstraints) > 0 {
					topologySpreadConstraints: #config.topologySpreadConstraints
				}
			}
		}
	}
}