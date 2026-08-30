package templates

import (
	admissionregistrationv1 "k8s.io/api/admissionregistration/v1"
)

monitoringPrometheusOperatorWebhooks: {
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

	let webhookAnnotations = {
		if op.admissionWebhooks.certManager.enabled {
			"certmanager.k8s.io/inject-ca-from": "\(opNamespace)/\(fullname)-admission"
			"cert-manager.io/inject-ca-from":    "\(opNamespace)/\(fullname)-admission"
		}
	}

	if op.enabled && op.admissionWebhooks.enabled {
		"mutating-webhook": admissionregistrationv1.#MutatingWebhookConfiguration & {
			apiVersion: "admissionregistration.k8s.io/v1"
			kind:       "MutatingWebhookConfiguration"
			metadata: {
				name:        "\(fullname)-admission"
				annotations: webhookAnnotations & op.admissionWebhooks.mutatingWebhookConfiguration.annotations
				labels: webhookLabels & {app: "\(chartName)-admission"}
			}
			webhooks: [{
				name: "prometheusrulemutate.monitoring.coreos.com"
				failurePolicy: [
					if op.admissionWebhooks.failurePolicy == "IgnoreOnInstallOnly" {"Fail"},
					if op.admissionWebhooks.failurePolicy != "" && op.admissionWebhooks.failurePolicy != "IgnoreOnInstallOnly" {op.admissionWebhooks.failurePolicy},
					if op.admissionWebhooks.patch.enabled {"Ignore"},
					"Fail",
				][0]
				rules: [{
					apiGroups: ["monitoring.coreos.com"]
					apiVersions: ["*"]
					resources: ["prometheusrules"]
					operations: ["CREATE", "UPDATE"]
				}]
				clientConfig: {
					service: {
						namespace: opNamespace
						name: [if op.admissionWebhooks.deployment.enabled {"\(opFullname)-webhook"}, opFullname][0]
						path: "/admission-prometheusrules/mutate"
					}
					if op.admissionWebhooks.caBundle != "" && !op.admissionWebhooks.patch.enabled && !op.admissionWebhooks.certManager.enabled {
						caBundle: op.admissionWebhooks.caBundle
					}
				}
				timeoutSeconds: op.admissionWebhooks.timeoutSeconds
				admissionReviewVersions: ["v1", "v1beta1"]
				sideEffects: "None"
				if len(op.denyNamespaces) > 0 || len(op.namespaces.additional) > 0 || op.admissionWebhooks.namespaceSelector != _|_ {
					namespaceSelector: {
						if op.admissionWebhooks.namespaceSelector != _|_ {
							op.admissionWebhooks.namespaceSelector
						}
						if len(op.denyNamespaces) > 0 {
							matchExpressions: [{
								key:      "kubernetes.io/metadata.name"
								operator: "NotIn"
								values:   op.denyNamespaces
							}]
						}
						if len(op.namespaces.additional) > 0 {
							matchExpressions: [{
								key:      "kubernetes.io/metadata.name"
								operator: "In"
								values: [
									if op.namespaces.releaseNamespace {opNamespace},
								] + op.namespaces.additional
							}]
						}
					}
				}
				if op.admissionWebhooks.objectSelector != _|_ {
					objectSelector: op.admissionWebhooks.objectSelector
				}
			}]
		}

		"validating-webhook": admissionregistrationv1.#ValidatingWebhookConfiguration & {
			apiVersion: "admissionregistration.k8s.io/v1"
			kind:       "ValidatingWebhookConfiguration"
			metadata: {
				name:        "\(fullname)-admission"
				annotations: webhookAnnotations & op.admissionWebhooks.validatingWebhookConfiguration.annotations
				labels: webhookLabels & {app: "\(chartName)-admission"}
			}
			webhooks: [{
				name: "prometheusrulemutate.monitoring.coreos.com"
				failurePolicy: [
					if op.admissionWebhooks.failurePolicy == "IgnoreOnInstallOnly" {"Fail"},
					if op.admissionWebhooks.failurePolicy != "" && op.admissionWebhooks.failurePolicy != "IgnoreOnInstallOnly" {op.admissionWebhooks.failurePolicy},
					if op.admissionWebhooks.patch.enabled {"Ignore"},
					"Fail",
				][0]
				rules: [{
					apiGroups: ["monitoring.coreos.com"]
					apiVersions: ["*"]
					resources: ["prometheusrules"]
					operations: ["CREATE", "UPDATE"]
				}]
				clientConfig: {
					service: {
						namespace: opNamespace
						name: [if op.admissionWebhooks.deployment.enabled {"\(opFullname)-webhook"}, opFullname][0]
						path: "/admission-prometheusrules/validate"
					}
					if op.admissionWebhooks.caBundle != "" && !op.admissionWebhooks.patch.enabled && !op.admissionWebhooks.certManager.enabled {
						caBundle: op.admissionWebhooks.caBundle
					}
				}
				timeoutSeconds: op.admissionWebhooks.timeoutSeconds
				admissionReviewVersions: ["v1", "v1beta1"]
				sideEffects: "None"
				if len(op.denyNamespaces) > 0 || len(op.namespaces.additional) > 0 || op.admissionWebhooks.namespaceSelector != _|_ {
					namespaceSelector: {
						if op.admissionWebhooks.namespaceSelector != _|_ {
							op.admissionWebhooks.namespaceSelector
						}
						if len(op.denyNamespaces) > 0 {
							matchExpressions: [{
								key:      "kubernetes.io/metadata.name"
								operator: "NotIn"
								values:   op.denyNamespaces
							}]
						}
						if len(op.namespaces.additional) > 0 {
							matchExpressions: [{
								key:      "kubernetes.io/metadata.name"
								operator: "In"
								values: [
									if op.namespaces.releaseNamespace {opNamespace},
								] + op.namespaces.additional
							}]
						}
					}
				}
				if op.admissionWebhooks.objectSelector != _|_ {
					objectSelector: op.admissionWebhooks.objectSelector
				}
			}]
		}
	}
}
