package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

#CaddyDeployment: appsv1.#Deployment & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-caddy"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: 1
		selector: metav1.#LabelSelector & {
			matchLabels: {
				"app.kubernetes.io/name":     "opensign-caddy"
				"app.kubernetes.io/instance": #config.metadata.name
			}
		}
		template: corev1.#PodTemplateSpec & {
			metadata: {
				labels: {
					"app.kubernetes.io/name":     "opensign-caddy"
					"app.kubernetes.io/instance": #config.metadata.name
				}
			}
			spec: corev1.#PodSpec & {
				if #config.podSecurityContext != _|_ {
					securityContext: #config.podSecurityContext
				}
				containers: [{
					name:            "caddy"
					image:           #config.caddy.image.reference
					imagePullPolicy: #config.caddy.image.pullPolicy
					ports: [
						{name: "http", containerPort: 80, protocol: "TCP"},
						{name: "https", containerPort: 443, protocol: "TCP"},
						{name: "https-udp", containerPort: 443, protocol: "UDP"},
						{name: "alt", containerPort: 3001, protocol: "TCP"},
					]
					env: [{
						name:  "HOST_URL"
						value: #config.caddy.hostUrl
					}]
					resources: #config.caddy.resources
					volumeMounts: [
						{name: "caddyfile", mountPath: "/etc/caddy/Caddyfile", subPath: "Caddyfile"},
						{name: "data", mountPath: "/data"},
						{name: "config", mountPath: "/config"},
					]
				}]
				volumes: [
					{name: "caddyfile", configMap: name: "caddyfile"},
					{name: "data", persistentVolumeClaim: claimName: "caddy-data"},
					{name: "config", persistentVolumeClaim: claimName: "caddy-config"},
				]
			}
		}
	}
}
