package templates

import (
	apps_v1 "k8s.io/api/apps/v1"
	core_v1 "k8s.io/api/core/v1"
)

monitoringLokiAdminApi: {
	#config: #Config
	let _loki_conf = #config."hyperswitch-monitoring".loki
	let minio_conf = #config."hyperswitch-monitoring".minio
	let ns = #config.metadata.namespace

	_labels: {
		"helm.sh/chart":              "loki-5.36.2"
		"app.kubernetes.io/name":     "loki"
		"app.kubernetes.io/instance": #config.metadata.name
		"app.kubernetes.io/version": [if _loki_conf.image.tag != "" {_loki_conf.image.tag}, #config.moduleVersion][0]
		"app.kubernetes.io/managed-by": "timoni"
		"app.kubernetes.io/component":  "admin-api"
	}

	_selectorLabels: {
		"app.kubernetes.io/name":      "loki"
		"app.kubernetes.io/instance":  #config.metadata.name
		"app.kubernetes.io/component": "admin-api"
	}

	if _loki_conf.enterprise.enabled {
		// 1. admin-api/deployment-admin-api.yaml
		"deployment": apps_v1.#Deployment & {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			metadata: {
				name:      "\(#config.metadata.name)-loki-admin-api"
				namespace: ns
				labels: _labels & _loki_conf.adminApi.labels & {
					"app.kubernetes.io/part-of": "memberlist"
				}
				if _loki_conf.adminApi.annotations != _|_ {
					annotations: _loki_conf.adminApi.annotations
				}
			}
			spec: {
				replicas: _loki_conf.adminApi.replicas
				selector: matchLabels: _selectorLabels
				strategy: _loki_conf.adminApi.strategy
				template: {
					metadata: {
						labels: _selectorLabels & _loki_conf.adminApi.labels & {
							"app.kubernetes.io/part-of": "memberlist"
						}
						annotations: {
							"checksum/config": "TODO_SHA256" // This would require the actual config content
							if _loki_conf.adminApi.annotations != _|_ {
								for k, v in _loki_conf.adminApi.annotations {
									"\(k)": v
								}
							}
						}
					}
					spec: {
						serviceAccountName: [if _loki_conf.rbac.namespaced {"\(#config.metadata.name)-loki"}, "default"][0]
						if _loki_conf.adminApi.priorityClassName != "" {
							priorityClassName: _loki_conf.adminApi.priorityClassName
						}
						securityContext: _loki_conf.adminApi.podSecurityContext

						if minio_conf.enabled {
							initContainers: [
								{
									name:            "minio-mc"
									image:           "\(minio_conf.mcImage.repository):\(minio_conf.mcImage.tag)"
									imagePullPolicy: minio_conf.mcImage.pullPolicy
									command: ["/bin/sh", "/config/initialize"]
									env: [
										{
											name:  "MINIO_ENDPOINT"
											value: "\(#config.metadata.name)-minio"
										},
										{
											name:  "MINIO_PORT"
											value: "\(minio_conf.minioAPIPort)"
										},
									]
									volumeMounts: [
										{
											name:      "minio-configuration"
											mountPath: "/config"
										},
									]
								},
							]
						}

						let loki_image_tag = [if _loki_conf.enterprise.image.tag != "" {_loki_conf.enterprise.image.tag}, _loki_conf.enterprise.version][0]
						containers: [
							{
								name:            "admin-api"
								image:           "\(_loki_conf.enterprise.image.repository):\(loki_image_tag)"
								imagePullPolicy: _loki_conf.enterprise.image.pullPolicy
								args: [
									"-target=admin-api",
									"-config.file=/etc/loki/config/config.yaml",
									if minio_conf.enabled {
										"-admin.client.backend-type=s3"
									},
									if minio_conf.enabled {
										"-admin.client.s3.endpoint=\(#config.metadata.name)-minio:\(minio_conf.minioAPIPort)"
									},
									if minio_conf.enabled {
										"-admin.client.s3.bucket-name=enterprise-logs-admin"
									},
									if minio_conf.enabled {
										"-admin.client.s3.access-key-id=\(minio_conf.accessKey)"
									},
									if minio_conf.enabled {
										"-admin.client.s3.secret-access-key=\(minio_conf.secretKey)"
									},
									if minio_conf.enabled {
										"-admin.client.s3.insecure=true"
									},
									for k, v in _loki_conf.adminApi.extraArgs {
										"-\(k)=\(v)"
									},
								]
								volumeMounts: [
									{
										name:      "config"
										mountPath: "/etc/loki/config"
									},
									{
										name:      "license"
										mountPath: "/etc/loki/license"
									},
									{
										name:      "storage"
										mountPath: "/data"
									},
									for vm in _loki_conf.adminApi.extraVolumeMounts {
										vm
									},
								]
								ports: [
									{
										name:          "http-metrics"
										containerPort: 3100
										protocol:      "TCP"
									},
									{
										name:          "grpc"
										containerPort: 9095
										protocol:      "TCP"
									},
									{
										name:          "http-memberlist"
										containerPort: 7946
										protocol:      "TCP"
									},
								]
								readinessProbe:  _loki_conf.adminApi.readinessProbe
								resources:       _loki_conf.adminApi.resources
								securityContext: _loki_conf.adminApi.containerSecurityContext
								if len(_loki_conf.adminApi.env) > 0 {
									env: _loki_conf.adminApi.env
								}
							},
							for c in _loki_conf.adminApi.extraContainers {
								c
							},
						]
						nodeSelector:                  _loki_conf.adminApi.nodeSelector
						affinity:                      _loki_conf.adminApi.affinity
						tolerations:                   _loki_conf.adminApi.tolerations
						terminationGracePeriodSeconds: _loki_conf.adminApi.terminationGracePeriodSeconds
						volumes: [
							{
								name: "config"
								configMap: {name: _loki_conf.loki.generatedConfigObjectName}
							},
							{
								name: "license"
								secret: secretName: [if _loki_conf.enterprise.useExternalLicense {_loki_conf.enterprise.externalLicenseName}, "enterprise-logs-license"][0]
							},
							{
								name: "storage"
								emptyDir: {}
							},
							for v in _loki_conf.adminApi.extraVolumes {
								v
							},
							if minio_conf.enabled {
								{
									name: "minio-configuration"
									projected: {
										sources: [
											{
												configMap: {name: "\(#config.metadata.name)-minio"}
											},
											{
												secret: {name: "\(#config.metadata.name)-minio"}
											},
										]
									}
								}
							},
						]
					}
				}
			}
		}

		// 2. admin-api/service-admin-api.yaml
		"service": core_v1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      "\(#config.metadata.name)-loki-admin-api"
				namespace: ns
				labels:    _labels & _loki_conf.adminApi.service.labels
				if _loki_conf.adminApi.service.annotations != _|_ {
					annotations: _loki_conf.adminApi.service.annotations
				}
			}
			spec: {
				type: "ClusterIP"
				ports: [
					{
						name:       "http-metrics"
						port:       3100
						protocol:   "TCP"
						targetPort: "http-metrics"
					},
					{
						name:       "grpc"
						port:       9095
						protocol:   "TCP"
						targetPort: "grpc"
					},
				]
				selector: _selectorLabels
			}
		}
	}
}
