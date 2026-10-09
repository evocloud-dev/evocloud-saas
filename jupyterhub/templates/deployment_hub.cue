package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#HubDeployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      #config.#hubFullname
		namespace: #config.metadata.namespace
		labels:    #config.#componentLabels & {#component: "hub"}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: #config.hub.replicaCount
		if !#config.#haHubWithExternalDb {
			strategy: type: appsv1.#RecreateDeploymentStrategyType
		}
		selector: matchLabels: #config.#selectorLabels & {#component: "hub"}
		template: corev1.#PodTemplateSpec & {
			metadata: {
				labels: #config.#podLabels & {#component: "hub"}
				if len(#config.podAnnotations) > 0 {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				terminationGracePeriodSeconds: #config.terminationGracePeriodSeconds
				if len(#config.imagePullSecrets) > 0 {
					imagePullSecrets: #config.imagePullSecrets
				}
				if #config.priorityClassName != "" {
					priorityClassName: #config.priorityClassName
				}
				serviceAccountName: #config.#serviceAccountName
				securityContext:    #config.podSecurityContext

				initContainers: [
					if #config.hub.cookieSecret.existingSecret != "" {
						{
							name:            "prepare-cookie-secret"
							image:           #config.hub.image.reference
							imagePullPolicy: #config.hub.image.pullPolicy
							command: [
								"sh",
								"-ec",
								"""
								umask 077
								cp "/var/run/jupyterhub-cookie-secret/\(#config.hub.cookieSecret.existingSecretKey)" "/srv/jupyterhub/\(#config.hub.cookieSecret.fileName)"
								chmod 600 "/srv/jupyterhub/\(#config.hub.cookieSecret.fileName)"
								""",
							]
							resources:       #config.hub.resources
							securityContext: #config.securityContext
							volumeMounts: [
								{
									name:      "data"
									mountPath: "/srv/jupyterhub"
								},
								{
									name:      "cookie-secret"
									mountPath: "/var/run/jupyterhub-cookie-secret"
									readOnly:  true
								},
							]
						}
					},
					{
						name:            "wait-for-proxy-api"
						image:           #config.#initCurlImage
						imagePullPolicy: #config.#initCurlImagePullPolicy
						command: [
							"sh",
							"-ec",
							"""
							until code="$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: token ${CONFIGPROXY_AUTH_TOKEN}" "http://\(#config.#proxyApiFullname):\(#config.service.proxyApiPort)/api/routes" 2>/dev/null || true)" && [ "$code" = "200" ]; do
							  echo "waiting for proxy api"
							  sleep 2
							done
							""",
						]
						env: [
							{
								name: "CONFIGPROXY_AUTH_TOKEN"
								valueFrom: secretKeyRef: {
									name: #config.#secretName
									key:  #config.proxy.existingSecretTokenKey
								}
							},
						]
						resources:       #config.#initCurlResources
						securityContext: #config.#initCurlSecurityContext
					},
				]

				containers: [
					{
						name:            "hub"
						image:           #config.hub.image.reference
						imagePullPolicy: #config.hub.image.pullPolicy
						command: ["jupyterhub"]
						args: ["-f", "/etc/jupyterhub/jupyterhub_config.py"]
						ports: [
							{
								name:          "hub"
								containerPort: 8081
								protocol:      "TCP"
							},
						]
						env: [
							{
								name: "CONFIGPROXY_AUTH_TOKEN"
								valueFrom: secretKeyRef: {
									name: #config.#secretName
									key:  #config.proxy.existingSecretTokenKey
								}
							},
							if #config.auth.type == "dummy" {
								{
									name:  "DUMMY_PASSWORD"
									value: #config.auth.dummyPassword
								}
							},
							{
								name: "POD_NAMESPACE"
								valueFrom: fieldRef: fieldPath: "metadata.namespace"
							},
							{
								name:  "HOME"
								value: "/srv/jupyterhub"
							},
							if len(#config.extraEnv) > 0 {
								for e in #config.extraEnv {e}
							},
						]
						livenessProbe: {
							httpGet: {
								path: #config.#hubHealthPath
								port: "hub"
							}
							initialDelaySeconds: #config.livenessProbe.initialDelaySeconds
							periodSeconds:       #config.livenessProbe.periodSeconds
							timeoutSeconds:      #config.livenessProbe.timeoutSeconds
							failureThreshold:    #config.livenessProbe.failureThreshold
						}
						readinessProbe: {
							httpGet: {
								path: #config.#hubHealthPath
								port: "hub"
							}
							initialDelaySeconds: #config.readinessProbe.initialDelaySeconds
							periodSeconds:       #config.readinessProbe.periodSeconds
							timeoutSeconds:      #config.readinessProbe.timeoutSeconds
							failureThreshold:    #config.readinessProbe.failureThreshold
						}
						startupProbe: {
							httpGet: {
								path: #config.#hubHealthPath
								port: "hub"
							}
							initialDelaySeconds: #config.startupProbe.initialDelaySeconds
							periodSeconds:       #config.startupProbe.periodSeconds
							timeoutSeconds:      #config.startupProbe.timeoutSeconds
							failureThreshold:    #config.startupProbe.failureThreshold
						}
						resources:       #config.hub.resources
						securityContext: #config.securityContext
						volumeMounts: [
							{
								name:      "config"
								mountPath: "/etc/jupyterhub"
							},
							{
								name:      "data"
								mountPath: "/srv/jupyterhub"
							},
							{
								name:      "tmp"
								mountPath: "/tmp"
							},
							if len(#config.extraVolumeMounts) > 0 {
								for vm in #config.extraVolumeMounts {vm}
							},
						]
					},
				]

				volumes: [
					{
						name: "config"
						configMap: name: #config.#cmName
					},
					if #config.hub.persistence.enabled {
						{
							name: "data"
							persistentVolumeClaim: claimName: #config.#hubDataClaimName
						}
					},
					if !#config.hub.persistence.enabled {
						{
							name: "data"
							emptyDir: {}
						}
					},
					if #config.hub.cookieSecret.existingSecret != "" {
						{
							name: "cookie-secret"
							secret: {
								secretName: #config.hub.cookieSecret.existingSecret
								items: [
									{
										key:  #config.hub.cookieSecret.existingSecretKey
										path: #config.hub.cookieSecret.existingSecretKey
									},
								]
							}
						}
					},
					{
						name: "tmp"
						emptyDir: {}
					},
					if len(#config.extraVolumes) > 0 {
						for v in #config.extraVolumes {v}
					},
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
