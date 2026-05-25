package templates

import (
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
	"strings"
)

#AppDbJob: batchv1.#Job & {
	#config: #Config
	let app = #config."hyperswitch-app"
	let _registry = [if #config.global.imageRegistry != "" {#config.global.imageRegistry}, app.initDB.migration.imageRegistry][0]

	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		name:      "\(#config.metadata.name)-create-db-\(strings.Replace(app.services.router.version, ".", "-", -1))"
		namespace: #config.metadata.namespace
		labels: {
			"app": "\(#config.metadata.name)-create-db-\(strings.Replace(app.services.router.version, ".", "-", -1))"
		}
		annotations: {
			"helm.sh/hook":               "post-install,post-upgrade"
			"helm.sh/hook-delete-policy": "hook-succeeded"
		}
	}
	spec: batchv1.#JobSpec & {
		template: corev1.#PodTemplateSpec & {
			metadata: labels: {
				"sidecar.istio.io/inject": "false"
			}
			spec: corev1.#PodSpec & {
				restartPolicy: "OnFailure"

				if len(#config.global.tolerations) > 0 {
					tolerations: #config.global.tolerations
				}
				if len(#config.global.tolerations) == 0 && len((app.server.tolerations | *[])) > 0 {
					tolerations: app.server.tolerations
				}

				if len(#config.global.affinity) > 0 {
					affinity: #config.global.affinity
				}
				if len(#config.global.affinity) == 0 && len((app.server.affinity | *{})) > 0 {
					affinity: app.server.affinity
				}

				if len(#config.global.nodeSelector) > 0 {
					nodeSelector: #config.global.nodeSelector
				}
				if len(#config.global.nodeSelector) == 0 && len((app.server.nodeSelector | *{})) > 0 {
					nodeSelector: app.server.nodeSelector
				}

				initContainers: [
					(#PostgresqlInitContainer & {#config: #config}).container,
				]

				_pgInit: #PostgresqlInitContainer & {#config: #config}
				_pgHost: _pgInit.pgHost
				_pgDB:   _pgInit.pgDB
				_pgUser: _pgInit.pgUser
				_pgEnvVars: (#PostgresqlSecretsEnvs & {#config: #config}).env
				_pgPass: [for env in _pgEnvVars if env.name == "ROUTER__MASTER_DATABASE__PASSWORD" {env.valueFrom}][0]

				containers: [
					corev1.#Container & {
						name:            "run-hyperswitch-db-migration"
						image:           "\(_registry)/\(app.initDB.migration.image)"
						imagePullPolicy: "IfNotPresent"
						command: ["/bin/sh", "-c"]
						args: [
							"""
							curl -L -o hyperswitch.tar.gz https://github.com/juspay/hyperswitch/archive/refs/$REFERENCE/$ROUTER_VERSION.tar.gz
							tar -xzvf hyperswitch.tar.gz --transform 's|[^/]*/|hyperswitch/|'
							cd hyperswitch
							diesel migration --database-url postgres://$POSTGRES_USER:$POSTGRES_PASSWORD@$POSTGRES_HOST:5432/$DBNAME run
							echo "Completed hyperswitch database migration"
							""",
						]
						env: [
							{name: "REFERENCE", value: app.initDB.refs},
							{name: "ROUTER_VERSION", value: app.services.router.version},
							{name: "POSTGRES_HOST", value: _pgHost},
							{name: "DBNAME", value: _pgDB},
							{name: "POSTGRES_USER", value: _pgUser},
							{name: "POSTGRES_PASSWORD", valueFrom: _pgPass},
						]
					},
				]
			}
		}
	}
}
