package templates

import (
	"list"
	"strings"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	rbacv1 "k8s.io/api/rbac/v1"
)

#KubeStateMetricsName: {
	#config: #Config
	let ksm = #config."hyperswitch-monitoring"."kube-prometheus-stack"."kube-state-metrics"

	// Mirrors the Helm "kube-state-metrics.name" helper:
	// use nameOverride when set, otherwise use the chart name.
	result: [if ksm.nameOverride != "" {ksm.nameOverride}, "kube-state-metrics"][0]
}

#KubeStateMetricsFullname: {
	#config: #Config
	let ksm = #config."hyperswitch-monitoring"."kube-prometheus-stack"."kube-state-metrics"
	let name = (#KubeStateMetricsName & {#config: #config}).result

	// Mirrors the Helm "kube-state-metrics.fullname" helper:
	// use fullnameOverride when set, otherwise prefix the chart name with the Timoni instance name.
	result: [if ksm.fullnameOverride != "" {ksm.fullnameOverride}, "\(#config.metadata.name)-\(name)"][0]
}

#KubeStateMetricsSelectorLabels: {
	#config: #Config
	let ksm = #config."hyperswitch-monitoring"."kube-prometheus-stack"."kube-state-metrics"
	let name = (#KubeStateMetricsName & {#config: #config}).result

	// Mirrors the Helm "kube-state-metrics.selectorLabels" helper:
	// selectorOverride wins, otherwise use app name and instance labels.
	result: [if len(ksm.selectorOverride) > 0 {ksm.selectorOverride}, {"app.kubernetes.io/name": name, "app.kubernetes.io/instance": #config.metadata.name}][0]
}

#KubeStateMetricsLabels: {
	#config: #Config
	let ksm = #config."hyperswitch-monitoring"."kube-prometheus-stack"."kube-state-metrics"
	let name = (#KubeStateMetricsName & {#config: #config}).result

	// Mirrors the Helm "kube-state-metrics.labels" helper:
	// standard chart labels plus selector labels, customLabels, and optional release label.
	result: (#KubeStateMetricsSelectorLabels & {#config: #config}).result & ksm.customLabels & {
		"helm.sh/chart":                "kube-state-metrics-5.25.1"
		"app.kubernetes.io/managed-by": "timoni"
		"app.kubernetes.io/component":  "metrics"
		"app.kubernetes.io/part-of":    name
		"app.kubernetes.io/version":    "2.13.0"
		if ksm.releaseLabel {release: #config.metadata.name}
	}
}

#KubeStateMetricsServiceAccountName: {
	#config: #Config
	let ksm = #config."hyperswitch-monitoring"."kube-prometheus-stack"."kube-state-metrics"
	let fullname = (#KubeStateMetricsFullname & {#config: #config}).result

	// Mirrors the Helm "kube-state-metrics.serviceAccountName" helper:
	// generated fullname when creating a service account, otherwise default or explicit name.
	result: string
	if ksm.serviceAccount.create && ksm.serviceAccount.name != "" {result: ksm.serviceAccount.name}
	if ksm.serviceAccount.create && ksm.serviceAccount.name == "" {result: fullname}
	if !ksm.serviceAccount.create && ksm.serviceAccount.name != "" {result: ksm.serviceAccount.name}
	if !ksm.serviceAccount.create && ksm.serviceAccount.name == "" {result: "default"}
}

#KubeStateMetricsImage: {
	#config: #Config
	let ksm = #config."hyperswitch-monitoring"."kube-prometheus-stack"."kube-state-metrics"
	let registry = [if ksm.global.imageRegistry != "" {ksm.global.imageRegistry}, ksm.image.registry][0]
	let tag = [if ksm.image.tag != "" {ksm.image.tag}, "v2.13.0"][0]

	// Mirrors the Helm "kube-state-metrics.image" helper:
	// build image reference from registry, repository, tag/appVersion fallback, and optional digest.
	result: [if ksm.image.sha != "" {"\(registry)/\(ksm.image.repository):\(tag)@\(ksm.image.sha)"}, "\(registry)/\(ksm.image.repository):\(tag)"][0]
}

#KubeStateMetricsRBACRules: {
	#config: #Config
	let ksm = #config."hyperswitch-monitoring"."kube-prometheus-stack"."kube-state-metrics"
	let collectors = ksm.collectors

	// Mirrors templates/role.yaml:
	// emit one RBAC rule per enabled collector, plus proxy/custom-resource/extra rules.
	result: [
		if list.Contains(collectors, "certificatesigningrequests") {apiGroups: ["certificates.k8s.io"], resources: ["certificatesigningrequests"], verbs: ["list", "watch"]},
		if list.Contains(collectors, "configmaps") {apiGroups: [""], resources: ["configmaps"], verbs: ["list", "watch"]},
		if list.Contains(collectors, "cronjobs") {apiGroups: ["batch"], resources: ["cronjobs"], verbs: ["list", "watch"]},
		if list.Contains(collectors, "daemonsets") {apiGroups: ["extensions", "apps"], resources: ["daemonsets"], verbs: ["list", "watch"]},
		if list.Contains(collectors, "deployments") {apiGroups: ["extensions", "apps"], resources: ["deployments"], verbs: ["list", "watch"]},
		if list.Contains(collectors, "endpoints") {apiGroups: [""], resources: ["endpoints"], verbs: ["list", "watch"]},
		if list.Contains(collectors, "endpointslices") {apiGroups: ["discovery.k8s.io"], resources: ["endpointslices"], verbs: ["list", "watch"]},
		if list.Contains(collectors, "horizontalpodautoscalers") {apiGroups: ["autoscaling"], resources: ["horizontalpodautoscalers"], verbs: ["list", "watch"]},
		if list.Contains(collectors, "ingresses") {apiGroups: ["extensions", "networking.k8s.io"], resources: ["ingresses"], verbs: ["list", "watch"]},
		if list.Contains(collectors, "jobs") {apiGroups: ["batch"], resources: ["jobs"], verbs: ["list", "watch"]},
		if list.Contains(collectors, "leases") {apiGroups: ["coordination.k8s.io"], resources: ["leases"], verbs: ["list", "watch"]},
		if list.Contains(collectors, "limitranges") {apiGroups: [""], resources: ["limitranges"], verbs: ["list", "watch"]},
		if list.Contains(collectors, "mutatingwebhookconfigurations") {apiGroups: ["admissionregistration.k8s.io"], resources: ["mutatingwebhookconfigurations"], verbs: ["list", "watch"]},
		if list.Contains(collectors, "namespaces") {apiGroups: [""], resources: ["namespaces"], verbs: ["list", "watch"]},
		if list.Contains(collectors, "networkpolicies") {apiGroups: ["networking.k8s.io"], resources: ["networkpolicies"], verbs: ["list", "watch"]},
		if list.Contains(collectors, "nodes") {apiGroups: [""], resources: ["nodes"], verbs: ["list", "watch"]},
		if list.Contains(collectors, "persistentvolumeclaims") {apiGroups: [""], resources: ["persistentvolumeclaims"], verbs: ["list", "watch"]},
		if list.Contains(collectors, "persistentvolumes") {apiGroups: [""], resources: ["persistentvolumes"], verbs: ["list", "watch"]},
		if list.Contains(collectors, "poddisruptionbudgets") {apiGroups: ["policy"], resources: ["poddisruptionbudgets"], verbs: ["list", "watch"]},
		if list.Contains(collectors, "pods") {apiGroups: [""], resources: ["pods"], verbs: ["list", "watch"]},
		if list.Contains(collectors, "replicasets") {apiGroups: ["extensions", "apps"], resources: ["replicasets"], verbs: ["list", "watch"]},
		if list.Contains(collectors, "replicationcontrollers") {apiGroups: [""], resources: ["replicationcontrollers"], verbs: ["list", "watch"]},
		if list.Contains(collectors, "resourcequotas") {apiGroups: [""], resources: ["resourcequotas"], verbs: ["list", "watch"]},
		if list.Contains(collectors, "secrets") {apiGroups: [""], resources: ["secrets"], verbs: ["list", "watch"]},
		if list.Contains(collectors, "services") {apiGroups: [""], resources: ["services"], verbs: ["list", "watch"]},
		if list.Contains(collectors, "statefulsets") {apiGroups: ["apps"], resources: ["statefulsets"], verbs: ["list", "watch"]},
		if list.Contains(collectors, "storageclasses") {apiGroups: ["storage.k8s.io"], resources: ["storageclasses"], verbs: ["list", "watch"]},
		if list.Contains(collectors, "validatingwebhookconfigurations") {apiGroups: ["admissionregistration.k8s.io"], resources: ["validatingwebhookconfigurations"], verbs: ["list", "watch"]},
		if list.Contains(collectors, "volumeattachments") {apiGroups: ["storage.k8s.io"], resources: ["volumeattachments"], verbs: ["list", "watch"]},
		if ksm.kubeRBACProxy.enabled {apiGroups: ["authentication.k8s.io"], resources: ["tokenreviews"], verbs: ["create"]},
		if ksm.kubeRBACProxy.enabled {apiGroups: ["authorization.k8s.io"], resources: ["subjectaccessreviews"], verbs: ["create"]},
		if ksm.customResourceState.enabled {apiGroups: ["apiextensions.k8s.io"], resources: ["customresourcedefinitions"], verbs: ["list", "watch"]},
		for r in ksm.rbac.extraRules {r},
	]
}

// Registry for kube-state-metrics rendered objects; the let bindings below cache Helm helper equivalents and shared values used by every converted template.
monitoringKubeStateMetrics: {
	#config: #Config
	let ksm = #config."hyperswitch-monitoring"."kube-prometheus-stack"."kube-state-metrics"
	let fullname = (#KubeStateMetricsFullname & {#config: #config}).result
	let ksmNamespace = [if ksm.namespaceOverride != "" {ksm.namespaceOverride}, #config.metadata.namespace][0]
	let ksmLabels = (#KubeStateMetricsLabels & {#config: #config}).result
	let selectorLabels = (#KubeStateMetricsSelectorLabels & {#config: #config}).result
	let ksmServiceAccountName = (#KubeStateMetricsServiceAccountName & {#config: #config}).result
	let servicePort = [if ksm.kubeRBACProxy.enabled {9090}, ksm.service.port][0]
	let telemetryPort = [if ksm.kubeRBACProxy.enabled {9091}, ksm.selfMonitor.telemetryPort][0]

	// 1. templates/ciliumnetworkpolicy.yaml
	if ksm.networkPolicy.enabled && ksm.networkPolicy.flavor == "cilium" {
		"ciliumnetworkpolicy": {
			apiVersion: "cilium.io/v2"
			kind:       "CiliumNetworkPolicy"
			metadata: {name: fullname, namespace: ksmNamespace, labels: ksmLabels, if len(ksm.annotations) > 0 {annotations: ksm.annotations}}
			spec: {
				endpointSelector: matchLabels: selectorLabels
				egress: [if len(ksm.networkPolicy.cilium.kubeApiServerSelector) > 0 {ksm.networkPolicy.cilium.kubeApiServerSelector}, {toEntities: ["kube-apiserver"]}][0]
				ingress: [{toPorts: [{ports: [{port: "\(ksm.service.port)", protocol: "TCP"}, if ksm.selfMonitor.enabled {port: "\(ksm.selfMonitor.telemetryPort)", protocol: "TCP"}]}]}]
			}
		}
	}

	// 2. templates/clusterrolebinding.yaml
	if ksm.rbac.create && ksm.rbac.useClusterRole {
		"clusterrolebinding": rbacv1.#ClusterRoleBinding & {apiVersion: "rbac.authorization.k8s.io/v1", kind: "ClusterRoleBinding", metadata: {name: fullname, labels: ksmLabels}, roleRef: {apiGroup: "rbac.authorization.k8s.io", kind: "ClusterRole", name: [if ksm.rbac.useExistingRole != "" {ksm.rbac.useExistingRole}, fullname][0]}, subjects: [{kind: "ServiceAccount", name: ksmServiceAccountName, namespace: ksmNamespace}]}
	}

	// 3. templates/crs-configmap.yaml
	if ksm.customResourceState.enabled {
		"crs-configmap": corev1.#ConfigMap & {
			apiVersion: "v1"
			kind:       "ConfigMap"
			metadata: {name: "\(fullname)-customresourcestate-config", namespace: ksmNamespace, labels: ksmLabels, if len(ksm.annotations) > 0 {annotations: ksm.annotations}}
			data: "config.yaml": "\(ksm.customResourceState.config)"
		}
	}

	// 4. templates/deployment.yaml
	"workload": appsv1.#Deployment & {
		apiVersion: "apps/v1"
		kind:       "Deployment"
		metadata: {name: fullname, namespace: ksmNamespace, labels: ksmLabels, if len(ksm.annotations) > 0 {annotations: ksm.annotations}}
		spec: {
			selector: matchLabels: selectorLabels
			replicas: ksm.replicas
			strategy: type: [if ksm.updateStrategy != "" {ksm.updateStrategy}, "RollingUpdate"][0]
			revisionHistoryLimit: ksm.revisionHistoryLimit
			template: {
				metadata: {labels: ksmLabels & ksm.podLabels, if len(ksm.podAnnotations) > 0 {annotations: ksm.podAnnotations}}
				spec: {
					automountServiceAccountToken: ksm.automountServiceAccountToken
					hostNetwork:                  ksm.hostNetwork
					serviceAccountName:           ksmServiceAccountName
					if ksm.securityContext.enabled {securityContext: ksm.securityContext.value}
					if ksm.priorityClassName != "" {priorityClassName: ksm.priorityClassName}
					if len(ksm.initContainers) > 0 {initContainers: ksm.initContainers}
					containers: [{
						name: (#KubeStateMetricsName & {#config: #config}).result
						args: list.Concat([ksm.extraArgs, ["--port=\(servicePort)"], [if len(ksm.collectors) > 0 {"--resources=\(strings.Join(ksm.collectors, ","))"}], [if len(ksm.metricLabelsAllowlist) > 0 {"--metric-labels-allowlist=\(strings.Join(ksm.metricLabelsAllowlist, ","))"}], [if len(ksm.metricAnnotationsAllowList) > 0 {"--metric-annotations-allowlist=\(strings.Join(ksm.metricAnnotationsAllowList, ","))"}], [if len(ksm.metricAllowlist) > 0 {"--metric-allowlist=\(strings.Join(ksm.metricAllowlist, ","))"}], [if len(ksm.metricDenylist) > 0 {"--metric-denylist=\(strings.Join(ksm.metricDenylist, ","))"}], [if len(ksm.namespaces) > 0 {"--namespaces=\(strings.Join(ksm.namespaces, ","))"}], [if len(ksm.namespacesDenylist) > 0 {"--namespaces-denylist=\(strings.Join(ksm.namespacesDenylist, ","))"}], [if ksm.kubeconfig.enabled {"--kubeconfig=/opt/k8s/.kube/config"}], [if ksm.customResourceState.enabled {"--custom-resource-state-config-file=/etc/customresourcestate/config.yaml"}]])
						if ksm.kubeconfig.enabled || ksm.customResourceState.enabled || len(ksm.volumeMounts) > 0 {
							volumeMounts: [
								if ksm.kubeconfig.enabled {{name: "kubeconfig", mountPath: "/opt/k8s/.kube/", readOnly: true}},
								if ksm.customResourceState.enabled {{name: "customresourcestate-config", mountPath: "/etc/customresourcestate", readOnly: true}},
								for vm in ksm.volumeMounts {vm},
							]
						}
						imagePullPolicy: ksm.image.pullPolicy
						image: (#KubeStateMetricsImage & {#config: #config}).result
						ports: [{containerPort: ksm.service.port, name: "http"}, if ksm.selfMonitor.enabled {containerPort: telemetryPort, name: "metrics"}]
						if ksm.startupProbe.enabled {startupProbe: ksm.startupProbe.value & {httpGet: {path: "/healthz", port: servicePort, scheme: ksm.startupProbe.httpGet.scheme, httpHeaders: ksm.startupProbe.httpGet.httpHeaders, if ksm.hostNetwork {host: "127.0.0.1"}}}}
						livenessProbe: ksm.livenessProbe.value & {httpGet: {path: "/livez", port: servicePort, scheme: ksm.livenessProbe.httpGet.scheme, httpHeaders: ksm.livenessProbe.httpGet.httpHeaders, if ksm.hostNetwork {host: "127.0.0.1"}}}
						readinessProbe: ksm.readinessProbe.value & {httpGet: {path: "/readyz", port: servicePort, scheme: ksm.readinessProbe.httpGet.scheme, httpHeaders: ksm.readinessProbe.httpGet.httpHeaders, if ksm.hostNetwork {host: "127.0.0.1"}}}
						resources: ksm.resources
						if len(ksm.containerSecurityContext) > 0 {securityContext: ksm.containerSecurityContext}
					}, for c in ksm.containers {c}]
					if len(ksm.imagePullSecrets) > 0 {imagePullSecrets: ksm.imagePullSecrets}
					if len(ksm.affinity) > 0 {affinity: ksm.affinity}
					if len(ksm.nodeSelector) > 0 {nodeSelector: ksm.nodeSelector}
					if len(ksm.tolerations) > 0 {tolerations: ksm.tolerations}
					if len(ksm.topologySpreadConstraints) > 0 {topologySpreadConstraints: ksm.topologySpreadConstraints}
					if ksm.kubeconfig.enabled || ksm.customResourceState.enabled || len(ksm.volumes) > 0 {
						volumes: [
							if ksm.kubeconfig.enabled {{name: "kubeconfig", secret: {secretName: "\(fullname)-kubeconfig"}}},
							if ksm.customResourceState.enabled {{name: "customresourcestate-config", configMap: {name: "\(fullname)-customresourcestate-config"}}},
							for v in ksm.volumes {v},
						]
					}
				}
			}
		}
	}

	// 5. templates/extra-manifests.yaml
	for i, manifest in ksm.extraManifests {
		"extra-manifest-\(i)": manifest
	}

	// 6. templates/kubeconfig-secret.yaml
	if ksm.kubeconfig.enabled {
		"kubeconfig-secret": corev1.#Secret & {
			apiVersion: "v1"
			kind:       "Secret"
			metadata: {name: "\(fullname)-kubeconfig", namespace: ksmNamespace, labels: ksmLabels}
			type: "Opaque"
			data: config: ksm.kubeconfig.secret
		}
	}

	// 7. templates/networkpolicy.yaml
	if ksm.networkPolicy.enabled && ksm.networkPolicy.flavor == "kubernetes" {
		"networkpolicy": {
			apiVersion: "networking.k8s.io/v1"
			kind:       "NetworkPolicy"
			metadata: {name: fullname, namespace: ksmNamespace, labels: ksmLabels, if len(ksm.annotations) > 0 {annotations: ksm.annotations}}
			spec: {
				if len(ksm.networkPolicy.egress) > 0 {egress: ksm.networkPolicy.egress}
				ingress: [if len(ksm.networkPolicy.ingress) > 0 {ksm.networkPolicy.ingress}, [{ports: [{port: ksm.service.port, protocol: "TCP"}, if ksm.selfMonitor.enabled {port: telemetryPort, protocol: "TCP"}]}]][0]
				podSelector: [if len(ksm.networkPolicy.podSelector) > 0 {ksm.networkPolicy.podSelector}, {matchLabels: selectorLabels}][0]
				policyTypes: ["Ingress", "Egress"]
			}
		}
	}

	// 8. templates/pdb.yaml
	if len(ksm.podDisruptionBudget) > 0 {
		"pdb": {
			apiVersion: "policy/v1"
			kind:       "PodDisruptionBudget"
			metadata: {name: fullname, namespace: ksmNamespace, labels: ksmLabels}
			spec: ksm.podDisruptionBudget & {selector: matchLabels: {"app.kubernetes.io/name": (#KubeStateMetricsName & {#config: #config}).result}}
		}
	}

	// 9. templates/podsecuritypolicy.yaml
	if ksm.podSecurityPolicy.enabled {
		"podsecuritypolicy": {
			apiVersion: "policy/v1beta1"
			kind:       "PodSecurityPolicy"
			metadata: {name: fullname, labels: ksmLabels, if len(ksm.podSecurityPolicy.annotations) > 0 {annotations: ksm.podSecurityPolicy.annotations}}
			spec: {
				privileged: false
				volumes: list.Concat([["secret"], ksm.podSecurityPolicy.additionalVolumes])
				hostNetwork: false
				hostIPC:     false
				hostPID:     false
				runAsUser: rule: "MustRunAsNonRoot"
				seLinux: rule:   "RunAsAny"
				supplementalGroups: {rule: "MustRunAs", ranges: [{min: 1, max: 65535}]}
				fsGroup: {rule: "MustRunAs", ranges: [{min: 1, max: 65535}]}
				readOnlyRootFilesystem: false
			}
		}
	}

	// 10. templates/psp-clusterrole.yaml
	if ksm.podSecurityPolicy.enabled {
		"psp-clusterrole": rbacv1.#ClusterRole & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRole"
			metadata: {name: "psp-\(fullname)", labels: ksmLabels}
			rules: [{apiGroups: ["policy"], resources: ["podsecuritypolicies"], verbs: ["use"], resourceNames: [fullname]}]
		}
	}

	// 11. templates/psp-clusterrolebinding.yaml
	if ksm.podSecurityPolicy.enabled {
		"psp-clusterrolebinding": rbacv1.#ClusterRoleBinding & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRoleBinding"
			metadata: {name: "psp-\(fullname)", labels: ksmLabels}
			roleRef: {apiGroup: "rbac.authorization.k8s.io", kind: "ClusterRole", name: "psp-\(fullname)"}
			subjects: [{kind: "ServiceAccount", name: ksmServiceAccountName, namespace: ksmNamespace}]
		}
	}

	// 12. templates/rbac-configmap.yaml
	if ksm.kubeRBACProxy.enabled {
		"rbac-configmap": corev1.#ConfigMap & {
			apiVersion: "v1"
			kind:       "ConfigMap"
			metadata: {name: "\(fullname)-rbac-config", namespace: ksmNamespace, labels: ksmLabels, if len(ksm.annotations) > 0 {annotations: ksm.annotations}}
			data: "config-file.yaml": "authorization:\n  resourceAttributes:\n    namespace: \(ksmNamespace)\n    apiVersion: v1\n    resource: services\n    subresource: \(fullname)\n    name: \(fullname)\n"
		}
	}

	// 13. templates/role.yaml
	if ksm.rbac.create && ksm.rbac.useClusterRole && ksm.rbac.useExistingRole == "" {
		"clusterrole": rbacv1.#ClusterRole & {apiVersion: "rbac.authorization.k8s.io/v1", kind: "ClusterRole", metadata: {name: fullname, labels: ksmLabels}, rules: (#KubeStateMetricsRBACRules & {#config: #config}).result}
	}
	if ksm.rbac.create && !ksm.rbac.useClusterRole && ksm.rbac.useExistingRole == "" {
		for ns in ksm.namespaces {
			"role-\(ns)": rbacv1.#Role & {apiVersion: "rbac.authorization.k8s.io/v1", kind: "Role", metadata: {name: fullname, namespace: ns, labels: ksmLabels}, rules: (#KubeStateMetricsRBACRules & {#config: #config}).result}
		}
	}

	// 14. templates/rolebinding.yaml
	if ksm.rbac.create && !ksm.rbac.useClusterRole {
		for ns in ksm.namespaces {
			"rolebinding-\(ns)": rbacv1.#RoleBinding & {apiVersion: "rbac.authorization.k8s.io/v1", kind: "RoleBinding", metadata: {name: fullname, namespace: ns, labels: ksmLabels}, roleRef: {apiGroup: "rbac.authorization.k8s.io", kind: "Role", name: [if ksm.rbac.useExistingRole != "" {ksm.rbac.useExistingRole}, fullname][0]}, subjects: [{kind: "ServiceAccount", name: ksmServiceAccountName, namespace: ksmNamespace}]}
		}
	}

	// 15. templates/service.yaml
	"service": corev1.#Service & {
		apiVersion: "v1"
		kind:       "Service"
		metadata: {name: fullname, namespace: ksmNamespace, labels: ksmLabels, annotations: ksm.service.annotations & {if ksm.prometheusScrape {"prometheus.io/scrape": "true"}}}
		spec: {
			type: ksm.service.type
			if ksm.service.ipDualStack.enabled {ipFamilies: ksm.service.ipDualStack.ipFamilies, ipFamilyPolicy: ksm.service.ipDualStack.ipFamilyPolicy}
			ports: [{name: "http", protocol: "TCP", port: ksm.service.port, targetPort: ksm.service.port, if ksm.service.nodePort > 0 {nodePort: ksm.service.nodePort}}, if ksm.selfMonitor.enabled {name: "metrics", protocol: "TCP", port: ksm.selfMonitor.telemetryPort, targetPort: ksm.selfMonitor.telemetryPort, if ksm.selfMonitor.telemetryNodePort > 0 {nodePort: ksm.selfMonitor.telemetryNodePort}}]
			if ksm.service.loadBalancerIP != "" {loadBalancerIP: ksm.service.loadBalancerIP}
			if len(ksm.service.loadBalancerSourceRanges) > 0 {loadBalancerSourceRanges: ksm.service.loadBalancerSourceRanges}
			if ksm.autosharding.enabled {clusterIP: "None"}
			if !ksm.autosharding.enabled && ksm.service.clusterIP != "" {clusterIP: ksm.service.clusterIP}
			selector: selectorLabels
		}
	}

	if ksm.serviceAccount.create {
		"serviceaccount": corev1.#ServiceAccount & {
			apiVersion:                   "v1"
			kind:                         "ServiceAccount"
			automountServiceAccountToken: ksm.serviceAccount.automountServiceAccountToken
			metadata: {name: ksmServiceAccountName, namespace: ksmNamespace, labels: ksmLabels, if len(ksm.serviceAccount.annotations) > 0 {annotations: ksm.serviceAccount.annotations}}
			if len(ksm.serviceAccount.imagePullSecrets) > 0 {imagePullSecrets: ksm.serviceAccount.imagePullSecrets}
		}
	}

	// 16. templates/serviceaccount.yaml
	// Implemented above as the conditional "serviceaccount" object.

	// 17. templates/servicemonitor.yaml
	if ksm.prometheus.monitor.enabled {
		"servicemonitor": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "ServiceMonitor"
			metadata: {name: fullname, namespace: ksmNamespace, labels: ksmLabels & ksm.prometheus.monitor.additionalLabels, if len(ksm.prometheus.monitor.annotations) > 0 {annotations: ksm.prometheus.monitor.annotations}}
			spec: {
				jobLabel: [if ksm.prometheus.monitor.jobLabel != "" {ksm.prometheus.monitor.jobLabel}, "app.kubernetes.io/name"][0]
				if len(ksm.prometheus.monitor.targetLabels) > 0 {targetLabels: ksm.prometheus.monitor.targetLabels}
				if len(ksm.prometheus.monitor.podTargetLabels) > 0 {podTargetLabels: ksm.prometheus.monitor.podTargetLabels}
				if len(ksm.prometheus.monitor.namespaceSelector) > 0 {namespaceSelector: matchNames: ksm.prometheus.monitor.namespaceSelector}
				selector: matchLabels: [if len(ksm.prometheus.monitor.selectorOverride) > 0 {ksm.prometheus.monitor.selectorOverride}, selectorLabels][0]
				endpoints: [{port: "http", if ksm.prometheus.monitor.http.interval != "" {interval: ksm.prometheus.monitor.http.interval}, if ksm.prometheus.monitor.http.scrapeTimeout != "" {scrapeTimeout: ksm.prometheus.monitor.http.scrapeTimeout}, if ksm.prometheus.monitor.http.proxyUrl != "" {proxyUrl: ksm.prometheus.monitor.http.proxyUrl}, if ksm.prometheus.monitor.http.enableHttp2 {enableHttp2: ksm.prometheus.monitor.http.enableHttp2}, if ksm.prometheus.monitor.http.honorLabels {honorLabels: true}, if len(ksm.prometheus.monitor.http.metricRelabelings) > 0 {metricRelabelings: ksm.prometheus.monitor.http.metricRelabelings}, if len(ksm.prometheus.monitor.http.relabelings) > 0 {relabelings: ksm.prometheus.monitor.http.relabelings}, if ksm.prometheus.monitor.http.scheme != "" {scheme: ksm.prometheus.monitor.http.scheme}, if len(ksm.prometheus.monitor.http.tlsConfig) > 0 {tlsConfig: ksm.prometheus.monitor.http.tlsConfig}, if ksm.prometheus.monitor.http.bearerTokenFile != "" {bearerTokenFile: ksm.prometheus.monitor.http.bearerTokenFile}}, if ksm.selfMonitor.enabled {port: "metrics"}]
			}
		}
	}

	// 18. templates/stsdiscovery-role.yaml
	if ksm.autosharding.enabled && ksm.rbac.create {
		"stsdiscovery-role": rbacv1.#Role & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "Role"
			metadata: {name: "stsdiscovery-\(fullname)", namespace: ksmNamespace, labels: ksmLabels}
			rules: [{apiGroups: [""], resources: ["pods"], verbs: ["get"]}, {apiGroups: ["apps"], resourceNames: [fullname], resources: ["statefulsets"], verbs: ["get", "list", "watch"]}]
		}
	}

	// 19. templates/stsdiscovery-rolebinding.yaml
	if ksm.autosharding.enabled && ksm.rbac.create {
		"stsdiscovery-rolebinding": rbacv1.#RoleBinding & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "RoleBinding"
			metadata: {name: "stsdiscovery-\(fullname)", namespace: ksmNamespace, labels: ksmLabels}
			roleRef: {apiGroup: "rbac.authorization.k8s.io", kind: "Role", name: "stsdiscovery-\(fullname)"}
			subjects: [{kind: "ServiceAccount", name: ksmServiceAccountName, namespace: ksmNamespace}]
		}
	}

	// 20. templates/verticalpodautoscaler.yaml
	if ksm.verticalPodAutoscaler.enabled {
		"verticalpodautoscaler": {
			apiVersion: "autoscaling.k8s.io/v1"
			kind:       "VerticalPodAutoscaler"
			metadata: {name: fullname, namespace: ksmNamespace, labels: ksmLabels}
			spec: {
				if len(ksm.verticalPodAutoscaler.recommenders) > 0 {recommenders: ksm.verticalPodAutoscaler.recommenders}
				resourcePolicy: containerPolicies: [{containerName: (#KubeStateMetricsName & {#config: #config}).result, if len(ksm.verticalPodAutoscaler.controlledResources) > 0 {controlledResources: ksm.verticalPodAutoscaler.controlledResources}, if ksm.verticalPodAutoscaler.controlledValues != "" {controlledValues: ksm.verticalPodAutoscaler.controlledValues}, if len(ksm.verticalPodAutoscaler.maxAllowed) > 0 {maxAllowed: ksm.verticalPodAutoscaler.maxAllowed}, if len(ksm.verticalPodAutoscaler.minAllowed) > 0 {minAllowed: ksm.verticalPodAutoscaler.minAllowed}}]
				targetRef: {apiVersion: "apps/v1", kind: [if ksm.autosharding.enabled {"StatefulSet"}, "Deployment"][0], name: fullname}
				if len(ksm.verticalPodAutoscaler.updatePolicy) > 0 {updatePolicy: ksm.verticalPodAutoscaler.updatePolicy}
			}
		}
	}
}
