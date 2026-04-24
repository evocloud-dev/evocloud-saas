package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)

#ApiService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-api"
	}
	spec: {
		type: "ClusterIP"
		if !#config.services.api.assign_cluster_ip {
			clusterIP: "None"
		}
		ports: [{
			name:       "api-8000"
			port:       8000
			protocol:   "TCP"
			targetPort: 8000
		}]
		selector: {
			"app.name": "\(#config.#namespace)-\(#config.metadata.name)-api"
		}
	}
}

#ApiDeployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-api-wl"
	}
	spec: {
		replicas: #config.services.api.replicas
		selector: matchLabels: {
			"app.name": "\(#config.#namespace)-\(#config.metadata.name)-api"
		}
		template: {
			metadata: {
				labels: {
					"app.name": "\(#config.#namespace)-\(#config.metadata.name)-api"
				}
				annotations: {
					timestamp: "placeholder"
				}
			}
			spec: {
				// {{- include "plane.podScheduling" .Values.services.api }}
				nodeSelector: #config.services.api.nodeSelector
				tolerations:  #config.services.api.tolerations
				affinity:     #config.services.api.affinity

				if #config.airgapped.enabled {
					volumes: [
						{
							name: "s3-custom-ca"
							projected: sources: [
								if len(#config.airgapped.s3Secrets) > 0 {
									for s in #config.airgapped.s3Secrets {
										secret: {
											name: s.name
											items: [{key: s.key, path: s.key}]
										}
									}
								},
								if len(#config.airgapped.s3Secrets) == 0 && #config.airgapped.s3SecretName != "" {
									{
										secret: {
											name: #config.airgapped.s3SecretName
											items: [{key: #config.airgapped.s3SecretKey, path: #config.airgapped.s3SecretKey}]
										}
									}
								}
							]
						},
						{
							name: "ca-bundle"
							emptyDir: {}
						}
					]
				}
				containers: [{
					name:            "\(#config.metadata.name)-api"
					image:           "\(#config.services.api.image):\(#config.planeVersion)"
					imagePullPolicy: "Always"
					stdin:           true
					tty:             true
					resources:       #config.services.api.resources
					
					if #config.airgapped.enabled {
						volumeMounts: [{
							name:      "s3-custom-ca"
							mountPath: "/s3-custom-ca"
							readOnly:  true
						}, {
							name:      "ca-bundle"
							mountPath: "/ca-bundle"
						}]
					}

					command: ["/bin/bash", "-c"]
					args: [
						"""
						set -e
						if [ -d /s3-custom-ca ] && [ \"$(ls -A /s3-custom-ca)\" ]; then
						  echo \"Preparing custom CA bundle...\"
						  cat /s3-custom-ca/* > /ca-bundle/custom-ca-bundle.crt
						  export NODE_EXTRA_CA_CERTS=/ca-bundle/custom-ca-bundle.crt
						  export REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
						  cat /ca-bundle/custom-ca-bundle.crt >> /etc/ssl/certs/ca-certificates.crt
						fi
						exec ./bin/docker-entrypoint-api-ee.sh
						""",
					]

					envFrom: [
						{configMapRef: name: "\(#config.metadata.name)-app-vars"},
						{secretRef: name:    "\(#config.metadata.name)-app-secrets"},
						{secretRef: name:    "\(#config.metadata.name)-doc-store-secrets"},
						{secretRef: name:    "\(#config.metadata.name)-opensearch-secrets"},
						if #config.services.silo.enabled {
							{secretRef: name: "\(#config.metadata.name)-silo-secrets"}
						},
					]

					if #config.airgapped.enabled || #config.extraEnv != [] {
						env: [
							if #config.airgapped.enabled {
								{
									name:  "NODE_EXTRA_CA_CERTS"
									value: "/ca-bundle/custom-ca-bundle.crt"
								}
							},
							for e in #config.extraEnv {e},
						]
					}

					readinessProbe: {
						httpGet: {
							path: "/"
							port: 8000
						}
						failureThreshold: 30
						periodSeconds:    10
						successThreshold: 1
						timeoutSeconds:   1
					}
				}]
				serviceAccount:     "\(#config.metadata.name)-srv-account"
				serviceAccountName: "\(#config.metadata.name)-srv-account"
			}
		}
	}
}
