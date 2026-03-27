package templates

import (
	"strings"
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
)

#CreateMultipleSitesJob: batchv1.#Job & {
	#config: #Config

	_scripts: [
		for site in #config.jobs.createMultipleSites.sites {
			let force = [ if #config.jobs.createMultipleSites.forceCreate { " --force" }, ""][0]
			let apps = strings.Join([ for app in site.installApps { "--install-app=\(app)" }], " ")
			"""
			bench_output=$(bench new-site \(site.name) --no-mariadb-socket --db-type=${DB_TYPE} --db-host=${DB_HOST} --db-port=${DB_PORT} --admin-password=${ADMIN_PASSWORD} --mariadb-root-username=${DB_ROOT_USER} --mariadb-root-password=${DB_ROOT_PASSWORD}\(force) \(apps) | tee /dev/stderr);
			bench_exit_status=$?;
			if [ $bench_exit_status -ne 0 ]; then
				if [[ "$bench_output" == *"already exists"* ]]; then
					echo "Site \(site.name) already exists, continuing...";
				else
					echo "An error occurred while creating site \(site.name)";
					exit $bench_exit_status;
				fi
			fi;
			"""
		},
	]
	_full_script: "set -x; " + strings.Join(_scripts, "\n") + " set -e; rm -f currentsite.txt;"

	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		if #config.jobs.createMultipleSites.jobName != _|_ {
			name: #config.jobs.createMultipleSites.jobName
		}
		if #config.jobs.createMultipleSites.jobName == _|_ {
			name: "\(#config.metadata.name)-create-multi"
		}
		namespace: #config.metadata.namespace
		labels: {
			for k, v in #config.metadata.labels if k != "app.kubernetes.io/name" {
				"\(k)": v
			}
			"app.kubernetes.io/name": "\(#config.metadata.name)-create-multi"
		}
	}
	spec: batchv1.#JobSpec & {
		backoffLimit: #config.jobs.createMultipleSites.backoffLimit
		template: {
			metadata: {
				labels: {
					for k, v in #config.metadata.labels if k != "app.kubernetes.io/name" {
						"\(k)": v
					}
					"app.kubernetes.io/name": "\(#config.metadata.name)-create-multi"
				}
			}
			spec: corev1.#PodSpec & {
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
				serviceAccountName: #config.metadata.name
				if #config.podSecurityContext != _|_ {
					securityContext: #config.podSecurityContext
				}
				restartPolicy: "Never"
				initContainers: [
					{
						name:            "validate-config"
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						command: ["bash", "-c"]
						args: [
							"""
							export start=`date +%s`;
							until [[ -n `grep -hs ^ sites/common_site_config.json | jq -r \".db_host // empty\"` ]] && \\
							  [[ -n `grep -hs ^ sites/common_site_config.json | jq -r \".redis_cache // empty\"` ]] && \\
							  [[ -n `grep -hs ^ sites/common_site_config.json | jq -r \".redis_queue // empty\"` ]];
							do
							  echo \"Waiting for sites/common_site_config.json to be created\";
							  sleep 5;
							  if (( `date +%s`-start > 600 )); then
							    echo \"could not find sites/common_site_config.json with required keys\";
							    exit 1
							  fi
							done;
							echo \"sites/common_site_config.json found\";

							echo \"Waiting for database to be reachable...\";
							wait-for-it -t 180 $(DB_HOST):$(DB_PORT);
							echo \"Database is reachable.\";
							""",
						]
						env: [
							{
								name:  "DB_HOST"
								value: #config._dbHost
							},
							{
								name:  "DB_PORT"
								value: "\(#config._dbPort)"
							},
						]
						resources:       #config.jobs.createMultipleSites.resources
						securityContext: #config.securityContext
						volumeMounts: [
							{
								name:      "sites-dir"
								mountPath: "/home/frappe/frappe-bench/sites"
							},
						]
					},
				]
				containers: [
					{
						name:            "create-multi"
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						command: ["bash", "-c"]
						args: [_full_script]
						env: [
							{
								name:  "DB_TYPE"
								value: #config.jobs.createMultipleSites.dbType
							},
							{
								name:  "DB_HOST"
								value: #config._dbHost
							},
							{
								name:  "DB_PORT"
								value: "\(#config._dbPort)"
							},
							{
								name:  "DB_ROOT_USER"
								value: #config._dbRootUser
							},
							{
								name: "DB_ROOT_PASSWORD"
								if #config["mariadb-sts"].enabled || #config["mariadb-subchart"].enabled {
									valueFrom: secretKeyRef: {
										key: "mariadb-root-password"
										name: #config.metadata.name
									}
								}
								if #config["postgresql-sts"].enabled || #config["postgresql-subchart"].enabled {
									valueFrom: secretKeyRef: {
										key: "postgres-password"
										name: #config.metadata.name
									}
								}
								if !(#config["mariadb-sts"].enabled || #config["postgresql-sts"].enabled || #config["mariadb-subchart"].enabled || #config["postgresql-subchart"].enabled) {
									if #config.dbExistingSecret != "" {
										valueFrom: secretKeyRef: {
											name: #config.dbExistingSecret
											key:  #config.dbExistingSecretPasswordKey
										}
									}
									if #config.dbExistingSecret == "" {
										valueFrom: secretKeyRef: {
											name: #config.metadata.name
											key:  "db-root-password"
										}
									}
								}
							},
							{
								name: "ADMIN_PASSWORD"
								value: #config.jobs.createMultipleSites.adminPassword
							},
						]
						resources:       #config.jobs.createMultipleSites.resources
						securityContext: #config.securityContext
						volumeMounts: [
							{
								name:      "sites-dir"
								mountPath: "/home/frappe/frappe-bench/sites"
							},
							{
								name:      "logs"
								mountPath: "/home/frappe/frappe-bench/logs"
							},
						]
					},
				]
				volumes: [
					{
						name: "sites-dir"
						if #config.persistence.worker.enabled {
							persistentVolumeClaim: {
								if #config.persistence.worker.existingClaim != "" {
									claimName: #config.persistence.worker.existingClaim
								}
								if #config.persistence.worker.existingClaim == "" {
									claimName: #config.metadata.name
								}
								readOnly: false
							}
						}
						if !#config.persistence.worker.enabled {
							emptyDir: {}
						}
					},
					{
						name: "logs"
						if #config.persistence.logs.enabled {
							persistentVolumeClaim: {
								if #config.persistence.logs.existingClaim != "" {
									claimName: #config.persistence.logs.existingClaim
								}
								if #config.persistence.logs.existingClaim == "" {
									claimName: "\(#config.metadata.name)-logs"
								}
								readOnly: false
							}
						}
						if !#config.persistence.logs.enabled {
							emptyDir: {}
						}
					},
				]
				if #config.jobs.createMultipleSites.nodeSelector != _|_ {
					nodeSelector: #config.jobs.createMultipleSites.nodeSelector
				}
				if #config.jobs.createMultipleSites.affinity != _|_ {
					affinity: #config.jobs.createMultipleSites.affinity
				}
				if #config.jobs.createMultipleSites.tolerations != _|_ {
					tolerations: #config.jobs.createMultipleSites.tolerations
				}
			}
		}
	}
}
