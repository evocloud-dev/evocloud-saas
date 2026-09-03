package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#ConfigMapSupervisord: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-supervisord-conf"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	data: {
		"pimcore.conf": """
			[program:messenger-consume]
			command=php /var/www/pimcore/bin/console messenger:consume pimcore_generic_data_index_queue scheduler_generic_data_index pimcore_core pimcore_maintenance pimcore_scheduled_tasks pimcore_image_optimize pimcore_asset_update pimcore_generic_execution_engine --memory-limit=250M --time-limit=3600
			numprocs=1
			startsecs=0
			autostart=true
			autorestart=true
			process_name=%(program_name)s_%(process_num)02d
			stdout_logfile=/dev/fd/1
			stdout_logfile_maxbytes=0
			redirect_stderr=true

			[program:consume-asset-update]
			command=php /var/www/pimcore/bin/console messenger:consume pimcore_asset_update --memory-limit=250M --time-limit=3600
			numprocs=1
			startsecs=0
			autostart=true
			autorestart=true
			process_name=%(program_name)s_%(process_num)02d
			stdout_logfile=/dev/fd/1
			stdout_logfile_maxbytes=0
			redirect_stderr=true

			[program:maintenance]
			command=bash -c 'sleep 3600 && exec php /var/www/pimcore/bin/console pimcore:maintenance'
			autostart=true
			autorestart=true
			stdout_logfile=/dev/fd/1
			stdout_logfile_maxbytes=0
			redirect_stderr=true
			"""
	}
}

#SupervisordDeployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-supervisord"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: {
		replicas: #config.supervisord.replicas
		selector: matchLabels: {
			"app.kubernetes.io/name":      #config.metadata.name
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "supervisord"
		}
		template: {
			metadata: {
				labels: {
					"app.kubernetes.io/name":      #config.metadata.name
					"app.kubernetes.io/instance":  #config.metadata.name
					"app.kubernetes.io/component": "supervisord"
				}
				annotations: {
					"seccomp.security.alpha.kubernetes.io/pod": "runtime/default"
					"container.seccomp.security.alpha.kubernetes.io/pod": "runtime/default"
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
							"until [ -f /var/www/\(#config.pvc.data.subPath)/var/installed ]; do echo wait-for-pimcore-initialized; sleep 5; done;",
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
						name:            "supervisord"
						image:           "\(#config.supervisord.image.registry):\(#config.supervisord.image.tag)"
						imagePullPolicy: #config.supervisord.image.pullPolicy
						command: ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
						workingDir: "/var/www/pimcore"
						envFrom: [
							{
								configMapRef: name: "\(#config.metadata.name)-php-env"
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
								name:      "supervisord-conf"
								mountPath: "/etc/supervisor/conf.d/pimcore.conf"
								subPath:   "pimcore.conf"
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
						]
						if #config.supervisord.resources != _|_ {
							resources: #config.supervisord.resources
						}
					},
				]
				volumes: [
					{
						name: "supervisord-conf"
						configMap: name: "\(#config.metadata.name)-supervisord-conf"
					},
					{
						name: "pimcore-data"
						persistentVolumeClaim: claimName: #dataClaimName
					},
				]
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
