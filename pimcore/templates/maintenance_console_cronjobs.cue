package templates

import (
	batchv1 "k8s.io/api/batch/v1"
)

#CronJobConsole: batchv1.#CronJob & {
	#config:  #Config
	#name:    string
	#cronVal: _

	apiVersion: "batch/v1"
	kind:       "CronJob"
	metadata: {
		name:      "\(#config.metadata.name)-\(#name)"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: {
		schedule: #cronVal.schedule
		if #cronVal.suspend != _|_ {
			suspend: #cronVal.suspend
		}
		concurrencyPolicy: #cronVal.concurrencyPolicy
		if #cronVal.startingDeadlineSeconds != _|_ {
			startingDeadlineSeconds: #cronVal.startingDeadlineSeconds
		}
		successfulJobsHistoryLimit: #cronVal.successfulJobsHistoryLimit
		failedJobsHistoryLimit:     #cronVal.failedJobsHistoryLimit
		jobTemplate: spec: {
			ttlSecondsAfterFinished: #cronVal.ttlSecondsAfterFinished
			if #cronVal.activeDeadlineSeconds != _|_ {
				activeDeadlineSeconds: #cronVal.activeDeadlineSeconds
			}
			template: {
				metadata: {
					labels: {
						"app.kubernetes.io/name":     #config.metadata.name
						"app.kubernetes.io/instance": "\(#config.metadata.name)-\(#name)"
					}
					annotations: {
						"checksum/php-env-vars":                  "fake-checksum"
						"checksum/secret-env-vars":               "fake-checksum"
						"checksum/php-fpm-conf":                  "fake-checksum"
						"checksum/php-fpm-d-zzzz-www-pool-conf": "fake-checksum"
						"checksum/php-ini":                       "fake-checksum"
						"checksum/php-conf-d-30-pimcore-ini":     "fake-checksum"
					}
				}
				spec: {
					if #config.php.imagePullSecrets != _|_ && len(#config.php.imagePullSecrets) > 0 {
						imagePullSecrets: #config.php.imagePullSecrets
					}
					restartPolicy: #cronVal.restartPolicy
					initContainers: [
						{
							name:  "wait-for-pimcore-installed"
							image: "busybox:latest"
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
					]
					containers: [
						{
							name:            #name
							image:           "\(#config.php.image.registry):\(#config.php.image.tag)"
							imagePullPolicy: #config.php.image.pullPolicy
							command: ["/bin/sh", "-c"]
							args: [
								"""
								cd /var/www/pimcore
								./bin/console \(#cronVal.command)
								""",
							]
							if #cronVal.resources != _|_ {
								resources: #cronVal.resources
							}
							if #cronVal.resources == _|_ {
								resources: #config.maintenance.cronjob.resources
							}
							envFrom: [
								{
									configMapRef: name: "\(#config.metadata.name)-maintenance-cronjob-env"
								},
								{
									secretRef: name: "\(#config.metadata.name)-dotenv"
								},
							]
							securityContext: {
								runAsUser:  #config.php.phpUser.uid
								runAsGroup: #config.php.phpUser.gid
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
	}

	#dataClaimName: {
		if #config.pvc.data.existingClaim != "" {
			#config.pvc.data.existingClaim
		}
		if #config.pvc.data.existingClaim == "" {
			"\(#config.metadata.name)-\(#config.pvc.data.name)"
		}
	}
}
