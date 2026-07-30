package templates

import (
	"strings"

	appsv1 "k8s.io/api/apps/v1"
)



#DeploymentWorker: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-maintenance-worker"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: {
		replicas: #config.maintenance.worker.replicas
		selector: matchLabels: {
			"app.kubernetes.io/name":     #config.metadata.name
			"app.kubernetes.io/instance": "\(#config.metadata.name)-maintenance-worker"
		}
		template: {
			metadata: {
				labels: {
					"app.kubernetes.io/name":     #config.metadata.name
					"app.kubernetes.io/instance": "\(#config.metadata.name)-maintenance-worker"
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
				if #config.podSecurityContext != _|_ && #config.podSecurityContext != {} {
					securityContext: #config.podSecurityContext
				}
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
							"until [ -f /var/www/\(#config.pvc.data.subPath)/var/installed ]; do echo wait-for-pimcore-installed; sleep 5; done;",
						]
						volumeMounts: [
							{
								name:      "pimcore-data"
								mountPath: "/var/www"
							},
						]
					},
					if #config.maintenance.worker.livenessProbe.enabled {
						{
							name:            "verify-probe-deps"
							image:           "\(#config.php.image.registry):\(#config.php.image.tag)"
							imagePullPolicy: #config.php.image.pullPolicy
							command: [
								"sh",
								"-c",
								"""
								missing=
								for bin in pgrep; do
								  command -v \"$bin\" >/dev/null 2>&1 || missing=\"$missing $bin\"
								done
								if [ -n \"$missing\" ]; then
								  echo \"ERROR: probe binaries missing from image:$missing\" >&2
								  echo \"Install the corresponding package(s) (procps for pgrep, libfcgi-bin for cgi-fcgi)\" >&2
								  echo \"or override the affected probe in values.yaml.\" >&2
								  exit 1
								fi
								""",
							]
						}
					},
				]
				containers: [
					{
						name:            "maintenance-worker"
						image:           "\(#config.php.image.registry):\(#config.php.image.tag)"
						imagePullPolicy: #config.php.image.pullPolicy
						command: ["/bin/sh", "-c"]
						args: [
							"""
							cd /var/www/pimcore
							trap 'kill -TERM "$child" 2>/dev/null; wait "$child" 2>/dev/null; exit 0' TERM INT
							while true; do
							  php bin/console messenger:consume pimcore_core pimcore_maintenance pimcore_generic_data_index_queue pimcore_scheduled_tasks pimcore_image_optimize pimcore_asset_update\(#extraTransportsStr)\(#memLimitStr) --time-limit=3600 &
							  child=$!
							  wait "$child"
							  child=""
							  sleep 5
							done
							""",
						]
						lifecycle: preStop: exec: command: [
							"sh",
							"-c",
							"kill -TERM 1; while kill -0 1 2>/dev/null; do sleep 1; done",
						]
						resources: #config.maintenance.worker.resources
						if #config.maintenance.worker.livenessProbe.enabled {
							livenessProbe: {
								exec:                #config.maintenance.worker.livenessProbe.exec
								initialDelaySeconds: #config.maintenance.worker.livenessProbe.initialDelaySeconds
								periodSeconds:       #config.maintenance.worker.livenessProbe.periodSeconds
								timeoutSeconds:      #config.maintenance.worker.livenessProbe.timeoutSeconds
								failureThreshold:    #config.maintenance.worker.livenessProbe.failureThreshold
							}
						}
						envFrom: [
							{
								configMapRef: name: "\(#config.metadata.name)-maintenance-worker-env"
							},
							{
								secretRef: name: "\(#config.metadata.name)-dotenv"
							},
						]
						if #config.securityContext != _|_ && #config.securityContext != {} {
							securityContext: #config.securityContext
						}
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
								mountPath: "/usr/local/etc/php-fpm.d/zzzz-www.conf"
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
				if #config.affinity != _|_ && #config.affinity != {} {
					affinity: #config.affinity
				}
				if #config.tolerations.maintenance != _|_ {
					tolerations: #config.tolerations.maintenance
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

	#memLimitStr: {
		if #config.maintenance.worker.messengerMemoryLimit != "" {
			" --memory-limit=\(#config.maintenance.worker.messengerMemoryLimit)"
		}
		if #config.maintenance.worker.messengerMemoryLimit == "" {
			""
		}
	}

	#extraTransportsStr: {
		if len(#config.maintenance.worker.extraTransports) > 0 {
			strings.Join([for t in #config.maintenance.worker.extraTransports {" \(t)"}], "")
		}
		if len(#config.maintenance.worker.extraTransports) == 0 {
			""
		}
	}
}


