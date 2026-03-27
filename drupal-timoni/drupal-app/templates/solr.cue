package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#SolrDeployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-solr"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: #config.solr.replicaCount
		strategy: {
			type: #config.solr.strategy
		}
		selector: matchLabels: #config.selector.labels & {
			app: "solr"
		}
		template: {
			metadata: labels: #config.metadata.labels & {
				app: "solr"
			}
			spec: corev1.#PodSpec & {
				securityContext: fsGroup: 1001
				if #config.solr.volumePermissions.enabled {
					initContainers: [
						{
							name:  "init-solr-data"
							image: "\(#config.solr.image.registry)/\(#config.solr.image.repository):\(#config.solr.image.tag)"
							command: [
								"/bin/sh",
								"-c",
								"""
								set -e
								# Populate writable mounts from original image locations
								echo "Initializing writable paths..."
								rm -rf /mnt/server/*
								cp -a /opt/bitnami/solr/server/* /mnt/server/
								mkdir -p /mnt/logs /mnt/tmp
								
								# Mirror the expected persistence structure
								mkdir -p /mnt/data/server/solr
								if [ ! -f /mnt/data/server/solr/solr.xml ]; then
									echo "Populating Solr home in PVC..."
									cp -a /opt/bitnami/solr/server/solr/* /mnt/data/server/solr/
								fi
								
								# Set permissions for non-root user 1001
								chown -R 1001:1001 /mnt/data /mnt/server /mnt/logs /mnt/tmp
								""",
							]
							securityContext: {
								runAsUser:                0
								allowPrivilegeEscalation: true
							}
							volumeMounts: [
								{
									name:      "solr-data"
									mountPath: "/mnt/data"
								},
								{
									name:      "solr-server"
									mountPath: "/mnt/server"
								},
								{
									name:      "solr-logs"
									mountPath: "/mnt/logs"
								},
								{
									name:      "solr-tmp"
									mountPath: "/mnt/tmp"
								},
							]
						},
					]
				}
				containers: [
					{
						name:  "solr"
						image:           "\(#config.solr.image.registry)/\(#config.solr.image.repository):\(#config.solr.image.tag)"
						imagePullPolicy: #config.solr.image.pullPolicy
						ports: [
							{
								name:          "solr"
								containerPort: #config.solr.service.port
							},
						]
						volumeMounts: [
							{
								name:      "solr-data"
								mountPath: "/bitnami/solr"
							},
							{
								name:      "solr-server"
								mountPath: "/opt/bitnami/solr/server"
							},
							{
								name:      "solr-logs"
								mountPath: "/opt/bitnami/solr/logs"
							},
							{
								name:      "solr-tmp"
								mountPath: "/opt/bitnami/solr/tmp"
							},
						]
						env: [
							if #config.solr.cloudEnabled {
								{
									name:  "SOLR_CLOUD"
									value: "true"
								}
								{
									name:  "SOLR_COLLECTION_REPLICAS"
									value: "\(#config.solr.collectionReplicas)"
								}
							}
							if #config.solr.zookeeper.enabled {
								{
									name:  "SOLR_ZK_HOST"
									value: "\(#config.metadata.name)-zookeeper:2181"
								}
							}
							{
								name:  "SOLR_HOME"
								value: "/opt/bitnami/solr/server/solr"
							},
							{
								name:  "SOLR_LOGS_DIR"
								value: "/opt/bitnami/solr/logs"
							},
							{
								name:  "SOLR_PID_DIR"
								value: "/opt/bitnami/solr/tmp"
							},
							{
								name:  "BITNAMI_DEBUG"
								value: "true"
							},
						]
						if #config.solr.resources != _|_ {
							resources: #config.solr.resources
						}
						lifecycle: postStart: exec: command: [
							"/bin/sh",
							"-c",
							"while ! curl -s http://localhost:8983/solr/admin/info/system > /dev/null; do sleep 2; done; if [ ! -d /opt/bitnami/solr/server/solr/drupal ]; then solr create -c drupal; fi",
						]
						securityContext: {
							runAsUser:    1001
							runAsGroup:   1001
							runAsNonRoot: true
						}
					},
				]
				volumes: [
					{
						name: "solr-data"
						persistentVolumeClaim: {
							claimName: [ if #config.solr.persistence.existingClaim != "" { #config.solr.persistence.existingClaim }, "\(#config.metadata.name)-solr" ][0]
						}
					},
					{
						name: "solr-server"
						emptyDir: {}
					},
					{
						name: "solr-logs"
						emptyDir: {}
					},
					{
						name: "solr-tmp"
						emptyDir: {}
					},
				]
			}
		}
	}
}

#SolrService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-solr"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#ServiceSpec & {
		type: #config.solr.service.type
		ports: [
			{
				name:       "solr"
				port:       #config.solr.service.port
				targetPort: "solr"
			},
		]
		selector: #config.selector.labels & {
			app: "solr"
		}
	}
}

#SolrPersistentVolumeClaim: corev1.#PersistentVolumeClaim & {
	#config: #Config

	if #config.solr.persistence.enabled && #config.solr.persistence.existingClaim == "" {
		apiVersion: "v1"
		kind:       "PersistentVolumeClaim"
		metadata: {
			name:      "\(#config.metadata.name)-solr"
			namespace: #config.metadata.namespace
			labels:    #config.metadata.labels
		}
		spec: corev1.#PersistentVolumeClaimSpec & {
			accessModes: [ #config.solr.persistence.accessMode]
			resources: requests: storage: #config.solr.persistence.size
			if #config.solr.persistence.storageClass != "" {
				if #config.solr.persistence.storageClass == "-" {
					storageClassName: ""
				}
				if #config.solr.persistence.storageClass != "-" {
					storageClassName: #config.solr.persistence.storageClass
				}
			}
		}
	}
}
