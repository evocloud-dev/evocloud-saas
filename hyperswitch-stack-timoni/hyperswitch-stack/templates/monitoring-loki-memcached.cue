package templates

import (
	"strings"
	"strconv"
	"math"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	policyv1 "k8s.io/api/policy/v1"
)

monitoringLokiMemcached: {
	#config: #Config
	let loki = #config."hyperswitch-monitoring".loki
	let memcached = #config."hyperswitch-monitoring".loki.memcached
	let exporter = #config."hyperswitch-monitoring".loki.memcachedExporter
	let ns = #config.metadata.namespace
	let _name = #config.metadata.name

	let _buildMemcached = {
		#section:   string
		#component: string
		#values: {
			enabled:                       bool
			replicas:                      int
			port:                          int
			allocatedMemory:               int
			maxItemMemory:                 int
			connectionLimit:               int
			podManagementPolicy:           string
			terminationGracePeriodSeconds: int
			statefulStrategy:              appsv1.#StatefulSetUpdateStrategy
			extraExtendedOptions:          string
			extraArgs: {[string]: string}
			extraContainers: [...corev1.#Container]
			extraVolumes: [...corev1.#Volume]
			extraVolumeMounts: [...corev1.#VolumeMount]
			initContainers: [...corev1.#Container]
			nodeSelector: {[string]: string}
			affinity: corev1.#Affinity
			topologySpreadConstraints: [...corev1.#TopologySpreadConstraint]
			tolerations: [...corev1.#Toleration]
			priorityClassName: string
			podLabels: {[string]: string}
			podAnnotations: {[string]: string}
			annotations: {[string]: string}
			service: {
				labels: {[string]: string}
				annotations: {[string]: string}
			}
			persistence: {
				enabled:      bool
				storageSize:  string
				storageClass: string | *null
				mountPath:    string
			}
			resources: corev1.#ResourceRequirements | *null
			podDisruptionBudget: {
				enabled:        bool
				maxUnavailable: int | string | *null
				minAvailable:   int | string | *null
			}
		}

		let fullname = "\(_name)-loki-\(#component)"
		let memcachedImage = "\(memcached.image.repository):\(memcached.image.tag)"
		let exporterImage = "\(exporter.image.repository):\(exporter.image.tag)"

		if #values.enabled {
			"service": corev1.#Service & {
				apiVersion: "v1"
				kind:       "Service"
				metadata: {
					name:      fullname
					namespace: ns
					labels: {
						"helm.sh/chart":              "loki-5.36.2"
						"app.kubernetes.io/name":     "loki"
						"app.kubernetes.io/instance": _name
						"app.kubernetes.io/version": [if loki.image.tag != null {loki.image.tag}, #config.moduleVersion][0]
						"app.kubernetes.io/component":  "memcached-\(#component)"
						"app.kubernetes.io/managed-by": "timoni"
						for k, v in #values.service.labels {"\(k)": v}
					}
					if len(#values.service.annotations) > 0 {
						annotations: #values.service.annotations
					}
				}
				spec: {
					type:      "ClusterIP"
					clusterIP: "None"
					ports: [
						{name: "memcached-client", port: #values.port, targetPort: #values.port},
						if exporter.enabled {
							{name: "http-metrics", port: 9150, targetPort: 9150}
						},
					]
					selector: {
						"app.kubernetes.io/name":      "loki"
						"app.kubernetes.io/instance":  _name
						"app.kubernetes.io/component": "memcached-\(#component)"
					}
				}
			}

			"statefulset": appsv1.#StatefulSet & {
				apiVersion: "apps/v1"
				kind:       "StatefulSet"
				metadata: {
					name:      fullname
					namespace: ns
					labels: {
						"helm.sh/chart":              "loki-5.36.2"
						"app.kubernetes.io/name":     "loki"
						"app.kubernetes.io/instance": _name
						"app.kubernetes.io/version": [if loki.image.tag != null {loki.image.tag}, #config.moduleVersion][0]
						"app.kubernetes.io/component":  "memcached-\(#component)"
						"app.kubernetes.io/managed-by": "timoni"
						"name":                         "memcached-\(#component)"
					}
					if len(#values.annotations) > 0 {
						annotations: #values.annotations
					}
				}
				spec: {
					podManagementPolicy: #values.podManagementPolicy
					replicas:            #values.replicas
					selector: matchLabels: {
						"app.kubernetes.io/name":      "loki"
						"app.kubernetes.io/instance":  _name
						"app.kubernetes.io/component": "memcached-\(#component)"
						"name":                        "memcached-\(#component)"
					}
					updateStrategy: #values.statefulStrategy
					serviceName:    fullname
					template: {
						metadata: {
							labels: {
								"app.kubernetes.io/name":      "loki"
								"app.kubernetes.io/instance":  _name
								"app.kubernetes.io/component": "memcached-\(#component)"
								"name":                        "memcached-\(#component)"
								for k, v in loki.loki.podLabels {"\(k)": v}
								for k, v in #values.podLabels {"\(k)": v}
							}
							annotations: {
								for k, v in #config.global.podAnnotations {"\(k)": v}
								for k, v in #values.podAnnotations {"\(k)": v}
							}
						}
						spec: {
							serviceAccountName: "\(_name)-loki"
							if #values.priorityClassName != "" {
								priorityClassName: #values.priorityClassName
							}
							securityContext: memcached.podSecurityContext
							if len(#values.initContainers) > 0 {
								initContainers: #values.initContainers
							}
							nodeSelector: #values.nodeSelector
							if len(#values.affinity) > 0 {
								affinity: #values.affinity
							}
							if len(#values.topologySpreadConstraints) > 0 {
								topologySpreadConstraints: #values.topologySpreadConstraints
							}
							tolerations:                   #values.tolerations
							terminationGracePeriodSeconds: #values.terminationGracePeriodSeconds
							if len(loki.imagePullSecrets) > 0 {
								imagePullSecrets: loki.imagePullSecrets
							}
							volumes: [
								for v in #values.extraVolumes {v},
							]
							containers: [
								{
									name:            "memcached"
									image:           memcachedImage
									imagePullPolicy: memcached.image.pullPolicy
									resources: [if #values.resources != null {#values.resources}, {
										let requestMemory = math.Floor((#values.allocatedMemory*12 + 5) / 10)
										limits: memory: "\(requestMemory)Mi"
										requests: {
											cpu:    "500m"
											memory: "\(requestMemory)Mi"
										}
									}][0]
									ports: [{containerPort: #values.port, name: "client"}]
									let _pSizeStr = strings.TrimSuffix(strings.TrimSuffix(#values.persistence.storageSize, "Gi"), "G")
									let pSizeInt = strconv.Atoi(_pSizeStr)
									let persistenceSize = math.Floor((pSizeInt * 9) / 10)
									args: [
										"-m \(#values.allocatedMemory)",
										"--extended=modern,track_sizes\([if #values.persistence.enabled {",ext_path=\(#values.persistence.mountPath)/file:\(persistenceSize)G,ext_wbuf_size=16"}, ""][0])\( [if #values.extraExtendedOptions != "" {",\(#values.extraExtendedOptions)"}, ""][0])",
										"-I \(#values.maxItemMemory)m",
										"-c \(#values.connectionLimit)",
										"-v",
										"-u \(#values.port)",
										for k, v in #values.extraArgs {
											"-\(k)\([if v != "" {" \(v)"}, ""][0])"
										},
									]
									if len(loki.loki.extraEnv) > 0 {
										env: loki.loki.extraEnv
									}
									if len(loki.loki.extraEnvFrom) > 0 {
										envFrom: loki.loki.extraEnvFrom
									}
									securityContext: memcached.containerSecurityContext
									if #values.persistence.enabled || len(#values.extraVolumeMounts) > 0 {
										volumeMounts: [
											if #values.persistence.enabled {
												{name: "data", mountPath: #values.persistence.mountPath}
											},
											for vm in #values.extraVolumeMounts {vm},
										]
									}
								},
								if exporter.enabled {
									{
										name:            "exporter"
										image:           exporterImage
										imagePullPolicy: exporter.image.pullPolicy
										ports: [{containerPort: 9150, name: "http-metrics"}]
										args: [
											"--memcached.address=localhost:\(#values.port)",
											"--web.listen-address=0.0.0.0:9150",
											for k, v in exporter.extraArgs {
												"--\(k)\([if v != "" {"=\(v)"}, ""][0])"
											},
										]
										resources:       exporter.resources
										securityContext: exporter.containerSecurityContext
										if len(#values.extraVolumeMounts) > 0 {
											volumeMounts: #values.extraVolumeMounts
										}
									}
								},
								for c in #values.extraContainers {c},
							]
						}
					}
					if #values.persistence.enabled {
						volumeClaimTemplates: [{
							metadata: name: "data"
							spec: {
								accessModes: ["ReadWriteOnce"]
								if #values.persistence.storageClass != null {
									storageClassName: [if #values.persistence.storageClass == "-" {""}, #values.persistence.storageClass][0]
								}
								resources: requests: storage: #values.persistence.storageSize
							}
						}]
					}
				}
			}

			if #values.podDisruptionBudget.enabled {
				"poddisruptionbudget": policyv1.#PodDisruptionBudget & {
					if #config.clusterVersion.#Version >= "1.21.0" {
						apiVersion: "policy/v1"
					}
					if #config.clusterVersion.#Version < "1.21.0" {
						apiVersion: "policy/v1beta1"
					}
					kind: "PodDisruptionBudget"
					metadata: {
						name:      fullname
						namespace: ns
						labels: {
							"helm.sh/chart":              "loki-5.36.2"
							"app.kubernetes.io/name":     "loki"
							"app.kubernetes.io/instance": _name
							"app.kubernetes.io/version": [if loki.image.tag != null {loki.image.tag}, #config.moduleVersion][0]
							"app.kubernetes.io/component":  "memcached-\(#component)"
							"app.kubernetes.io/managed-by": "timoni"
						}
					}
					spec: {
						selector: matchLabels: {
							"app.kubernetes.io/name":      "loki"
							"app.kubernetes.io/instance":  _name
							"app.kubernetes.io/component": "memcached-\(#component)"
						}
						if #values.podDisruptionBudget.maxUnavailable != null {
							maxUnavailable: #values.podDisruptionBudget.maxUnavailable
						}
						if #values.podDisruptionBudget.minAvailable != null {
							minAvailable: #values.podDisruptionBudget.minAvailable
						}
					}
				}
			}
		}
	}

	// File 1-3: chunks-cache
	let chunks = _buildMemcached & {#section: "chunksCache", #component: "chunks-cache", #values: loki.chunksCache}
	for name, obj in chunks {
		"chunks-cache-\(name)": obj
	}
}
