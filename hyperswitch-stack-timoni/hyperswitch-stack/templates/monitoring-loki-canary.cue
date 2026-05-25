package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

monitoringLokiCanary: {
	#config: #Config
	let loki = #config."hyperswitch-monitoring".loki
	let lokiCanary = #config."hyperswitch-monitoring".loki.lokiCanary
	let ns = #config.metadata.namespace
	let _name = #config.metadata.name

	if loki.enabled && lokiCanary.enabled {
		let canaryLabels = {
			"helm.sh/chart":              "loki-5.36.2"
			"app.kubernetes.io/name":     "loki"
			"app.kubernetes.io/instance": _name
			"app.kubernetes.io/version": [if loki.image.tag != null {loki.image.tag}, #config.moduleVersion][0]
			"app.kubernetes.io/component":  "canary"
			"app.kubernetes.io/managed-by": "timoni"
			for k, v in #config.metadata.labels if k != "app.kubernetes.io/name" && k != "app.kubernetes.io/instance" && k != "app.kubernetes.io/managed-by" {
				"\(k)": v
			}
		}

		let canarySelectorLabels = {
			"app.kubernetes.io/name":      "loki"
			"app.kubernetes.io/instance":  _name
			"app.kubernetes.io/component": "canary"
		}

		let canaryFullname = "\(_name)-loki-canary"
		let lokiTag = [if lokiCanary.image.tag != null {lokiCanary.image.tag}, #config.moduleVersion][0]
		let canaryImage = [if lokiCanary.image.registry != null {"\(lokiCanary.image.registry)/\(lokiCanary.image.repository):\(lokiTag)"}, "\(lokiCanary.image.repository):\(lokiTag)"][0]
		let clusterDomain = #config.global.clusterDomain
		let lokiHost = "\(_name)-loki-gateway.\(ns).svc.\(clusterDomain):8080"

		// File 1: serviceaccount.yaml
		"serviceaccount": corev1.#ServiceAccount & {
			apiVersion: "v1"
			kind:       "ServiceAccount"
			metadata: {
				name:      canaryFullname
				namespace: ns
				labels:    canaryLabels
				if len(lokiCanary.annotations) > 0 {
					annotations: lokiCanary.annotations
				}
			}
			automountServiceAccountToken: [if loki.serviceAccount.automountServiceAccountToken != null {loki.serviceAccount.automountServiceAccountToken}, true][0]
			if loki.serviceAccount.imagePullSecrets != null && len(loki.serviceAccount.imagePullSecrets) > 0 {
				imagePullSecrets: loki.serviceAccount.imagePullSecrets
			}
		}

		// File 2: service.yaml
		"service": corev1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:        canaryFullname
				namespace:   ns
				labels:      canaryLabels & loki.loki.serviceLabels & lokiCanary.service.labels
				annotations: loki.loki.serviceAnnotations & lokiCanary.service.annotations
			}
			spec: {
				type: "ClusterIP"
				ports: [
					{
						name:       "http-metrics"
						port:       3500
						targetPort: "http-metrics"
						protocol:   "TCP"
					},
				]
				selector: canarySelectorLabels
			}
		}

		// File 3: daemonset.yaml
		"daemonset": appsv1.#DaemonSet & {
			apiVersion: "apps/v1"
			kind:       "DaemonSet"
			metadata: {
				name:      canaryFullname
				namespace: ns
				labels:    canaryLabels
			}
			spec: {
				selector: matchLabels: canarySelectorLabels
				if len(lokiCanary.updateStrategy) > 0 {
					updateStrategy: lokiCanary.updateStrategy
				}
				template: {
					metadata: {
						if len(lokiCanary.annotations) > 0 {
							annotations: lokiCanary.annotations
						}
						labels: canarySelectorLabels & lokiCanary.podLabels
					}
					spec: {
						serviceAccountName: canaryFullname
						if len(loki.imagePullSecrets) > 0 {
							imagePullSecrets: loki.imagePullSecrets
						}
						if lokiCanary.priorityClassName != "" {
							priorityClassName: lokiCanary.priorityClassName
						}
						securityContext: loki.loki.podSecurityContext
						containers: [
							{
								name:            "loki-canary"
								image:           canaryImage
								imagePullPolicy: loki.image.pullPolicy
								args: [
									"-addr=\(lokiHost)",
									"-labelname=\(lokiCanary.labelname)",
									"-labelvalue=$(POD_NAME)",
									if loki.loki.auth_enabled {
										"-user=\(#config.monitoring.selfMonitoring.tenant.name)"
									},
									if loki.loki.auth_enabled {
										"-tenant-id=\(#config.monitoring.selfMonitoring.tenant.name)"
									},
									if loki.loki.auth_enabled {
										"-pass=\(#config.monitoring.selfMonitoring.tenant.password)"
									},
									if lokiCanary.push {
										"-push=true"
									},
									for arg in lokiCanary.extraArgs {
										arg
									},
								]
								securityContext: loki.loki.containerSecurityContext
								if len(lokiCanary.extraVolumeMounts) > 0 {
									volumeMounts: lokiCanary.extraVolumeMounts
								}
								ports: [
									{
										name:          "http-metrics"
										containerPort: 3500
										protocol:      "TCP"
									},
								]
								env: [
									{
										name: "POD_NAME"
										valueFrom: fieldRef: fieldPath: "metadata.name"
									},
									for ev in lokiCanary.extraEnv {
										ev
									},
								]
								if len(lokiCanary.extraEnvFrom) > 0 {
									envFrom: lokiCanary.extraEnvFrom
								}
								readinessProbe: {
									httpGet: {
										path: "/metrics"
										port: "http-metrics"
									}
									initialDelaySeconds: 15
									timeoutSeconds:      1
								}
								if len(lokiCanary.resources) > 0 {
									resources: lokiCanary.resources
								}
							},
						]
						if lokiCanary.dnsConfig != null {
							dnsConfig: lokiCanary.dnsConfig
						}
						if len(lokiCanary.nodeSelector) > 0 {
							nodeSelector: lokiCanary.nodeSelector
						}
						if len(lokiCanary.tolerations) > 0 {
							tolerations: lokiCanary.tolerations
						}
						if len(lokiCanary.extraVolumes) > 0 {
							volumes: lokiCanary.extraVolumes
						}
					}
				}
			}
		}
	}
}
