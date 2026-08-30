package templates

import (
	"strings"
	corev1 "k8s.io/api/core/v1"
	rbacv1 "k8s.io/api/rbac/v1"
	appsv1 "k8s.io/api/apps/v1"
)

#LokiGrafanaAgentOperatorName: {
	#config: #Config
	let gao = #config."hyperswitch-monitoring"."grafana-agent-operator"
	result: strings.Slice([if gao.nameOverride != "" {gao.nameOverride}, "grafana-agent-operator"][0], 0, 63)
}

#LokiGrafanaAgentOperatorFullname: {
	#config: #Config
	let gao = #config."hyperswitch-monitoring"."grafana-agent-operator"
	let name = (#LokiGrafanaAgentOperatorName & {#config: #config}).result
	let fullname = [
		if gao.fullnameOverride != "" {gao.fullnameOverride},
		if strings.Contains(#config.metadata.name, name) {#config.metadata.name},
		"\(#config.metadata.name)-\(name)",
	][0]
	result: strings.TrimSuffix(strings.Slice(fullname, 0, 63), "-")
}

#LokiGrafanaAgentOperatorLabels: {
	#config: #Config
	let name = (#LokiGrafanaAgentOperatorName & {#config: #config}).result
	result: {
		"app.kubernetes.io/name":       name
		"app.kubernetes.io/instance":   #config.metadata.name
		"app.kubernetes.io/managed-by": #config.metadata.name
		"app.kubernetes.io/component":  "operator"
		"helm.sh/chart":                "grafana-agent-operator-0.3.15"
	}
}

#LokiGrafanaAgentOperatorSelectorLabels: {
	#config: #Config
	let name = (#LokiGrafanaAgentOperatorName & {#config: #config}).result
	result: {
		"app.kubernetes.io/name":     name
		"app.kubernetes.io/instance": #config.metadata.name
	}
}

#LokiGrafanaAgentOperatorServiceAccountName: {
	#config: #Config
	let gao = #config."hyperswitch-monitoring"."grafana-agent-operator"
	let fullname = (#LokiGrafanaAgentOperatorFullname & {#config: #config}).result
	result: [
		if gao.serviceAccount.create {
			[if gao.serviceAccount.name != "" {gao.serviceAccount.name}, fullname][0]
		},
		[if gao.serviceAccount.name != "" {gao.serviceAccount.name}, "default"][0],
	][0]
}

monitoringLokiGrafanaAgentOperator: {
	#config: #Config
	let loki = #config."hyperswitch-monitoring".loki
	let gao = #config."hyperswitch-monitoring"."grafana-agent-operator"
	let fullname = (#LokiGrafanaAgentOperatorFullname & {#config: #config}).result
	let _labels = (#LokiGrafanaAgentOperatorLabels & {#config: #config}).result
	let _selectorLabels = (#LokiGrafanaAgentOperatorSelectorLabels & {#config: #config}).result
	let saName = (#LokiGrafanaAgentOperatorServiceAccountName & {#config: #config}).result
	let ns = #config.metadata.namespace

	if loki.enabled && loki.monitoring.selfMonitoring.grafanaAgent.installOperator {
		// 1. operator-clusterrole.yaml
		if gao.rbac.create {
			"#1-clusterrole": rbacv1.#ClusterRole & {
				apiVersion: "rbac.authorization.k8s.io/v1"
				kind:       "ClusterRole"
				metadata: {
					name:   fullname
					labels: _labels
				}
				rules: [
					{
						apiGroups: ["monitoring.grafana.com"]
						resources: [
							"grafanaagents",
							"metricsinstances",
							"logsinstances",
							"podlogs",
							"integrations",
						]
						verbs: ["get", "list", "watch"]
					},
					{
						apiGroups: ["monitoring.grafana.com"]
						resources: [
							"grafanaagents/finalizers",
							"metricsinstances/finalizers",
							"logsinstances/finalizers",
							"podlogs/finalizers",
							"integrations/finalizers",
						]
						verbs: ["get", "list", "watch", "update"]
					},
					{
						apiGroups: ["monitoring.coreos.com"]
						resources: [
							"podmonitors",
							"probes",
							"servicemonitors",
						]
						verbs: ["get", "list", "watch"]
					},
					{
						apiGroups: ["monitoring.coreos.com"]
						resources: [
							"podmonitors/finalizers",
							"probes/finalizers",
							"servicemonitors/finalizers",
						]
						verbs: ["get", "list", "watch", "update"]
					},
					{
						apiGroups: [""]
						resources: [
							"namespaces",
							"nodes",
						]
						verbs: ["get", "list", "watch"]
					},
					{
						apiGroups: [""]
						resources: [
							"secrets",
							"services",
							"configmaps",
							"endpoints",
						]
						verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
					},
					{
						apiGroups: ["apps"]
						resources: [
							"statefulsets",
							"daemonsets",
							"deployments",
						]
						verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
					},
					if gao.rbac.podSecurityPolicyName != "" {
						{
							apiGroups: ["policy"]
							resources: ["podsecuritypolicies"]
							verbs: ["use"]
							resourceNames: [gao.rbac.podSecurityPolicyName]
						}
					},
				]
			}

			// 2. operator-clusterrolebinding.yaml
			"#2-clusterrolebinding": rbacv1.#ClusterRoleBinding & {
				apiVersion: "rbac.authorization.k8s.io/v1"
				kind:       "ClusterRoleBinding"
				metadata: {
					name:   fullname
					labels: _labels
				}
				roleRef: {
					apiGroup: "rbac.authorization.k8s.io"
					kind:     "ClusterRole"
					name:     fullname
				}
				subjects: [
					{
						kind:      "ServiceAccount"
						name:      saName
						namespace: ns
					},
				]
			}
		}

		// 3. operator-serviceaccount.yaml
		if gao.serviceAccount.create {
			"#3-serviceaccount": corev1.#ServiceAccount & {
				apiVersion: "v1"
				kind:       "ServiceAccount"
				metadata: {
					name:      saName
					namespace: ns
					labels:    _labels
				}
			}
		}

		// 4. operator-deployment.yaml
		"#4-deployment": appsv1.#Deployment & {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			metadata: {
				name:      fullname
				namespace: ns
				labels:    _labels
				if len(gao.annotations) > 0 {
					annotations: gao.annotations
				}
			}
			spec: {
				replicas: 1
				selector: matchLabels: _selectorLabels
				template: {
					metadata: {
						labels: _selectorLabels & gao.podLabels
						if len(gao.podAnnotations) > 0 {
							annotations: gao.podAnnotations
						}
					}
					spec: {
						if gao.priorityClassName != "" {
							priorityClassName: gao.priorityClassName
						}
						serviceAccountName: saName
						if gao.podSecurityContext != _|_ {
							securityContext: gao.podSecurityContext
						}
						containers: [
							{
								name: (#LokiGrafanaAgentOperatorName & {#config: #config}).result
								image:           "\(gao.image.registry)/\(gao.image.repository):\(gao.image.tag)"
								imagePullPolicy: gao.image.pullPolicy
								if gao.containerSecurityContext != _|_ {
									securityContext: gao.containerSecurityContext
								}
								if gao.resources != _|_ {
									resources: gao.resources
								}
								if (gao.kubeletService.namespace != "" && gao.kubeletService.serviceName != "") || len(gao.extraArgs) > 0 {
									args: [
										if gao.kubeletService.namespace != "" && gao.kubeletService.serviceName != "" {
											"--kubelet-service=\(gao.kubeletService.namespace)/\(gao.kubeletService.serviceName)"
										},
										for arg in gao.extraArgs {
											arg
										},
									]
								}
							},
						]
						if len(gao.image.pullSecrets) > 0 {
							imagePullSecrets: [
								for s in gao.image.pullSecrets {
									{name: s}
								},
							]
						}
						if len(gao.hostAliases) > 0 {
							hostAliases: gao.hostAliases
						}
						if len(gao.nodeSelector) > 0 {
							nodeSelector: gao.nodeSelector
						}
						if len(gao.tolerations) > 0 {
							tolerations: gao.tolerations
						}
						if gao.affinity != _|_ {
							affinity: gao.affinity
						}
					}
				}
			}
		}
	}
}
