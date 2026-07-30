package templates

import (
	appsv1 "k8s.io/api/apps/v1"
)

#DeploymentNginx: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-nginx"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: {
		replicas: #config.nginx.replicas
		if #config.nginx.strategy != _|_ && #config.nginx.strategy != {} {
			strategy: #config.nginx.strategy
		}
		selector: matchLabels: {
			"app.kubernetes.io/name":     #config.metadata.name
			"app.kubernetes.io/instance": "\(#config.metadata.name)-nginx"
		}
		template: {
			metadata: {
				labels: {
					"app.kubernetes.io/name":     #config.metadata.name
					"app.kubernetes.io/instance": "\(#config.metadata.name)-nginx"
				}
				annotations: {
					"checksum/serverblock": "fake-checksum"
					"checksum/nginx":       "fake-checksum"
					"seccomp.security.alpha.kubernetes.io/pod": "runtime/default"
					"container.seccomp.security.alpha.kubernetes.io/pod": "runtime/default"
					for k, v in #config.podAnnotations {
						"\(k)": v
					}
					for k, v in #config.nginx.podAnnotations {
						"\(k)": v
					}
				}
			}
			spec: {
				automountServiceAccountToken: false
				securityContext: {
					seccompProfile: type: "RuntimeDefault"
				}
				if #config.nginx.imagePullSecrets != _|_ && len(#config.nginx.imagePullSecrets) > 0 {
					imagePullSecrets: #config.nginx.imagePullSecrets
				}
				serviceAccountName: #saName
				initContainers: [
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
							},
						]
					},
				]
				containers: [
					{
						name:            "nginx"
						image:           "\(#config.nginx.image.registry):\(#config.nginx.image.tag)"
						imagePullPolicy: #config.nginx.image.pullPolicy
						securityContext: {
							allowPrivilegeEscalation: false
						}
						ports: [
							{
								containerPort: 80
							},
						]
						resources: #config.nginx.resources
						if #config.nginx.startupProbe.enabled {
							startupProbe: {
								httpGet:          #config.nginx.startupProbe.httpGet
								periodSeconds:    #config.nginx.startupProbe.periodSeconds
								timeoutSeconds:   #config.nginx.startupProbe.timeoutSeconds
								failureThreshold: #config.nginx.startupProbe.failureThreshold
							}
						}
						if #config.nginx.livenessProbe.enabled {
							livenessProbe: {
								httpGet:          #config.nginx.livenessProbe.httpGet
								periodSeconds:    #config.nginx.livenessProbe.periodSeconds
								timeoutSeconds:   #config.nginx.livenessProbe.timeoutSeconds
								failureThreshold: #config.nginx.livenessProbe.failureThreshold
							}
						}
						if #config.nginx.readinessProbe.enabled {
							readinessProbe: {
								httpGet:          #config.nginx.readinessProbe.httpGet
								initialDelaySeconds: #config.nginx.readinessProbe.initialDelaySeconds
								periodSeconds:    #config.nginx.readinessProbe.periodSeconds
								timeoutSeconds:   #config.nginx.readinessProbe.timeoutSeconds
								failureThreshold: #config.nginx.readinessProbe.failureThreshold
							}
						}
						volumeMounts: [
							{
								name:      "server-block"
								mountPath: "/etc/nginx/conf.d"
							},
							{
								name:      "nginx-cache-dir"
								mountPath: "/var/cache/nginx"
							},
							{
								name:      "nginx-run-dir"
								mountPath: "/var/run"
							},
							{
								name:      "nginx-tmp-dir"
								mountPath: "/tmp"
							},
							for folder in #config.nginx.sharedFolders {
								{
									name:      "pimcore-data"
									mountPath: "/var/www/pimcore/\(folder)"
									subPath:   "\(#config.pvc.data.subPath)/\(folder)"
								}
							},
							for k, v in #config.pvc.data.sharedSubPaths {
								{
									name:      "pimcore-data"
									mountPath: v.mountPath
									subPath:   v.subPath
								}
							},
						]
					},
				]
				volumes: [
					{
						name: "server-block"
						configMap: name: "\(#config.metadata.name)-nginx-server-block"
					},
					{
						name: "pimcore-data"
						persistentVolumeClaim: claimName: #dataClaimName
					},
					{
						name: "nginx-cache-dir"
						emptyDir: {}
					},
					{
						name: "nginx-run-dir"
						emptyDir: {}
					},
					{
						name: "nginx-tmp-dir"
						emptyDir: {}
					},
				]
				if #config.nodeSelector != _|_ && #config.nodeSelector != {} {
					nodeSelector: #config.nodeSelector
				}
				if #config.nginx.topologySpreadConstraints != _|_ && len(#config.nginx.topologySpreadConstraints) > 0 {
					topologySpreadConstraints: #config.nginx.topologySpreadConstraints
				}
				if #config.affinity != _|_ && #config.affinity != {} {
					affinity: #config.affinity
				}
				if #config.tolerations.nginx != _|_ {
					tolerations: #config.tolerations.nginx
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
