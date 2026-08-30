package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
	policyv1 "k8s.io/api/policy/v1"
)

#KubePrometheusStackOperatorAdmissionWebhookServiceAccountName: {
	#config: #Config
	let kps = #config."hyperswitch-monitoring"."kube-prometheus-stack"
	let op = kps.prometheusOperator
	let opFullname = (#KubePrometheusStackOperatorFullname & {#config: #config}).result
	result: string
	if op.serviceAccount.create {
		if op.admissionWebhooks.deployment.serviceAccount.name != "" {
			result: op.admissionWebhooks.deployment.serviceAccount.name
		}
		if op.admissionWebhooks.deployment.serviceAccount.name == "" {
			result: "\(opFullname)-webhook"
		}
	}
	if !op.serviceAccount.create {
		if op.admissionWebhooks.deployment.serviceAccount.name != "" {
			result: op.admissionWebhooks.deployment.serviceAccount.name
		}
		if op.admissionWebhooks.deployment.serviceAccount.name == "" {
			result: "default"
		}
	}
}

monitoringPrometheusOperatorWebhookDeployment: {
	#config: #Config
	let mon = #config."hyperswitch-monitoring"
	let kps = mon."kube-prometheus-stack"
	let op = kps.prometheusOperator
	let fullname = (#KubePrometheusStackFullname & {#config: #config}).result
	let chartName = (#KubePrometheusStackName & {#config: #config}).result
	let opFullname = (#KubePrometheusStackOperatorFullname & {#config: #config}).result
	let opNamespace = [if kps.namespaceOverride != "" {kps.namespaceOverride}, #config.metadata.namespace][0]
	let _labels = (#KubePrometheusStackLabels & {#config: #config}).result
	let webhookLabels = _labels & {
		"app.kubernetes.io/name":      "\(chartName)-prometheus-operator"
		"app.kubernetes.io/component": "prometheus-operator-webhook"
	}
	let opServiceAccountName = (#KubePrometheusStackOperatorAdmissionWebhookServiceAccountName & {#config: #config}).result

	if op.enabled && op.admissionWebhooks.deployment.enabled {
		// deployment.yaml
		"webhook-deployment": appsv1.#Deployment & {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			metadata: {
				name:      "\(opFullname)-webhook"
				namespace: opNamespace
				labels: webhookLabels & {app: "\(chartName)-operator-webhook"} & op.admissionWebhooks.deployment.labels
				if len(op.admissionWebhooks.deployment.annotations) > 0 {
					annotations: op.admissionWebhooks.deployment.annotations
				}
			}
			spec: {
				replicas:             op.admissionWebhooks.deployment.replicas
				revisionHistoryLimit: op.admissionWebhooks.deployment.revisionHistoryLimit
				if op.admissionWebhooks.deployment.strategy != _|_ {
					strategy: op.admissionWebhooks.deployment.strategy
				}
				selector: matchLabels: {
					app:     "\(chartName)-operator-webhook"
					release: #config.metadata.name
				}
				template: {
					metadata: {
						labels: webhookLabels & {app: "\(chartName)-operator-webhook"} & op.admissionWebhooks.deployment.podLabels
						if len(op.admissionWebhooks.deployment.podAnnotations) > 0 {
							annotations: op.admissionWebhooks.deployment.podAnnotations
						}
					}
					spec: {
						if op.admissionWebhooks.deployment.priorityClassName != "" {
							priorityClassName: op.admissionWebhooks.deployment.priorityClassName
						}
						if len(mon.global.imagePullSecrets) > 0 {
							imagePullSecrets: mon.global.imagePullSecrets
						}
						containers: [{
							name: "prometheus-operator-admission-webhook"
							let operatorRegistry = [if mon.global.imageRegistry != "" {mon.global.imageRegistry}, op.admissionWebhooks.deployment.image.registry][0]
							image: [
								if op.admissionWebhooks.deployment.image.sha != "" {
									"\(operatorRegistry)/\(op.admissionWebhooks.deployment.image.repository):\(op.admissionWebhooks.deployment.image.tag)@sha256:\(op.admissionWebhooks.deployment.image.sha)"
								},
								"\(operatorRegistry)/\(op.admissionWebhooks.deployment.image.repository):\(op.admissionWebhooks.deployment.image.tag)",
							][0]
							imagePullPolicy: op.admissionWebhooks.deployment.image.pullPolicy
							args: [
								if op.admissionWebhooks.deployment.logFormat != "" {
									"--log-format=\(op.admissionWebhooks.deployment.logFormat)"
								},
								if op.admissionWebhooks.deployment.logLevel != "" {
									"--log-level=\(op.admissionWebhooks.deployment.logLevel)"
								},
								if op.admissionWebhooks.deployment.tls.enabled {
									"--web.enable-tls=true"
								},
								if op.admissionWebhooks.deployment.tls.enabled {
									"--web.cert-file=/cert/\([if op.admissionWebhooks.certManager.enabled {"tls.crt"}, "cert"][0])"
								},
								if op.admissionWebhooks.deployment.tls.enabled {
									"--web.key-file=/cert/\([if op.admissionWebhooks.certManager.enabled {"tls.key"}, "key"][0])"
								},
								if op.admissionWebhooks.deployment.tls.enabled {
									"--web.listen-address=:\(op.admissionWebhooks.deployment.tls.internalPort)"
								},
								if op.admissionWebhooks.deployment.tls.enabled {
									"--web.tls-min-version=\(op.admissionWebhooks.deployment.tls.tlsMinVersion)"
								},
							]
							ports: [{
								if op.admissionWebhooks.deployment.tls.enabled {
									containerPort: op.admissionWebhooks.deployment.tls.internalPort
									name:          "https"
								}
								if !op.admissionWebhooks.deployment.tls.enabled {
									containerPort: 8080
									name:          "http"
								}
							}]
							if op.admissionWebhooks.deployment.readinessProbe.enabled {
								readinessProbe: {
									httpGet: {
										path: "/healthz"
										port: [if op.admissionWebhooks.deployment.tls.enabled {"https"}, "http"][0]
										scheme: [if op.admissionWebhooks.deployment.tls.enabled {"HTTPS"}, "HTTP"][0]
									}
									initialDelaySeconds: op.admissionWebhooks.deployment.readinessProbe.initialDelaySeconds
									periodSeconds:       op.admissionWebhooks.deployment.readinessProbe.periodSeconds
									timeoutSeconds:      op.admissionWebhooks.deployment.readinessProbe.timeoutSeconds
									successThreshold:    op.admissionWebhooks.deployment.readinessProbe.successThreshold
									failureThreshold:    op.admissionWebhooks.deployment.readinessProbe.failureThreshold
								}
							}
							if op.admissionWebhooks.deployment.livenessProbe.enabled {
								livenessProbe: {
									httpGet: {
										path: "/healthz"
										port: [if op.admissionWebhooks.deployment.tls.enabled {"https"}, "http"][0]
										scheme: [if op.admissionWebhooks.deployment.tls.enabled {"HTTPS"}, "HTTP"][0]
									}
									initialDelaySeconds: op.admissionWebhooks.deployment.livenessProbe.initialDelaySeconds
									periodSeconds:       op.admissionWebhooks.deployment.livenessProbe.periodSeconds
									timeoutSeconds:      op.admissionWebhooks.deployment.livenessProbe.timeoutSeconds
									successThreshold:    op.admissionWebhooks.deployment.livenessProbe.successThreshold
									failureThreshold:    op.admissionWebhooks.deployment.livenessProbe.failureThreshold
								}
							}
							resources: op.admissionWebhooks.deployment.resources
							if op.admissionWebhooks.deployment.containerSecurityContext != _|_ {
								securityContext: op.admissionWebhooks.deployment.containerSecurityContext
							}
							if op.admissionWebhooks.deployment.tls.enabled {
								volumeMounts: [{
									name:      "tls-secret"
									mountPath: "/cert"
									readOnly:  true
								}]
							}
						}]
						if op.admissionWebhooks.deployment.tls.enabled {
							volumes: [{
								name: "tls-secret"
								secret: {
									defaultMode: 420
									secretName:  "\(fullname)-admission"
								}
							}]
						}
						if op.admissionWebhooks.deployment.dnsConfig != _|_ {
							dnsConfig: op.admissionWebhooks.deployment.dnsConfig
						}
						if op.admissionWebhooks.deployment.securityContext != _|_ {
							securityContext: op.admissionWebhooks.deployment.securityContext
						}
						serviceAccountName:           opServiceAccountName
						automountServiceAccountToken: op.admissionWebhooks.deployment.automountServiceAccountToken
						if op.admissionWebhooks.deployment.hostNetwork {
							hostNetwork: true
							dnsPolicy:   "ClusterFirstWithHostNet"
						}
						nodeSelector: op.admissionWebhooks.deployment.nodeSelector
						affinity:     op.admissionWebhooks.deployment.affinity
						tolerations:  op.admissionWebhooks.deployment.tolerations
					}
				}
			}
		}

		// serviceaccount.yaml
		if op.admissionWebhooks.deployment.serviceAccount.create {
			"webhook-serviceaccount": corev1.#ServiceAccount & {
				apiVersion: "v1"
				kind:       "ServiceAccount"
				metadata: {
					name:      opServiceAccountName
					namespace: opNamespace
					labels: webhookLabels & {app: "\(chartName)-operator"}
					if len(op.admissionWebhooks.deployment.serviceAccount.annotations) > 0 {
						annotations: op.admissionWebhooks.deployment.serviceAccount.annotations
					}
				}
				automountServiceAccountToken: op.admissionWebhooks.deployment.serviceAccount.automountServiceAccountToken
				if len(mon.global.imagePullSecrets) > 0 {
					imagePullSecrets: mon.global.imagePullSecrets
				}
			}
		}

		// service.yaml
		"webhook-service": corev1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      "\(opFullname)-webhook"
				namespace: opNamespace
				labels: webhookLabels & {app: "\(chartName)-operator-webhook"} & op.admissionWebhooks.deployment.service.labels
				if len(op.admissionWebhooks.deployment.service.annotations) > 0 {
					annotations: op.admissionWebhooks.deployment.service.annotations
				}
			}
			spec: {
				if op.admissionWebhooks.deployment.service.clusterIP != "" {
					clusterIP: op.admissionWebhooks.deployment.service.clusterIP
				}
				if op.admissionWebhooks.deployment.service.ipDualStack.enabled {
					ipFamilies:     op.admissionWebhooks.deployment.service.ipDualStack.ipFamilies
					ipFamilyPolicy: op.admissionWebhooks.deployment.service.ipDualStack.ipFamilyPolicy
				}
				if len(op.admissionWebhooks.deployment.service.externalIPs) > 0 {
					externalIPs: op.admissionWebhooks.deployment.service.externalIPs
				}
				if op.admissionWebhooks.deployment.service.loadBalancerIP != "" {
					loadBalancerIP: op.admissionWebhooks.deployment.service.loadBalancerIP
				}
				if len(op.admissionWebhooks.deployment.service.loadBalancerSourceRanges) > 0 {
					loadBalancerSourceRanges: op.admissionWebhooks.deployment.service.loadBalancerSourceRanges
				}
				if op.admissionWebhooks.deployment.service.type != "ClusterIP" {
					externalTrafficPolicy: op.admissionWebhooks.deployment.service.externalTrafficPolicy
				}
				ports: [
					if !op.admissionWebhooks.deployment.tls.enabled {
						{
							name: "http"
							if op.admissionWebhooks.deployment.service.type == "NodePort" {
								nodePort: op.admissionWebhooks.deployment.service.nodePort
							}
							port:       8080
							targetPort: "http"
						}
					},
					if op.admissionWebhooks.deployment.tls.enabled {
						{
							name: "https"
							if op.admissionWebhooks.deployment.service.type == "NodePort" {
								nodePort: op.admissionWebhooks.deployment.service.nodePortTls
							}
							port:       443
							targetPort: "https"
						}
					},
				]
				selector: {
					app:     "\(chartName)-operator-webhook"
					release: #config.metadata.name
				}
				type: op.admissionWebhooks.deployment.service.type
			}
		}

		// pdb.yaml
		if op.admissionWebhooks.deployment.podDisruptionBudget != _|_ {
			"webhook-pdb": policyv1.#PodDisruptionBudget & {
				apiVersion: "policy/v1"
				kind:       "PodSecurityPolicy"
				metadata: {
					name:      "\(opFullname)-webhook"
					namespace: opNamespace
					labels:    webhookLabels
				}
				spec: {
					selector: matchLabels: {
						app:     "\(chartName)-operator-webhook"
						release: #config.metadata.name
					}
					minAvailable:   op.admissionWebhooks.deployment.podDisruptionBudget.minAvailable
					maxUnavailable: op.admissionWebhooks.deployment.podDisruptionBudget.maxUnavailable
				}
			}
		}
	}
}
