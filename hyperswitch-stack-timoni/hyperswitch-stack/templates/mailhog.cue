package templates

import (
	"list"
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
	netv1 "k8s.io/api/networking/v1"
)

#Mailhog: {
	#config: #Config
	let mh = #config."hyperswitch-app".mailhog

	_mailhogName: string
	if mh.fullnameOverride != "" {
		_mailhogName: mh.fullnameOverride
	}
	if mh.fullnameOverride == "" {
		_mailhogName: "\(#config.metadata.name)-mailhog"
	}

	let _labels = {
		for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
		"app.kubernetes.io/name":     "mailhog"
		"app.kubernetes.io/instance": #config.metadata.name
	}
	let _selectorLabels = {
		"app.kubernetes.io/name":     "mailhog"
		"app.kubernetes.io/instance": #config.metadata.name
	}

	// Auth Secret
	if mh.auth.enabled && mh.auth.existingSecret == "" {
		authSecret: corev1.#Secret & {
			apiVersion: "v1"
			kind:       "Secret"
			metadata: {
				name:      "\(_mailhogName)-auth"
				namespace: #config.metadata.namespace
				"labels":  _labels
			}
			type: "Opaque"
			data: {
				"\(mh.auth.fileName)": mh.auth.fileContents
			}
		}
	}

	// ServiceAccount
	if mh.serviceAccount.create {
		serviceAccount: corev1.#ServiceAccount & {
			apiVersion: "v1"
			kind:       "ServiceAccount"
			metadata: {
				name: string
				if mh.serviceAccount.name != "" {
					name: mh.serviceAccount.name
				}
				if mh.serviceAccount.name == "" {
					name: _mailhogName
				}
				namespace: #config.metadata.namespace
				"labels":  _labels
			}
			if len(mh.serviceAccount.imagePullSecrets) > 0 {
				imagePullSecrets: mh.serviceAccount.imagePullSecrets
			}
			automountServiceAccountToken: mh.automountServiceAccountToken
		}
	}

	// Service
	service: corev1.#Service & {
		apiVersion: "v1"
		kind:       "Service"
		metadata: {
			name:      _mailhogName
			namespace: #config.metadata.namespace
			"labels":  _labels
			if len(mh.service.annotations) > 0 {
				annotations: mh.service.annotations
			}
		}
		spec: {
			type: mh.service.type
			if mh.service.clusterIP != "" {
				clusterIP: mh.service.clusterIP
			}
			if len(mh.service.externalIPs) > 0 {
				externalIPs: mh.service.externalIPs
			}
			if mh.service.loadBalancerIP != "" {
				loadBalancerIP: mh.service.loadBalancerIP
			}
			if len(mh.service.loadBalancerSourceRanges) > 0 {
				loadBalancerSourceRanges: mh.service.loadBalancerSourceRanges
			}
			ports: [
				{
					name:       "http"
					port:       mh.service.port.http
					targetPort: "http"
					protocol:   "TCP"
					if mh.service.nodePort.http != "" {
						nodePort: mh.service.nodePort.http
					}
				},
				{
					name:       "tcp-smtp"
					port:       mh.service.port.smtp
					targetPort: "tcp-smtp"
					protocol:   "TCP"
					if mh.service.nodePort.smtp != "" {
						nodePort: mh.service.nodePort.smtp
					}
				},
			]
			selector: _selectorLabels
		}
	}

	// Deployment
	deployment: appsv1.#Deployment & {
		apiVersion: "apps/v1"
		kind:       "Deployment"
		metadata: {
			name:      _mailhogName
			namespace: #config.metadata.namespace
			"labels":  _labels
		}
		spec: {
			replicas: 1
			selector: matchLabels: _selectorLabels
			template: {
				metadata: {
					if len(mh.podAnnotations) > 0 {
						annotations: mh.podAnnotations
					}
					labels: _labels & mh.podLabels
				}
				spec: {
					serviceAccountName: string
					if mh.serviceAccount.name != "" {
						serviceAccountName: mh.serviceAccount.name
					}
					if mh.serviceAccount.name == "" {
						if mh.serviceAccount.create {
							serviceAccountName: _mailhogName
						}
						if !mh.serviceAccount.create {
							serviceAccountName: "default"
						}
					}

					automountServiceAccountToken: mh.automountServiceAccountToken
					securityContext:              mh.securityContext
					if len(mh.imagePullSecrets) > 0 {
						imagePullSecrets: mh.imagePullSecrets
					}
					containers: [
						{
							name: "mailhog"
							_tag: string
							if mh.image.tag != "" {_tag: mh.image.tag}
							if mh.image.tag == "" {_tag: #config.moduleVersion}
							image:           "\(mh.image.repository):\(_tag)"
							imagePullPolicy: mh.image.pullPolicy
							env: list.Concat([
								[
									{
										name: "MH_HOSTNAME"
										valueFrom: fieldRef: fieldPath: "metadata.name"
									},
									if mh.auth.enabled {
										{
											name:  "MH_AUTH_FILE"
											value: "/authdir/\(mh.auth.fileName)"
										}
									},
								],
								mh.extraEnv,
							])
							ports: [
								{
									name:          "http"
									containerPort: 8025
									protocol:      "TCP"
								},
								{
									name:          "tcp-smtp"
									containerPort: 1025
									protocol:      "TCP"
								},
							]
							livenessProbe: {
								tcpSocket: port: "tcp-smtp"
								initialDelaySeconds: 10
								timeoutSeconds:      1
							}
							readinessProbe: tcpSocket: port: "tcp-smtp"
							if mh.auth.enabled {
								volumeMounts: [
									{
										name:      "authdir"
										mountPath: "/authdir"
										readOnly:  true
									},
								]
							}
							securityContext: mh.containerSecurityContext
							resources:       mh.resources
						},
					]
					if len(mh.affinity) > 0 {
						affinity: mh.affinity
					}
					if len(mh.nodeSelector) > 0 {
						nodeSelector: mh.nodeSelector
					}
					if len(mh.tolerations) > 0 {
						tolerations: mh.tolerations
					}
					if mh.auth.enabled {
						volumes: [
							{
								name: "authdir"
								secret: secretName: string
								if mh.auth.existingSecret != "" {
									secret: secretName: mh.auth.existingSecret
								}
								if mh.auth.existingSecret == "" {
									secret: secretName: "\(_mailhogName)-auth"
								}
							},
						]
					}
				}
			}
		}
	}

	// Ingress
	if mh.ingress.enabled {
		ingress: netv1.#Ingress & {
			apiVersion: "networking.k8s.io/v1"
			kind:       "Ingress"
			metadata: {
				name:      _mailhogName
				namespace: #config.metadata.namespace
				labels:    _labels & mh.ingress.labels
				if len(mh.ingress.annotations) > 0 {
					annotations: mh.ingress.annotations
				}
			}
			spec: {
				rules: [
					for h in mh.ingress.hosts {
						host: h.host
						http: paths: [
							for p in h.paths {
								path:     p
								pathType: "Prefix"
								backend: service: {
									name: _mailhogName
									port: name: "http"
								}
							},
						]
					},
				]
				if len(mh.ingress.tls) > 0 {
					tls: mh.ingress.tls
				}
			}
		}
	}
}
