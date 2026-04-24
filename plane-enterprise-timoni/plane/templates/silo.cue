package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)

#SiloService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-silo"
		labels: {
			"app.name": "\(#config.#namespace)-\(#config.metadata.name)-silo"
		}
	}
	spec: {
		type: "ClusterIP"
		if !#config.services.silo.assign_cluster_ip {
			clusterIP: "None"
		}
		ports: [{
			name:       "silo-8080"
			port:       8080
			protocol:   "TCP"
			targetPort: 8080
		}]
		selector: {
			"app.name": "\(#config.#namespace)-\(#config.metadata.name)-silo"
		}
	}
}

#SiloDeployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-silo-wl"
	}
	spec: {
		replicas:    #config.services.silo.replicas
		selector: matchLabels: {
			"app.name": "\(#config.#namespace)-\(#config.metadata.name)-silo"
		}
		template: {
			metadata: {
				labels: {
					"app.name": "\(#config.#namespace)-\(#config.metadata.name)-silo"
				}
				annotations: {
					timestamp: "placeholder"
				}
			}
			spec: {
				// {{- include "plane.podScheduling" .Values.services.silo }}
				nodeSelector: #config.services.silo.nodeSelector
				tolerations:  #config.services.silo.tolerations
				affinity:     #config.services.silo.affinity

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
				}

				initContainers: [
					{
						name:  "wait-for-rabbitmq"
						image: "busybox"
						command: ["/bin/sh", "-c"]
						args: [
							"""
							until nslookup \((#config.metadata.name))-rabbitmq.\((#config.#namespace)).svc.cluster.local > /dev/null 2>&1; do
							  echo \"Waiting for local RabbitMQ...\";
							  sleep 5;
							done;
							echo \"RabbitMQ is up!\";
							""",
						]
					},
					if #config.airgapped.enabled {
						{
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
						}
					},
				]
				containers: [{
					name:            "\(#config.metadata.name)-silo"
					image:           "\(#config.services.silo.image):\(#config.planeVersion)"
					imagePullPolicy: "Always"
					stdin:           true
					tty:             true
					resources:       #config.services.silo.resources
					
					if #config.airgapped.enabled {
						volumeMounts: [{
							name:      "ca-bundle"
							mountPath: "/ca-bundle"
						}]
					}

					envFrom: [{
						configMapRef: name: "\(#config.metadata.name)-silo-vars"
					}, {
						secretRef: name:    "\(#config.metadata.name)-silo-secrets"
					}, {
						secretRef: name:    "\(#config.metadata.name)-doc-store-secrets"
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
