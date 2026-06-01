package templates

import (
	corev1 "k8s.io/api/core/v1"
	batchv1 "k8s.io/api/batch/v1"
)

#ClickhouseInitJob: batchv1.#Job & {
	#config: #Config
	let ch = #config."hyperswitch-app".clickhouse
	let _metadata = #config.metadata
	let ns = _metadata.namespace
	let instanceName = _metadata.name
	let chName = ch.name

	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		name:      "\(instanceName)-\(chName)-init"
		namespace: ns
		labels: _metadata.labels & {
			"app.kubernetes.io/component": "clickhouse"
			"app.kubernetes.io/part-of":   "clickhouse-init"
		}
		annotations: {
			"helm.sh/hook":               "post-install,post-upgrade"
			"helm.sh/hook-delete-policy": "hook-succeeded,hook-failed"
		}
	}
	spec: batchv1.#JobSpec & {
		template: {
			metadata: labels: {
				"sidecar.istio.io/inject": "false"
			}
			spec: corev1.#PodSpec & {
				restartPolicy: "OnFailure"
				containers: [
					{
						name:            "clickhouse-init"
						image:           "\(ch.image.registry)/\(ch.image.repository):\(ch.image.tag)"
						imagePullPolicy: "IfNotPresent"
						command: ["sh", "-c"]
						args: [
							"""
							echo "Fetching ClickHouse admin password from environment..."
							if [ -z "$CLICKHOUSE_ADMIN_PASSWORD" ]; then
							  echo "Failed to retrieve password. Exiting..."
							  exit 1
							fi
							echo "Checking for SQL scripts..."
							if [ -z "$(ls -A /docker-entrypoint-initdb.d/*.sql 2>/dev/null)" ]; then
							  echo "No SQL scripts found. Exiting..."
							  exit 1
							fi

							echo "Executing ClickHouse init scripts..."
							cat /docker-entrypoint-initdb.d/*.sql | clickhouse-client --host=\(instanceName)-\(chName) --user default --password "$CLICKHOUSE_ADMIN_PASSWORD" --multiquery

							echo "ClickHouse initialization completed."
							""",
						]
						env: [
							{
								name: "CLICKHOUSE_ADMIN_PASSWORD"
								valueFrom: secretKeyRef: {
									name: "\(instanceName)-\(chName)"
									key:  "admin-password"
								}
							},
						]
						volumeMounts: [
							{
								name:      "init-scripts"
								mountPath: "/docker-entrypoint-initdb.d"
							},
						]
					},
				]
				volumes: [
					{
						name: "init-scripts"
						configMap: name: "\(instanceName)-\(chName)-script"
					},
				]
			}
		}
	}
}
