package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#AdmissionSecret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-admission"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	type: corev1.#SecretTypeOpaque
	stringData: {
		key: #config.admission.key
	}
}

#AdmissionService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-admission"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type:           corev1.#ServiceTypeClusterIP
		ipFamilyPolicy: corev1.#IPFamilyPolicyPreferDualStack
		ports: [
			{
				name:       "admission"
				port:       8088
				targetPort: 8088
				protocol:   corev1.#ProtocolTCP
			},
		]
		selector: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-admission"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
}

#AdmissionDeployment: appsv1.#Deployment & {
	#config: #Config
	#saName: string

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-admission"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: 1
		selector: matchLabels: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-admission"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		template: {
			metadata: {
				labels: {
					"app.kubernetes.io/name":      "\(#config.metadata.name)-admission"
					"app.kubernetes.io/instance":  #config.metadata.name
					"app.kubernetes.io/component": "enrollment-admission"
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           #saName
				automountServiceAccountToken: false
				securityContext:              #config.podSecurityContext
				if len(#config.imagePullSecrets) > 0 {
					imagePullSecrets: #config.imagePullSecrets
				}
				if len(#config.nodeSelector) > 0 {
					nodeSelector: #config.nodeSelector
				}
				if len(#config.tolerations) > 0 {
					tolerations: #config.tolerations
				}
				containers: [
					{
						name:            "admission"
						image:           #config.admission.image.reference
						imagePullPolicy: #config.admission.image.pullPolicy
						command: ["node", "/helmforge/helper.mjs"]
						securityContext: #config.securityContext
						resources:       #config.admission.resources
						ports: [
							{
								name:          "admission"
								containerPort: 8088
							},
						]
						readinessProbe: {
							httpGet: {
								path: "/health"
								port: "admission"
							}
						}
						livenessProbe: {
							httpGet: {
								path: "/health"
								port: "admission"
							}
						}
						volumeMounts: [
							{
								name:      "runtime"
								mountPath: "/helmforge"
								readOnly:  true
							},
							{
								name:      "admission-key"
								mountPath: "/admission-key"
								readOnly:  true
							},
						]
					},
				]
				volumes: [
					{
						name: "runtime"
						configMap: {
							name: "\(#config.metadata.name)-runtime"
							items: [
								{key: "admission.mjs", path: "admission.mjs"},
								{key: "helper.mjs", path: "helper.mjs"},
							]
						}
					},
					{
						name: "admission-key"
						secret: {
							secretName: [
								if #config.admission.existingSecret != "" {#config.admission.existingSecret},
								"\(#config.metadata.name)-admission",
							][0]
							defaultMode: 0o440
						}
					},
				]
			}
		}
	}
}
