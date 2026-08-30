package templates

import (
	"strings"
	"list"
	corev1 "k8s.io/api/core/v1"
	rbacv1 "k8s.io/api/rbac/v1"
	appsv1 "k8s.io/api/apps/v1"
)

#KubePrometheusStackOperatorFullname: {
	#config: #Config
	let fullname = (#KubePrometheusStackFullname & {#config: #config}).result
	result: [if #config."hyperswitch-monitoring"."kube-prometheus-stack".prometheusOperator.fullnameOverride != "" {#config."hyperswitch-monitoring"."kube-prometheus-stack".prometheusOperator.fullnameOverride}, "\(fullname)-operator"][0]
}

#KubePrometheusStackOperatorServiceAccountName: {
	#config: #Config
	let kps = #config."hyperswitch-monitoring"."kube-prometheus-stack"
	let op = kps.prometheusOperator
	let fullname = (#KubePrometheusStackOperatorFullname & {#config: #config}).result
	result: string
	if op.serviceAccount.create && op.serviceAccount.name != "" {result: op.serviceAccount.name}
	if op.serviceAccount.create && op.serviceAccount.name == "" {result: fullname}
	if !op.serviceAccount.create && op.serviceAccount.name != "" {result: op.serviceAccount.name}
	if !op.serviceAccount.create && op.serviceAccount.name == "" {result: "default"}
}

#KubePrometheusStackOperatorLabels: {
	#config: #Config
	let labels = (#KubePrometheusStackLabels & {#config: #config}).result
	let chartName = (#KubePrometheusStackName & {#config: #config}).result
	result: labels & {
		app: "\(chartName)-operator"
	}
}

monitoringPrometheusOperator: {
	#config: #Config
	let mon = #config."hyperswitch-monitoring"
	let kps = mon."kube-prometheus-stack"
	let op = kps.prometheusOperator
	let fullname = (#KubePrometheusStackFullname & {#config: #config}).result
	let chartName = (#KubePrometheusStackName & {#config: #config}).result
	let opFullname = (#KubePrometheusStackOperatorFullname & {#config: #config}).result
	let opLabels = (#KubePrometheusStackOperatorLabels & {#config: #config}).result
	let opNamespace = [if kps.namespaceOverride != "" {kps.namespaceOverride}, #config.metadata.namespace][0]
	let opServiceAccountName = (#KubePrometheusStackOperatorServiceAccountName & {#config: #config}).result

	// 1. aggregate-clusterroles.yaml
	if mon.global.rbac.create && mon.global.rbac.createAggregateClusterRoles {
		"prometheus-crd-view-clusterrole": rbacv1.#ClusterRole & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRole"
			metadata: {
				name: "\(fullname)-prometheus-crd-view"
				labels: opLabels & {
					"rbac.authorization.k8s.io/aggregate-to-admin": "true"
					"rbac.authorization.k8s.io/aggregate-to-edit":  "true"
					"rbac.authorization.k8s.io/aggregate-to-view":  "true"
				}
			}
			rules: [{
				apiGroups: ["monitoring.coreos.com"]
				resources: ["alertmanagers", "alertmanagerconfigs", "podmonitors", "probes", "prometheuses", "prometheusagents", "prometheusrules", "scrapeconfigs", "servicemonitors"]
				verbs: ["get", "list", "watch"]
			}]
		}
		"prometheus-crd-edit-clusterrole": rbacv1.#ClusterRole & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRole"
			metadata: {
				name: "\(fullname)-prometheus-crd-edit"
				labels: opLabels & {
					"rbac.authorization.k8s.io/aggregate-to-edit":  "true"
					"rbac.authorization.k8s.io/aggregate-to-admin": "true"
				}
			}
			rules: [{
				apiGroups: ["monitoring.coreos.com"]
				resources: ["alertmanagers", "alertmanagerconfigs", "podmonitors", "probes", "prometheuses", "prometheusagents", "prometheusrules", "scrapeconfigs", "servicemonitors"]
				verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
			}]
		}
	}

	// 2. certmanager.yaml
	if op.admissionWebhooks.enabled && op.admissionWebhooks.certManager.enabled {
		if op.admissionWebhooks.certManager.issuerRef == _|_ {
			"self-signed-issuer": {
				apiVersion: "cert-manager.io/v1"
				kind:       "Issuer"
				metadata: {
					name:      "\(fullname)-self-signed-issuer"
					namespace: opNamespace
				}
				spec: selfSigned: {}
			}
			"root-cert": {
				apiVersion: "cert-manager.io/v1"
				kind:       "Certificate"
				metadata: {
					name:      "\(fullname)-root-cert"
					namespace: opNamespace
				}
				spec: {
					secretName: "\(fullname)-root-cert"
					duration: [if op.admissionWebhooks.certManager.rootCert.duration != "" {op.admissionWebhooks.certManager.rootCert.duration}, "43800h0m0s"][0]
					issuerRef: name: "\(fullname)-self-signed-issuer"
					commonName: "ca.webhook.kube-prometheus-stack"
					isCA:       true
				}
			}
			"root-issuer": {
				apiVersion: "cert-manager.io/v1"
				kind:       "Issuer"
				metadata: {
					name:      "\(fullname)-root-issuer"
					namespace: opNamespace
				}
				spec: ca: secretName: "\(fullname)-root-cert"
			}
		}
		"admission-cert": {
			apiVersion: "cert-manager.io/v1"
			kind:       "Certificate"
			metadata: {
				name:      "\(fullname)-admission"
				namespace: opNamespace
			}
			spec: {
				secretName: "\(fullname)-admission"
				duration: [if op.admissionWebhooks.certManager.admissionCert.duration != "" {op.admissionWebhooks.certManager.admissionCert.duration}, "8760h0m0s"][0]
				issuerRef: [if op.admissionWebhooks.certManager.issuerRef != _|_ {op.admissionWebhooks.certManager.issuerRef}, {name: "\(fullname)-root-issuer"}][0]
				dnsNames: [
					"\(opFullname).\(opNamespace).svc",
					"\(opFullname).\(opNamespace).svc.cluster.local",
				]
			}
		}
	}

	// 3. ciliumnetworkpolicy.yaml
	if op.networkPolicy.enabled && op.networkPolicy.flavor == "cilium" {
		"operator-cilium-networkpolicy": {
			apiVersion: "cilium.io/v2"
			kind:       "CiliumNetworkPolicy"
			metadata: {
				name:      opFullname
				namespace: opNamespace
				labels:    opLabels
			}
			spec: {
				endpointSelector: matchLabels: {
					if len(op.networkPolicy.matchLabels) > 0 {
						app: "\(chartName)-operator"
						op.networkPolicy.matchLabels
					}
					if len(op.networkPolicy.matchLabels) == 0 {
						opLabels
					}
				}
				egress: [
					if op.networkPolicy.cilium.egress != _|_ {
						for e in op.networkPolicy.cilium.egress {e}
					},
					if op.networkPolicy.cilium.egress == _|_ {
						{toEntities: ["kube-apiserver"]}
					},
				]
				ingress: [{
					toPorts: [{
						ports: [{
							port: [if op.tls.enabled {"\(op.tls.internalPort)"}, "8080"][0]
							protocol: "TCP"
						}]
						if !op.tls.enabled {
							rules: http: [{
								method: "GET"
								path:   "/metrics"
							}]
						}
					}]
				}]
			}
		}
	}

	// 4. clusterrole.yaml
	if op.enabled && mon.global.rbac.create {
		"operator-clusterrole": rbacv1.#ClusterRole & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRole"
			metadata: {
				name:   opFullname
				labels: opLabels
			}
			rules: [
				{
					apiGroups: ["monitoring.coreos.com"]
					resources: ["alertmanagers", "alertmanagers/finalizers", "alertmanagers/status", "alertmanagerconfigs", "prometheuses", "prometheuses/finalizers", "prometheuses/status", "prometheusagents", "prometheusagents/finalizers", "prometheusagents/status", "thanosrulers", "thanosrulers/finalizers", "thanosrulers/status", "scrapeconfigs", "servicemonitors", "podmonitors", "probes", "prometheusrules"]
					verbs: ["*"]
				},
				{
					apiGroups: ["apps"]
					resources: ["statefulsets"]
					verbs: ["*"]
				},
				{
					apiGroups: [""]
					resources: ["configmaps", "secrets"]
					verbs: ["*"]
				},
				{
					apiGroups: [""]
					resources: ["pods"]
					verbs: ["list", "delete"]
				},
				{
					apiGroups: [""]
					resources: ["services", "services/finalizers", "endpoints"]
					verbs: ["get", "create", "update", "delete"]
				},
				{
					apiGroups: [""]
					resources: ["nodes"]
					verbs: ["list", "watch"]
				},
				{
					apiGroups: [""]
					resources: ["namespaces"]
					verbs: ["get", "list", "watch"]
				},
				{
					apiGroups: [""]
					resources: ["events"]
					verbs: ["patch", "create"]
				},
				{
					apiGroups: ["networking.k8s.io"]
					resources: ["ingresses"]
					verbs: ["get", "list", "watch"]
				},
				{
					apiGroups: ["storage.k8s.io"]
					resources: ["storageclasses"]
					verbs: ["get"]
				},
				{
					apiGroups: ["discovery.k8s.io"]
					resources: ["endpointslices"]
					verbs: ["get", "list", "watch"]
				},
			]
		}
	}

	// 5. clusterrolebinding.yaml
	if op.enabled && mon.global.rbac.create {
		"operator-clusterrolebinding": rbacv1.#ClusterRoleBinding & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRoleBinding"
			metadata: {
				name:   opFullname
				labels: opLabels
			}
			roleRef: {
				apiGroup: "rbac.authorization.k8s.io"
				kind:     "ClusterRole"
				name:     opFullname
			}
			subjects: [{
				kind:      "ServiceAccount"
				name:      opServiceAccountName
				namespace: opNamespace
			}]
		}
	}

	// 6. deployment.yaml
	if op.enabled {
		"operator-deployment": appsv1.#Deployment & {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			metadata: {
				name:      opFullname
				namespace: opNamespace
				labels:    opLabels & op.labels
				if len(op.annotations) > 0 {
					annotations: op.annotations
				}
			}
			spec: {
				replicas:             1
				revisionHistoryLimit: op.revisionHistoryLimit
				selector: matchLabels: {
					app:     "\(chartName)-operator"
					release: opLabels.release
				}
				if op.strategy != _|_ {
					strategy: op.strategy
				}
				template: {
					metadata: {
						labels: opLabels & op.podLabels
						if len(op.podAnnotations) > 0 {
							annotations: op.podAnnotations
						}
					}
					spec: {
						if op.priorityClassName != "" {
							priorityClassName: op.priorityClassName
						}
						containers: [{
							name:            chartName
							image:           "\(op.image.registry)/\(op.image.repository):\(op.image.tag)"
							imagePullPolicy: op.image.pullPolicy
							args: [
								if op.kubeletService.enabled {
									"--kubelet-service=\(op.kubeletService.namespace)/\([if op.kubeletService.name != "" {op.kubeletService.name}, "\(fullname)-kubelet"][0])"
								},
								if op.kubeletService.enabled && op.kubeletService.selector != "" {
									"--kubelet-selector=\(op.kubeletService.selector)"
								},
								if op.logFormat != "" {
									"--log-format=\(op.logFormat)"
								},
								if op.logLevel != "" {
									"--log-level=\(op.logLevel)"
								},
								if len(op.denyNamespaces) > 0 {
									"--deny-namespaces=\(strings.Join(op.denyNamespaces, ","))"
								},
								if op.namespaces.releaseNamespace || len(op.namespaces.additional) > 0 {
									let nsList = [if op.namespaces.releaseNamespace {opNamespace}] + op.namespaces.additional
									"--namespaces=\(strings.Join(nsList, ","))"
								},
								if op.prometheusDefaultBaseImage != "" {
									"--prometheus-default-base-image=\([if mon.global.imageRegistry != "" {mon.global.imageRegistry}, op.prometheusDefaultBaseImageRegistry][0])/\(op.prometheusDefaultBaseImage)"
								},
								if op.alertmanagerDefaultBaseImage != "" {
									"--alertmanager-default-base-image=\([if mon.global.imageRegistry != "" {mon.global.imageRegistry}, op.alertmanagerDefaultBaseImageRegistry][0])/\(op.alertmanagerDefaultBaseImage)"
								},
								"--prometheus-config-reloader=\(op.prometheusConfigReloader.image.registry)/\(op.prometheusConfigReloader.image.repository):\(op.prometheusConfigReloader.image.tag)",
								"--config-reloader-cpu-request=\([if op.prometheusConfigReloader.resources.requests.cpu != _|_ {op.prometheusConfigReloader.resources.requests.cpu}, "0"][0])",
								"--config-reloader-cpu-limit=\([if op.prometheusConfigReloader.resources.limits.cpu != _|_ {op.prometheusConfigReloader.resources.limits.cpu}, "0"][0])",
								"--config-reloader-memory-request=\([if op.prometheusConfigReloader.resources.requests.memory != _|_ {op.prometheusConfigReloader.resources.requests.memory}, "0"][0])",
								"--config-reloader-memory-limit=\([if op.prometheusConfigReloader.resources.limits.memory != _|_ {op.prometheusConfigReloader.resources.limits.memory}, "0"][0])",
								if op.prometheusConfigReloader.enableProbe {
									"--enable-config-reloader-probes=true"
								},
								if len(op.alertmanagerInstanceNamespaces) > 0 {
									"--alertmanager-instance-namespaces=\(strings.Join(op.alertmanagerInstanceNamespaces, ","))"
								},
								if op.alertmanagerInstanceSelector != "" {
									"--alertmanager-instance-selector=\(op.alertmanagerInstanceSelector)"
								},
								if len(op.alertmanagerConfigNamespaces) > 0 {
									"--alertmanager-config-namespaces=\(strings.Join(op.alertmanagerConfigNamespaces, ","))"
								},
								if len(op.prometheusInstanceNamespaces) > 0 {
									"--prometheus-instance-namespaces=\(strings.Join(op.prometheusInstanceNamespaces, ","))"
								},
								if op.prometheusInstanceSelector != "" {
									"--prometheus-instance-selector=\(op.prometheusInstanceSelector)"
								},
								"--thanos-default-base-image=\(op.thanosImage.registry)/\(op.thanosImage.repository):\(op.thanosImage.tag)",
								if len(op.thanosRulerInstanceNamespaces) > 0 {
									"--thanos-ruler-instance-namespaces=\(strings.Join(op.thanosRulerInstanceNamespaces, ","))"
								},
								if op.thanosRulerInstanceSelector != "" {
									"--thanos-ruler-instance-selector=\(op.thanosRulerInstanceSelector)"
								},
								if op.secretFieldSelector != "" {
									"--secret-field-selector=\(op.secretFieldSelector)"
								},
								if op.clusterDomain != "" {
									"--cluster-domain=\(op.clusterDomain)"
								},
								if op.tls.enabled {
									"--web.enable-tls=true"
								},
								if op.tls.enabled {
									"--web.cert-file=/cert/\([if op.admissionWebhooks.certManager.enabled {"tls.crt"}, "cert"][0])"
								},
								if op.tls.enabled {
									"--web.key-file=/cert/\([if op.admissionWebhooks.certManager.enabled {"tls.key"}, "key"][0])"
								},
								if op.tls.enabled {
									"--web.listen-address=:\(op.tls.internalPort)"
								},
								if op.tls.enabled {
									"--web.tls-min-version=\(op.tls.tlsMinVersion)"
								},
							]
							ports: [{
								containerPort: [if op.tls.enabled {op.tls.internalPort}, 8080][0]
								name: [if op.tls.enabled {"https"}, "http"][0]
							}]
							if len(op.env) > 0 {
								env: [for k, v in op.env {{name: k, value: v}}]
							}
							resources: op.resources
							if op.containerSecurityContext != _|_ {
								securityContext: op.containerSecurityContext
							}
							volumeMounts: list.Concat([
								[if op.tls.enabled {
									{name: "tls-secret", mountPath: "/cert", readOnly: true}
								}],
								op.extraVolumeMounts,
							])
							if op.readinessProbe.enabled {
								readinessProbe: {
									httpGet: {
										path: "/healthz"
										port: [if op.tls.enabled {"https"}, "http"][0]
										scheme: [if op.tls.enabled {"HTTPS"}, "HTTP"][0]
									}
									initialDelaySeconds: op.readinessProbe.initialDelaySeconds
									periodSeconds:       op.readinessProbe.periodSeconds
									timeoutSeconds:      op.readinessProbe.timeoutSeconds
									successThreshold:    op.readinessProbe.successThreshold
									failureThreshold:    op.readinessProbe.failureThreshold
								}
							}
							if op.livenessProbe.enabled {
								livenessProbe: {
									httpGet: {
										path: "/healthz"
										port: [if op.tls.enabled {"https"}, "http"][0]
										scheme: [if op.tls.enabled {"HTTPS"}, "HTTP"][0]
									}
									initialDelaySeconds: op.livenessProbe.initialDelaySeconds
									periodSeconds:       op.livenessProbe.periodSeconds
									timeoutSeconds:      op.livenessProbe.timeoutSeconds
									successThreshold:    op.livenessProbe.successThreshold
									failureThreshold:    op.livenessProbe.failureThreshold
								}
							}
						}]
						volumes: list.Concat([
							[if op.tls.enabled {
								{
									name: "tls-secret"
									secret: {
										defaultMode: 420
										secretName:  "\(fullname)-admission"
									}
								}
							}],
							op.extraVolumes,
						])
						if op.dnsConfig != _|_ {
							dnsConfig: op.dnsConfig
						}
						if op.securityContext != _|_ {
							securityContext: op.securityContext
						}
						serviceAccountName:           opServiceAccountName
						automountServiceAccountToken: op.automountServiceAccountToken
						if op.hostNetwork {
							hostNetwork: true
							dnsPolicy:   "ClusterFirstWithHostNet"
						}
						nodeSelector: op.nodeSelector
						affinity:     op.affinity
						tolerations:  op.tolerations
					}
				}
			}
		}
	}

	// 7. networkpolicy.yaml
	if op.networkPolicy.enabled && op.networkPolicy.flavor == "kubernetes" {
		"operator-networkpolicy": {
			apiVersion: "networking.k8s.io/v1"
			kind:       "NetworkPolicy"
			metadata: {
				name:      opFullname
				namespace: opNamespace
				labels:    opLabels
			}
			spec: {
				egress: [{}]
				ingress: [{
					ports: [{
						port: [if op.tls.enabled {op.tls.internalPort}, 8080][0]
					}]
				}]
				policyTypes: ["Egress", "Ingress"]
				podSelector: matchLabels: {
					app:     "\(chartName)-operator"
					release: opLabels.release
					if len(op.networkPolicy.matchLabels) > 0 {
						op.networkPolicy.matchLabels
					}
				}
			}
		}
	}

	// 8. psp-clusterrole.yaml
	if op.enabled && mon.global.rbac.create && mon.global.rbac.pspEnabled {
		"operator-psp-clusterrole": rbacv1.#ClusterRole & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRole"
			metadata: {
				name:   "\(opFullname)-psp"
				labels: opLabels
			}
			rules: [{
				apiGroups: ["policy"]
				resources: ["podsecuritypolicies"]
				resourceNames: [opFullname]
				verbs: ["use"]
			}]
		}
	}

	// 9. psp-clusterrolebinding.yaml
	if op.enabled && mon.global.rbac.create && mon.global.rbac.pspEnabled {
		"operator-psp-clusterrolebinding": rbacv1.#ClusterRoleBinding & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRoleBinding"
			metadata: {
				name:   "\(opFullname)-psp"
				labels: opLabels
			}
			roleRef: {
				apiGroup: "rbac.authorization.k8s.io"
				kind:     "ClusterRole"
				name:     "\(opFullname)-psp"
			}
			subjects: [{
				kind:      "ServiceAccount"
				name:      opServiceAccountName
				namespace: opNamespace
			}]
		}
	}

	// 10. psp.yaml
	if op.enabled && mon.global.rbac.create && mon.global.rbac.pspEnabled {
		"operator-psp": {
			apiVersion: "policy/v1beta1"
			kind:       "PodSecurityPolicy"
			metadata: {
				name:   opFullname
				labels: opLabels
				if len(mon.global.rbac.pspAnnotations) > 0 {
					annotations: mon.global.rbac.pspAnnotations
				}
			}
			spec: {
				privileged: false
				volumes: ["configMap", "emptyDir", "projected", "secret", "downwardAPI", "persistentVolumeClaim"]
				hostNetwork: op.hostNetwork
				hostIPC:     false
				hostPID:     false
				runAsUser: rule:          "RunAsAny"
				seLinux: rule:            "RunAsAny"
				supplementalGroups: rule: "MustRunAs"
				supplementalGroups: ranges: [{min: 0, max: 65535}]
				fsGroup: rule: "MustRunAs"
				fsGroup: ranges: [{min: 0, max: 65535}]
				readOnlyRootFilesystem: false
			}
		}
	}

	// 11. service.yaml
	if op.enabled {
		"operator-service": corev1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      opFullname
				namespace: opNamespace
				labels:    opLabels & op.service.labels
				if len(op.service.annotations) > 0 {
					annotations: op.service.annotations
				}
			}
			spec: {
				if op.service.clusterIP != "" {
					clusterIP: op.service.clusterIP
				}
				if op.service.ipDualStack.enabled {
					ipFamilies:     op.service.ipDualStack.ipFamilies
					ipFamilyPolicy: op.service.ipDualStack.ipFamilyPolicy
				}
				if len(op.service.externalIPs) > 0 {
					externalIPs: op.service.externalIPs
				}
				if op.service.loadBalancerIP != "" {
					loadBalancerIP: op.service.loadBalancerIP
				}
				if len(op.service.loadBalancerSourceRanges) > 0 {
					loadBalancerSourceRanges: op.service.loadBalancerSourceRanges
				}
				if op.service.type != "ClusterIP" {
					externalTrafficPolicy: op.service.externalTrafficPolicy
				}
				ports: [
					if !op.tls.enabled {
						{
							name: "http"
							if op.service.type == "NodePort" {
								nodePort: op.service.nodePort
							}
							port:       8080
							targetPort: "http"
						}
					},
					if op.tls.enabled {
						{
							name: "https"
							if op.service.type == "NodePort" {
								nodePort: op.service.nodePortTls
							}
							port:       443
							targetPort: "https"
						}
					},
				]
				selector: {
					app:     "\(chartName)-operator"
					release: opLabels.release
				}
				type: op.service.type
			}
		}
	}

	// 12. serviceaccount.yaml
	if op.enabled && op.serviceAccount.create {
		"operator-serviceaccount": corev1.#ServiceAccount & {
			apiVersion: "v1"
			kind:       "ServiceAccount"
			metadata: {
				name:      opServiceAccountName
				namespace: opNamespace
				labels:    opLabels
				if len(op.serviceAccount.annotations) > 0 {
					annotations: op.serviceAccount.annotations
				}
			}
			automountServiceAccountToken: op.serviceAccount.automountServiceAccountToken
		}
	}

	// 13. servicemonitor.yaml
	if op.enabled && op.serviceMonitor.selfMonitor {
		"operator-servicemonitor": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "ServiceMonitor"
			metadata: {
				name:      opFullname
				namespace: opNamespace
				labels:    opLabels & op.serviceMonitor.additionalLabels
			}
			spec: {
				endpoints: [{
					if op.tls.enabled {
						port:   "https"
						scheme: "https"
						tlsConfig: {
							serverName: opFullname
							ca: secret: {
								name: "\(fullname)-admission"
								key: [if op.admissionWebhooks.certManager.enabled {"ca.crt"}, "ca"][0]
								optional: false
							}
						}
					}
					if !op.tls.enabled {
						port: "http"
					}
					honorLabels: true
					if op.serviceMonitor.interval != "" {
						interval: op.serviceMonitor.interval
					}
					if len(op.serviceMonitor.metricRelabelings) > 0 {
						metricRelabelings: op.serviceMonitor.metricRelabelings
					}
					if len(op.serviceMonitor.relabelings) > 0 {
						relabelings: op.serviceMonitor.relabelings
					}
				}]
				selector: matchLabels: {
					app:     "\(chartName)-operator"
					release: opLabels.release
				}
				namespaceSelector: matchNames: [opNamespace]
			}
		}
	}

	// 14. verticalpodautoscaler.yaml
	if op.verticalPodAutoscaler.enabled {
		"operator-vpa": {
			apiVersion: "autoscaling.k8s.io/v1"
			kind:       "VerticalPodAutoscaler"
			metadata: {
				name:      opFullname
				namespace: opNamespace
				labels:    opLabels
			}
			spec: {
				if len(op.verticalPodAutoscaler.recommenders) > 0 {
					recommenders: op.verticalPodAutoscaler.recommenders
				}
				resourcePolicy: containerPolicies: [{
					containerName: chartName
					if len(op.verticalPodAutoscaler.controlledResources) > 0 {
						controlledResources: op.verticalPodAutoscaler.controlledResources
					}
					if op.verticalPodAutoscaler.controlledValues != "" {
						controlledValues: op.verticalPodAutoscaler.controlledValues
					}
					if len(op.verticalPodAutoscaler.maxAllowed) > 0 {
						maxAllowed: op.verticalPodAutoscaler.maxAllowed
					}
					if len(op.verticalPodAutoscaler.minAllowed) > 0 {
						minAllowed: op.verticalPodAutoscaler.minAllowed
					}
				}]
				targetRef: {
					apiVersion: "apps/v1"
					kind:       "Deployment"
					name:       opFullname
				}
				if op.verticalPodAutoscaler.updatePolicy != _|_ {
					updatePolicy: op.verticalPodAutoscaler.updatePolicy
				}
			}
		}
	}
}
