package templates

import (
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
	"list"
)

// #UpdateJob defines a template for database updates.
#UpdateJob: batchv1.#Job & {
	#config: #Config
	#cmName: string
	#pvcName: string
	#name:   string
	#script: string

	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		name:      #name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			tier: "update"
		}
	}
	spec: batchv1.#JobSpec & {
		backoffLimit: 1
		template: {
			metadata: labels: #config.metadata.labels
			spec: corev1.#PodSpec & {
				restartPolicy: "OnFailure"
				initContainers: [
					{
						name:  "init-drush-config"
						image: #config.drupal.initContainerImage
						command: [
							"/bin/sh",
							"-c",
							#"""
							\#( [ if #config.mysql.enabled { #"""
							cat <<EOF > /tmp/.my.cnf
							[client]
							ssl = false
							ssl-verify-server-cert = false
							EOF
							"""#
							}, "" ][0] )
							mkdir -p /var/www/html/drush
							cat <<EOF > /var/www/html/drush/drush.yml
							command:
							  sql:
							\#( [ if #config.mysql.enabled { #"""
							    cli:
							      options:
							        extra: "--skip-ssl"
							    connect:
								  options:
							        extra: "--skip-ssl"
							    create:
								  options:
							        extra: "--skip-ssl"
							    drop:
								  options:
							        extra: "--skip-ssl"
							    dump:
								  options:
							        extra: "--skip-ssl"
							    query:
								  options:
							        extra: "--skip-ssl"
							"""#
							}, "" ][0] )
							EOF
							"""#
							,
						]
						volumeMounts: [
							{
								name:      "tmp"
								mountPath: "/tmp"
							},
							{
								name:      "drush-config"
								mountPath: "/var/www/html/drush"
							},
						]
					},
				]
				containers: [
					{
						name:  "update"
						image: #config.drupal.image + ":" + [ if #config.drupal.tag != "" { #config.drupal.tag }, #config.moduleVersion ][0]
						command: ["/bin/sh", "-c", #script]
						env: list.Concat([#config.#env, [
							{
								name:  "HOME"
								value: "/tmp"
							},
						]])
						volumeMounts: [
							{
								mountPath: "/var/www/html/sites/default/files"
								name:      "public-storage"
							},
							{
								name:      "tmp"
								mountPath: "/tmp"
							},
							{
								name:      "drush-config"
								mountPath: "/var/www/html/drush"
							},
						]
					},
				]
				volumes: [
					{
						name: "public-storage"
						persistentVolumeClaim: claimName: #pvcName
					},
					{
						name: "tmp"
						emptyDir: {}
					},
					{
						name: "drush-config"
						emptyDir: {}
					},
				]
			}
		}
	}
}

// #CronJob defines a template for periodic tasks.
#CronJob: batchv1.#CronJob & {
	#config:  #Config
	#pvcName: string
	#name:    string
	#script:  string
	#schedule: string

	apiVersion: "batch/v1"
	kind:       "CronJob"
	metadata: {
		name:      #name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			tier: "cron"
		}
	}
	spec: batchv1.#CronJobSpec & {
		schedule: #schedule
		jobTemplate: spec: template: spec: corev1.#PodSpec & {
			restartPolicy: "OnFailure"
			initContainers: [
				{
					name:  "init-drush-config"
					image: #config.drupal.initContainerImage
					command: [
						"/bin/sh",
						"-c",
						#"""
						\#( [ if #config.mysql.enabled { #"""
						cat <<EOF > /tmp/.my.cnf
						[client]
						ssl = false
						ssl-verify-server-cert = false
						EOF
						"""#
						}, "" ][0] )
						mkdir -p /var/www/html/drush
						cat <<EOF > /var/www/html/drush/drush.yml
						command:
						  sql:
						\#( [ if #config.mysql.enabled { #"""
						    cli:
						      options:
						        extra: "--skip-ssl"
						    connect:
						      options:
						        extra: "--skip-ssl"
						    create:
						      options:
						        extra: "--skip-ssl"
						    drop:
						      options:
						        extra: "--skip-ssl"
						    dump:
						      options:
						        extra: "--skip-ssl"
						    query:
						      options:
						        extra: "--skip-ssl"
						"""#
						}, "" ][0] )
						EOF
						"""#
						,
					]
					volumeMounts: [
						{
							name:      "tmp"
							mountPath: "/tmp"
						},
						{
							name:      "drush-config"
							mountPath: "/var/www/html/drush"
						},
					]
				},
			]
			containers: [
				{
					name:  "cron"
					image: #config.drupal.image + ":" + [ if #config.drupal.tag != "" { #config.drupal.tag }, #config.moduleVersion ][0]
					command: ["/bin/sh", "-c", #script]
					env: list.Concat([#config.#env, [
						{
							name:  "HOME"
							value: "/tmp"
						},
					]])
					volumeMounts: [
						{
							mountPath: "/var/www/html/sites/default/files"
							name:      "public-storage"
						},
						{
							name:      "tmp"
							mountPath: "/tmp"
						},
						{
							name:      "drush-config"
							mountPath: "/var/www/html/drush"
						},
					]
				},
			]
			volumes: [
				{
					name: "public-storage"
					persistentVolumeClaim: claimName: #pvcName
				},
				{
					name: "tmp"
					emptyDir: {}
				},
				{
					name: "drush-config"
					emptyDir: {}
				},
			]
		}
	}
}
