package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
	networkingv1 "k8s.io/api/networking/v1"
)

#RealmConfigMap: corev1.#ConfigMap & {
	#config: #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "realm"
		namespace: #config.metadata.namespace
	}
	data: {
		"docs.json": #config.keycloak.realmJson
	}
}

#KeycloakService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "keycloak"
		namespace: #config.metadata.namespace
	}
	spec: corev1.#ServiceSpec & {
		ports: [{
			name:       "tcp-keycloak"
			port:       8080
			targetPort: 8080
			protocol:   "TCP"
		}]
		selector: {
			"app.kubernetes.io/instance": "extra"
			"app.kubernetes.io/name":     "keycloak"
		}
		type: "ClusterIP"
	}
}

#KeycloakIngress: networkingv1.#Ingress & {
	#config: #Config
	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata: {
		name:      "keycloak"
		namespace: #config.metadata.namespace
		// Merge className annotation with any user-supplied extra annotations.
		// Use a let with a default so spreading works even when annotations is unset.
		let _extraAnnotations = *#config.keycloak.ingress.annotations | {}
		annotations: {
			if #config.keycloak.ingress.className != null {
				"kubernetes.io/ingress.class": #config.keycloak.ingress.className
			}
			_extraAnnotations
		}
	}
	spec: networkingv1.#IngressSpec & {
		if #config.keycloak.ingress.className != null {
			ingressClassName: #config.keycloak.ingress.className
		}
		rules: [{
			host: #config.keycloak.host
			http: paths: [{
				path:     "/"
				pathType: "Prefix"
				backend: service: {
					name: "keycloak"
					port: number: 8080
				}
			}]
		}]
		tls: [{
			hosts: [#config.keycloak.host]
			secretName: #config.keycloak.ingress.secretName
		}]
	}
}

#KeycloakStatefulSet: appsv1.#StatefulSet & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "keycloak"
		namespace: #config.metadata.namespace
	}
	spec: appsv1.#StatefulSetSpec & {
		selector: matchLabels: {
			"app.kubernetes.io/instance": "extra"
			"app.kubernetes.io/name":     "keycloak"
		}
		serviceName: "keycloak"
		replicas:    1
		template: {
			metadata: labels: {
				"app.kubernetes.io/instance": "extra"
				"app.kubernetes.io/name":     "keycloak"
			}
			spec: corev1.#PodSpec & {
				terminationGracePeriodSeconds: 10
				automountServiceAccountToken: #config.keycloak.automountServiceAccountToken
				serviceAccountName:           #config.keycloak.serviceAccountName
				if #config.keycloak.podSecurityContext != null {
					securityContext: #config.keycloak.podSecurityContext
				}
				initContainers: [{
					name:  "copy-lib-quarkus"
					image: #config.keycloak.image.reference
					command: [
						"/bin/sh",
						"-c",
						"rm -rf /opt/keycloak/lib/quarkus-writable/* && cp -r /opt/keycloak/lib/quarkus/. /opt/keycloak/lib/quarkus-writable/",
					]
					volumeMounts: [{
						name:      "lib-quarkus-writable"
						mountPath: "/opt/keycloak/lib/quarkus-writable"
					}]
					if #config.keycloak.securityContext != null {
						securityContext: #config.keycloak.securityContext
					}
				}]
				containers: [{
					name:  "keycloak"
					image: #config.keycloak.image.reference
					if #config.keycloak.securityContext != null {
						securityContext: #config.keycloak.securityContext
					}
					if #config.keycloak.resources != null {
						resources: #config.keycloak.resources
					}
					args: [
						"start-dev",
						"--features=preview",
						"--import-realm",
						"--proxy-headers=xforwarded",
						"--http-enabled=true",
						"--hostname=\(#config.keycloak.host)",
						"--hostname-strict=false",
					]
					ports: [{
						containerPort: 8080
						name:          "tcp-keycloak"
					}]
					env: [{
						name:  "KEYCLOAK_ADMIN"
						value: #config.keycloak.adminUser
					}, {
						name:  "KEYCLOAK_ADMIN_PASSWORD"
						value: #config.keycloak.adminPassword
					}, {
						name:  "PROXY_ADDRESS_FORWARDING"
						value: "true"
					}, {
						name:  "KC_DB"
						value: "postgres"
					}, {
						name:  "KC_DB_URL_HOST"
						value: #config.keycloak.db.host
					}, {
						name:  "KC_DB_URL_DATABASE"
						value: #config.keycloak.db.database
					}, {
						name:  "KC_DB_PASSWORD"
						value: #config.keycloak.db.password
					}, {
						name:  "KC_DB_USERNAME"
						value: #config.keycloak.db.username
					}, {
						name:  "KC_DB_SCHEMA"
						value: #config.keycloak.db.schema
					}]
					volumeMounts: [{
						name:      "realm"
						mountPath: "/opt/keycloak/data/import"
						readOnly:  true
					}, {
						name:      "lib-quarkus-writable"
						mountPath: "/opt/keycloak/lib/quarkus"
					}, {
						name:      "tmp-volume"
						mountPath: "/tmp"
					}]
				}]
				volumes: [{
					name: "realm"
					configMap: name: "realm"
				}, {
					name: "lib-quarkus-writable"
					emptyDir: {}
				}, {
					name: "tmp-volume"
					emptyDir: {}
				}]
			}
		}
	}
}
