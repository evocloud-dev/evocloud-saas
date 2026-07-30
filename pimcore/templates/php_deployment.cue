package templates

import (
	appsv1 "k8s.io/api/apps/v1"
)

#DeploymentPhp: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-php"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: {
		replicas: #config.php.replicas
		if #config.php.strategy != _|_ && #config.php.strategy != {} {
			strategy: #config.php.strategy
		}
		selector: matchLabels: {
			"app.kubernetes.io/name":     #config.metadata.name
			"app.kubernetes.io/instance": "\(#config.metadata.name)-php"
		}
		template: {
			metadata: {
				labels: {
					"app.kubernetes.io/name":     #config.metadata.name
					"app.kubernetes.io/instance": "\(#config.metadata.name)-php"
				}
				annotations: {
					"checksum/php-env-vars":                  "fake-checksum"
					"checksum/secret-env-vars":               "fake-checksum"
					"checksum/php-fpm-conf":                  "fake-checksum"
					"checksum/php-fpm-d-zzzz-www-pool-conf": "fake-checksum"
					"checksum/php-ini":                       "fake-checksum"
					"checksum/php-conf-d-30-pimcore-ini":     "fake-checksum"
					"checksum/pimcore-configmap":             "fake-checksum"
					"seccomp.security.alpha.kubernetes.io/pod": "runtime/default"
					"container.seccomp.security.alpha.kubernetes.io/pod": "runtime/default"
					for k, v in #config.podAnnotations {
						"\(k)": v
					}
					for k, v in #config.php.podAnnotations {
						"\(k)": v
					}
				}
			}
			spec: {
				automountServiceAccountToken: false
				if #config.podSecurityContext != _|_ && #config.podSecurityContext != {} {
					securityContext: #config.podSecurityContext
				}
				if #config.php.imagePullSecrets != _|_ && len(#config.php.imagePullSecrets) > 0 {
					imagePullSecrets: #config.php.imagePullSecrets
				}
				serviceAccountName: #saName
				initContainers: [
					{
						name:  "fix-var-permissions"
						image: "busybox:latest"
						securityContext: {
							runAsUser:    0
							runAsNonRoot: false
						}
						command: [
							"sh",
							"-c",
							"chown -R \(#config.php.phpUser.uid):\(#config.php.phpUser.gid) /var/www/\(#config.pvc.data.subPath)/var && chmod -R 775 /var/www/\(#config.pvc.data.subPath)/var",
						]
						volumeMounts: [
							{
								name:      "pimcore-data"
								mountPath: "/var/www"
							},
						]
					},
					{
						name:  "wait-for-pimcore-installed"
						image: "busybox:latest"
						securityContext: {
							runAsUser:    #config.php.phpUser.uid
							runAsGroup:   #config.php.phpUser.gid
							runAsNonRoot: true
						}
						command: [
							"sh",
							"-c",
							"until [ -f /var/www/var/installed ] || [ -f /var/www/\(#config.pvc.data.subPath)/var/installed ]; do echo wait-for-pimcore-installed; sleep 2; done;",
						]
						volumeMounts: [
							{
								name:      "pimcore-data"
								mountPath: "/var/www"
								subPath:   "pimcore"
							},
						]
					},
				]
				containers: [
					{
						name: "pimcore"
						if #config.securityContext != _|_ && #config.securityContext != {} {
							securityContext: #config.securityContext
						}
						image:           "\(#config.php.image.registry):\(#config.php.image.tag)"
						imagePullPolicy: #config.php.image.pullPolicy
						ports: [
							{
								containerPort: 9000
							},
						]
						resources: #config.php.resources
						if #config.php.startupProbe.enabled {
							startupProbe: {
								tcpSocket: {
									port: 9000
								}
								periodSeconds:    #config.php.startupProbe.periodSeconds
								timeoutSeconds:   #config.php.startupProbe.timeoutSeconds
								failureThreshold: #config.php.startupProbe.failureThreshold
							}
						}
						if #config.php.livenessProbe.enabled {
							livenessProbe: {
								tcpSocket: {
									port: 9000
								}
								periodSeconds:    #config.php.livenessProbe.periodSeconds
								timeoutSeconds:   #config.php.livenessProbe.timeoutSeconds
								failureThreshold: #config.php.livenessProbe.failureThreshold
							}
						}
						if #config.php.readinessProbe.enabled {
							readinessProbe: {
								tcpSocket:        #config.php.readinessProbe.tcpSocket
								initialDelaySeconds: #config.php.readinessProbe.initialDelaySeconds
								periodSeconds:    #config.php.readinessProbe.periodSeconds
								timeoutSeconds:   #config.php.readinessProbe.timeoutSeconds
								failureThreshold: #config.php.readinessProbe.failureThreshold
							}
						}
						if #config.securityContext != _|_ && #config.securityContext != {} {
							securityContext: #config.securityContext
						}
						envFrom: [
							{
								configMapRef: name: "\(#config.metadata.name)-php-env"
							},
							{
								secretRef: name: "\(#config.metadata.name)-dotenv"
							},
						]
						volumeMounts: [
							{
								name:      "php-ini"
								mountPath: "/usr/local/etc/php/php.ini"
								subPath:   "php.ini"
							},
							{
								name:      "php-conf-d-30-pimcore-ini"
								mountPath: "/usr/local/etc/php/conf.d/30-pimcore.ini"
								subPath:   "30-pimcore.ini"
							},
							{
								name:      "php-fpm-conf"
								mountPath: "/usr/local/etc/php-fpm.conf"
								subPath:   "php-fpm.conf"
							},
							{
								name:      "php-fpm-d-zzzz-www-pool-conf"
								mountPath: "/usr/local/etc/php-fpm.d/zzzz-www-pool.conf"
								subPath:   "zzzz-www-pool.conf"
							},
							{
								name:      "pimcore-data"
								mountPath: "/var/www/pimcore"
								subPath:   #config.pvc.data.subPath
							},
							for k, v in #config.pvc.data.sharedSubPaths {
								{
									name:      "pimcore-data"
									mountPath: v.mountPath
									subPath:   v.subPath
								}
							},
							for k, v in #config.pimcore.customConfigFiles if v.enabled {
								{
									name:      k
									mountPath: "/var/www/pimcore/\(v.containerPath)"
									subPath:   k
								}
							},
							for k, v in #config.pimcore.mountedConfigDirs if v.enabled {
								{
									name:      k
									mountPath: "/var/www/pimcore/\(v.containerPath)"
									readOnly:  true
								}
							},
						]
					},
				]
				volumes: [
					{
						name: "pimcore-data"
						persistentVolumeClaim: claimName: #dataClaimName
					},
					{
						name: "php-ini"
						configMap: name: "\(#config.metadata.name)-php-ini"
					},
					{
						name: "php-conf-d-30-pimcore-ini"
						configMap: name: "\(#config.metadata.name)-php-conf-d-30-pimcore-ini"
					},
					{
						name: "php-fpm-conf"
						configMap: name: "\(#config.metadata.name)-php-fpm-conf"
					},
					{
						name: "php-fpm-d-zzzz-www-pool-conf"
						configMap: name: "\(#config.metadata.name)-php-fpm-d-zzzz-www-pool-conf"
					},
					for k, v in #config.pimcore.customConfigFiles if v.enabled {
						{
							name: k
							configMap: name: "\(#config.metadata.name)-\(k)"
						}
					},
					for k, v in #config.pimcore.mountedConfigDirs if v.enabled {
						{
							name: k
							configMap: name: "\(#config.metadata.name)-\(k)"
						}
					},
				]
				if #config.nodeSelector != _|_ && #config.nodeSelector != {} {
					nodeSelector: #config.nodeSelector
				}
				if #config.php.topologySpreadConstraints != _|_ && len(#config.php.topologySpreadConstraints) > 0 {
					topologySpreadConstraints: #config.php.topologySpreadConstraints
				}
				if #config.affinity != _|_ && #config.affinity != {} {
					affinity: #config.affinity
				}
				if #config.tolerations.php != _|_ {
					tolerations: #config.tolerations.php
				}
			}
		}
	}

	#dataClaimName: {
		if #config.pvc.data.existingClaim != "" {
			#config.pvc.data.existingClaim
		}
		if #config.pvc.data.existingClaim == "" {
			"\(#config.metadata.name)-\(#config.pvc.data.name)"
		}
	}

	#saName: {
		if #config.serviceAccount.name != "" {
			#config.serviceAccount.name
		}
		if #config.serviceAccount.name == "" {
			#config.metadata.name
		}
	}
}
