package templates

monitoringLokiRuler: {
	#loki:     _
	#ruler:    _
	#metadata: _

	let ns = #metadata.namespace
	let _name = #metadata.name
	let fullname = "\(_name)-loki-ruler"
	let isDistributed = #loki.deploymentMode == "Distributed"
	let imageTag = #loki.image.tag
	let imageRepo = #loki.image.repository
	let pullPolicy = #loki.image.pullPolicy

	let commonLabels = {
		for k, v in #metadata.labels if k != "app.kubernetes.io/name" && k != "app.kubernetes.io/instance" && k != "app.kubernetes.io/version" && k != "app.kubernetes.io/component" && k != "app.kubernetes.io/managed-by" {
			"\(k)": v
		}
		"helm.sh/chart":                "loki-5.36.2"
		"app.kubernetes.io/name":       "loki"
		"app.kubernetes.io/instance":   _name
		"app.kubernetes.io/version":    imageTag
		"app.kubernetes.io/component":  "ruler"
		"app.kubernetes.io/managed-by": "timoni"
	}

	let selectorLabels = {
		"app.kubernetes.io/name":      "loki"
		"app.kubernetes.io/instance":  _name
		"app.kubernetes.io/component": "ruler"
	}

	if isDistributed && #ruler.enabled {
		// File 1: statefulset-ruler.yaml
		"statefulset": {
			apiVersion: "apps/v1"
			kind:       "StatefulSet"
			metadata: {
				name:      fullname
				namespace: ns
				labels: commonLabels & {"app.kubernetes.io/part-of": "memberlist"}
				if len(#loki.loki.annotations) > 0 {
					annotations: #loki.loki.annotations
				}
			}
			spec: {
				replicas:             #ruler.replicas
				serviceName:          fullname
				revisionHistoryLimit: #loki.loki.revisionHistoryLimit
				selector: matchLabels: selectorLabels
				template: {
					metadata: {
						annotations: {
							"checksum/config": "config-checksum-placeholder"
							for k, v in #loki.loki.podAnnotations {"\(k)": v}
							for k, v in #ruler.podAnnotations {"\(k)": v}
						}
						labels: selectorLabels & {
							"app.kubernetes.io/part-of": "memberlist"
							for k, v in #loki.loki.podLabels {"\(k)": v}
							for k, v in #ruler.podLabels {"\(k)": v}
						}
					}
					spec: {
						serviceAccountName: "\(_name)-loki"
						if #ruler.priorityClassName != null {
							priorityClassName: #ruler.priorityClassName
						}
						securityContext:               #loki.loki.podSecurityContext
						terminationGracePeriodSeconds: #ruler.terminationGracePeriodSeconds
						if len(#ruler.initContainers) > 0 {
							initContainers: #ruler.initContainers
						}
						containers: [
							{
								name:            "ruler"
								image:           "\(imageRepo):\(imageTag)"
								imagePullPolicy: pullPolicy
								args: [
									"-config.file=/etc/loki/config/config.yaml",
									"-target=ruler",
									for arg in #ruler.extraArgs {arg},
								]
								ports: [
									{name: "http-metrics", containerPort: 3100, protocol: "TCP"},
									{name: "grpc", containerPort: 9095, protocol: "TCP"},
									{name: "http-memberlist", containerPort: 7946, protocol: "TCP"},
								]
								if len(#ruler.extraEnv) > 0 {
									env: #ruler.extraEnv
								}
								if len(#ruler.extraEnvFrom) > 0 {
									envFrom: #ruler.extraEnvFrom
								}
								securityContext: #loki.loki.containerSecurityContext
								readinessProbe:  #loki.loki.readinessProbe
								volumeMounts: [
									{name: "config", mountPath: "/etc/loki/config"},
									{name: "runtime-config", mountPath: "/etc/loki/runtime-config"},
									{name: "data", mountPath: "/var/loki"},
									{name: "tmp", mountPath: "/tmp/loki"},
									for dirName, _ in #ruler.directories {
										{name: "rules-\(dirName)", mountPath: "/etc/loki/rules/\(dirName)"}
									},
									for vm in #ruler.extraVolumeMounts {vm},
								]
								resources: #ruler.resources
							},
						]
						if len(#ruler.affinity) > 0 {
							affinity: #ruler.affinity
						}
						nodeSelector: #ruler.nodeSelector
						tolerations:  #ruler.tolerations
						volumes: [
							{name: "config", configMap: name: "\(_name)-loki-config"},
							{name: "runtime-config", configMap: name: "\(_name)-loki-runtime"},
							{name: "tmp", emptyDir: {}},
							for dirName, _ in #ruler.directories {
								{name: "rules-\(dirName)", configMap: name: "\(fullname)-rules-\(dirName)"}
							},
							if !#ruler.persistence.enabled {
								{name: "data", emptyDir: {}}
							},
							for v in #ruler.extraVolumes {v},
						]
					}
				}
				if #ruler.persistence.enabled {
					volumeClaimTemplates: [
						{
							metadata: {
								name: "data"
								if len(#ruler.persistence.annotations) > 0 {
									annotations: #ruler.persistence.annotations
								}
							}
							spec: {
								accessModes: ["ReadWriteOnce"]
								if #ruler.persistence.storageClass != null {
									storageClassName: [if #ruler.persistence.storageClass == "-" {""}, #ruler.persistence.storageClass][0]
								}
								resources: requests: storage: #ruler.persistence.size
							}
						},
					]
				}
			}
		}

		// File 2: service-ruler.yaml
		"service": {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      fullname
				namespace: ns
				labels:    commonLabels
			}
			spec: {
				type: "ClusterIP"
				ports: [
					{name: "http-metrics", port: 3100, targetPort: "http-metrics", protocol: "TCP"},
					{name: "grpc", port: 9095, targetPort: "grpc", protocol: "TCP"},
				]
				selector: selectorLabels
			}
		}

		// File 3: poddisruptionbudget-ruler.yaml
		if #ruler.replicas > 1 {
			"poddisruptionbudget": {
				apiVersion: "policy/v1"
				kind:       "PodDisruptionBudget"
				metadata: {
					name:      fullname
					namespace: ns
					labels:    commonLabels
				}
				spec: {
					selector: matchLabels: selectorLabels
					maxUnavailable: 1
				}
			}
		}

		// File 4: configmap-ruler.yaml
		for dirName, content in #ruler.directories {
			"configmap-rules-\(dirName)": {
				apiVersion: "v1"
				kind:       "ConfigMap"
				metadata: {
					name:      "\(fullname)-rules-\(dirName)"
					namespace: ns
					labels:    commonLabels
				}
				data: content
			}
		}
	}
}
