package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)

#LiveService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-live"
		labels: {
			"app.name": "\(#config.#namespace)-\(#config.metadata.name)-live"
		}
	}
	spec: {
		type: "ClusterIP"
		if !#config.services.live.assign_cluster_ip {
			clusterIP: "None"
		}
		ports: [{
			name:       "live-8080"
			port:       8080
			protocol:   "TCP"
			targetPort: 8080
		}]
		selector: {
			"app.name": "\(#config.#namespace)-\(#config.metadata.name)-live"
		}
	}
}

#LiveDeployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-live-wl"
	}
	spec: {
		replicas: #config.services.live.replicas
		selector: matchLabels: {
			"app.name": "\(#config.#namespace)-\(#config.metadata.name)-live"
		}
		template: {
			metadata: {
				labels: {
					"app.name": "\(#config.#namespace)-\(#config.metadata.name)-live"
				}
				annotations: {
					timestamp: "placeholder"
				}
			}
			spec: {
				// {{- include "plane.podScheduling" .Values.services.live }}
				nodeSelector: #config.services.live.nodeSelector
				tolerations:  #config.services.live.tolerations
				affinity:     #config.services.live.affinity

				if #config.airgapped.enabled {
					volumes: [
						{
							name: "s3-custom-ca"
							hostPath: {
								path: "/etc/ssl/certs"
								type: "Directory"
							}
						},
						{
							name: "ca-bundle"
							emptyDir: {}
						},
					]
					initContainers: [{
						name:  "prepare-ca-bundle"
						image: "busybox"
						command: ["/bin/sh", "-c"]
						args: [
							"""
							set -e
							echo \"Preparing custom CA bundle for Node.js...\"
							if [ \"$(ls -A /s3-custom-ca)\" ]; then
							  cat /s3-custom-ca/* > /ca-bundle/custom-ca-bundle.crt
							  echo \"CA bundle created at /ca-bundle/custom-ca-bundle.crt\"
							else
							  echo \"No custom CA certificates found, creating empty bundle\"
							  touch /ca-bundle/custom-ca-bundle.crt
							fi
							""",
						]
						volumeMounts: [{
							name:      "s3-custom-ca"
							mountPath: "/s3-custom-ca"
							readOnly:  true
						}, {
							name:      "ca-bundle"
							mountPath: "/ca-bundle"
						}]
					}]
				}
				containers: [{
					name:            "\(#config.metadata.name)-live"
					image:           "\(#config.services.live.image):\(#config.planeVersion)"
					imagePullPolicy: "Always"
					stdin:           true
					tty:             true
					resources:       #config.services.live.resources
					
					if #config.airgapped.enabled {
						volumeMounts: [{
							name:      "ca-bundle"
							mountPath: "/ca-bundle"
						}]
					}

					envFrom: [{
						configMapRef: name: "\(#config.metadata.name)-live-vars"
					}, {
						secretRef: name:    "\(#config.metadata.name)-live-secrets"
					}]
					if #config.airgapped.enabled {
						env: [{
							name:  "NODE_EXTRA_CA_CERTS"
							value: "/ca-bundle/custom-ca-bundle.crt"
						}]
					}
				}]
				serviceAccount:     "\(#config.metadata.name)-srv-account"
				serviceAccountName: "\(#config.metadata.name)-srv-account"
			}
		}
	}
}
