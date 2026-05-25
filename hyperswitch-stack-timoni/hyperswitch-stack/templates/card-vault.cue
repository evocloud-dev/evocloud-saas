package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
	batchv1 "k8s.io/api/batch/v1"
	"strings"
	"list"
)

// 1. /charts/hyperswitch-card-vault/templates/configmap.yaml
#CardVaultConfigMap: corev1.#ConfigMap & {
	#config: #Config
	let cv = #config."hyperswitch-app"."hyperswitch-card-vault"
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "hyperswitch-vault-config-\(#config.metadata.name)"
		namespace: #config.metadata.namespace
		labels: {
			for k, v in #config.metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
			"app.kubernetes.io/name": "hyperswitch-card-vault"
		}
	}
	data: {
		let server_toml = """
			[server]
			host = "\(cv.server.host)"
			port = \(cv.server.port)

			[secrets]
			tenant = "hyperswitch"
			"""

		let sm_toml = [
			if cv.backend == "aws" {
				"""
				[secrets_management]
				secrets_manager = "aws_kms"

				[secrets_management.aws_kms]
				key_id = "\(cv.secrets.aws.key_id)"
				region = "\(cv.secrets.aws.region)"
				"""
			},
			if cv.backend == "vault" {
				"""
				[secrets_management]
				secrets_manager = "hashi_corp_vault"

				[secrets_management.hashi_corp_vault]
				url = "\(cv.server.vault.url)"
				token = "\(cv.secrets.vault.token)"
				"""
			},
		]

		let tls_toml = [
			if cv.secrets.tls.certificate != "" && cv.secrets.tls.private_key != "" {
				"""
				[tls]
				certificate = "\(cv.secrets.tls.certificate)"
				private_key = "\(cv.secrets.tls.private_key)"
				"""
			},
		]

		let ekm_toml = [
			if cv.secrets.external_key_manager.cert != "" {
				"""
				[external_key_manager]
				url = "\(cv.server.externalKeyManager.url)"
				cert = "\(cv.server.externalKeyManager.cert)"
				
				[api_client]
				client_idle_timeout = 90
				pool_max_idle_per_host = 10
				identity = "\(cv.server.apiClient.identity)"
				"""
			},
			if cv.secrets.external_key_manager.cert == "" {
				"""
				[external_key_manager]
				url = "\(cv.server.externalKeyManager.url)"
				
				[api_client]
				client_idle_timeout = 90
				pool_max_idle_per_host = 10
				"""
			},
		]

		let parts = list.Concat([[server_toml], sm_toml, tls_toml, [ekm_toml[0]]])
		"development.toml": strings.Join([for p in parts if p != _|_ {p}], "\n\n")
	}
}

// 2. /charts/hyperswitch-card-vault/templates/secrets.yaml
#CardVaultSecrets: corev1.#Secret & {
	#config: #Config
	let cv = #config."hyperswitch-app"."hyperswitch-card-vault"
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "locker-secrets-\(#config.metadata.name)"
		namespace: #config.metadata.namespace
		labels: {
			for k, v in #config.metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
			"app.kubernetes.io/name": "hyperswitch-card-vault"
		}
	}
	type: "Opaque"
	stringData: {
		"LOCKER__DATABASE__PASSWORD":                 cv.postgresql.auth.password
		"LOCKER__SECRETS__LOCKER_PRIVATE_KEY":        cv.secrets.locker_private_key
		"LOCKER__TENANT_SECRETS__PUBLIC__MASTER_KEY": cv.server.tenant_secrets.hyperswitch.master_key
		"LOCKER__TENANT_SECRETS__PUBLIC__PUBLIC_KEY": cv.server.tenant_secrets.hyperswitch.public_key

		if cv.backend == "aws" {
			"LOCKER__SECRETS_MANAGEMENT__AWS_KMS__KEY_ID": cv.secrets.aws.key_id
			"LOCKER__SECRETS_MANAGEMENT__AWS_KMS__REGION": cv.secrets.aws.region
		}
		if cv.backend == "vault" {
			"LOCKER__SECRETS_MANAGEMENT__HASHI_CORP_VAULT__TOKEN": cv.secrets.vault.token
		}
		if cv.secrets.tls.certificate != "" {
			"LOCKER__TLS__CERTIFICATE": cv.secrets.tls.certificate
		}
		if cv.secrets.tls.private_key != "" {
			"LOCKER__TLS__PRIVATE_KEY": cv.secrets.tls.private_key
		}
		if cv.secrets.external_key_manager.cert != "" {
			"LOCKER__EXTERNAL_KEY_MANAGER__CERT": cv.secrets.external_key_manager.cert
		}
		if cv.secrets.api_client.identity != "" {
			"LOCKER__API_CLIENT__IDENTITY": cv.secrets.api_client.identity
		}
	}
}

// 3. /charts/hyperswitch-card-vault/templates/sa.yaml
#CardVaultServiceAccount: corev1.#ServiceAccount & {
	#config: #Config
	let cv = #config."hyperswitch-app"."hyperswitch-card-vault"
	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name:      "\(#config.metadata.name)-vault-role"
		namespace: #config.metadata.namespace
		labels: {
			for k, v in #config.metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
			"app.kubernetes.io/name": "hyperswitch-card-vault"
		}
		if cv.backend == "aws" && cv.server.annotations != _|_ {
			annotations: cv.server.annotations
		}
	}
}

// 4. /charts/hyperswitch-card-vault/templates/service.yaml
#CardVaultService: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-vault"
		namespace: #config.metadata.namespace
		labels: {
			for k, v in #config.metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
			"app.kubernetes.io/name": "hyperswitch-card-vault"
		}
	}
	spec: {
		internalTrafficPolicy: "Cluster"
		ipFamilies: ["IPv4"]
		ipFamilyPolicy: "SingleStack"
		ports: [
			{
				name:       "http"
				port:       80
				targetPort: 8080
				protocol:   "TCP"
			},
			{
				name:       "https"
				port:       443
				targetPort: 8080
				protocol:   "TCP"
			},
		]
		selector: {
			app: "\(#config.metadata.name)-card-vault"
		}
		sessionAffinity: "None"
		type:            "ClusterIP"
	}
}

// 5. /charts/hyperswitch-card-vault/templates/deployment.yaml
#CardVaultDeployment: appsv1.#Deployment & {
	#config: #Config
	let cv = #config."hyperswitch-app"."hyperswitch-card-vault"
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "hyperswitch-card-vault-\(#config.metadata.name)"
		namespace: #config.metadata.namespace
		labels: {
			for k, v in #config.metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
			"app.kubernetes.io/name": "hyperswitch-card-vault"
		}
		if cv.server.annotations != _|_ {
			annotations: cv.server.annotations
		}
	}
	spec: {
		replicas: 1
		selector: matchLabels: app: "\(#config.metadata.name)-card-vault"
		strategy: {
			type: "RollingUpdate"
			rollingUpdate: maxUnavailable: 0
		}
		template: {
			metadata: {
				annotations: {
					"checksum/config":  "placeholder" // In Timoni, we often omit checksums if using ConfigMap rollout
					"checksum/secrets": "placeholder"
					if cv.server.pod.annotations != _|_ {
						for k, v in cv.server.pod.annotations {"\(k)": v}
					}
				}
				labels: app: "\(#config.metadata.name)-card-vault"
			}
			spec: {
				if cv.server.tolerations != _|_ {
					tolerations: cv.server.tolerations
				}
				if cv.server.affinity != _|_ {
					affinity: cv.server.affinity
				}
				if cv.server.nodeSelector != _|_ {
					nodeSelector: cv.server.nodeSelector
				}
				containers: [
					{
						name:            "tartarus"
						image:           "\(cv.server.imageRegistry)/\(cv.server.image)"
						imagePullPolicy: "IfNotPresent"
						env: [
							{name: "LOCKER__LOG__CONSOLE__ENABLED", value: "true"},
							{name: "LOCKER__LOG__CONSOLE__LEVEL", value: "DEBUG"},
							{name: "LOCKER__LOG__CONSOLE__LOG_FORMAT", value: "default"},
							{name: "LOCKER__SERVER__HOST", value: cv.server.host},
							{name: "LOCKER__SERVER__PORT", value: "\(cv.server.port)"},
							{name: "LOCKER__DATABASE__USERNAME", value: cv.postgresql.auth.username},
							{
								name: "LOCKER__DATABASE__PASSWORD"
								valueFrom: secretKeyRef: {
									name: "locker-secrets-\(#config.metadata.name)"
									key:  "LOCKER__DATABASE__PASSWORD"
								}
							},
							{name: "LOCKER__DATABASE__HOST", value: "\(#config.metadata.name)-locker-db"},
							{name: "LOCKER__DATABASE__PORT", value: "5432"},
							{name: "LOCKER__DATABASE__DBNAME", value: cv.postgresql.auth.database},
							{name: "LOCKER__LIMIT__REQUEST_COUNT", value: "100"},
							{name: "LOCKER__LIMIT__DURATION", value: "60"},
							{name: "LOCKER__SECRETS__TENANT", value: "hyperswitch"},
							{
								name: "LOCKER__SECRETS__LOCKER_PRIVATE_KEY"
								valueFrom: secretKeyRef: {
									name: "locker-secrets-\(#config.metadata.name)"
									key:  "LOCKER__SECRETS__LOCKER_PRIVATE_KEY"
								}
							},
							{
								name: "LOCKER__TENANT_SECRETS__PUBLIC__MASTER_KEY"
								valueFrom: secretKeyRef: {
									name: "locker-secrets-\(#config.metadata.name)"
									key:  "LOCKER__TENANT_SECRETS__PUBLIC__MASTER_KEY"
								}
							},
							{
								name: "LOCKER__TENANT_SECRETS__PUBLIC__PUBLIC_KEY"
								valueFrom: secretKeyRef: {
									name: "locker-secrets-\(#config.metadata.name)"
									key:  "LOCKER__TENANT_SECRETS__PUBLIC__PUBLIC_KEY"
								}
							},
							{name: "LOCKER__TENANT_SECRETS__PUBLIC__SCHEMA", value: cv.server.tenant_secrets.hyperswitch.schema},
							if cv.backend == "aws" {
								{name: "LOCKER__SECRETS_MANAGEMENT__SECRETS_MANAGER", value: "aws_kms"}
							},
							if cv.backend == "aws" {
								{
									name: "LOCKER__SECRETS_MANAGEMENT__AWS_KMS__KEY_ID"
									valueFrom: secretKeyRef: {
										name: "locker-secrets-\(#config.metadata.name)"
										key:  "LOCKER__SECRETS_MANAGEMENT__AWS_KMS__KEY_ID"
									}
								}
							},
							if cv.backend == "aws" {
								{
									name: "LOCKER__SECRETS_MANAGEMENT__AWS_KMS__REGION"
									valueFrom: secretKeyRef: {
										name: "locker-secrets-\(#config.metadata.name)"
										key:  "LOCKER__SECRETS_MANAGEMENT__AWS_KMS__REGION"
									}
								}
							},
							if cv.backend == "vault" {
								{name: "LOCKER__SECRETS_MANAGEMENT__SECRETS_MANAGER", value: "hashi_corp_vault"}
							},
							if cv.backend == "vault" {
								{name: "LOCKER__SECRETS_MANAGEMENT__HASHI_CORP_VAULT__URL", value: cv.server.vault.url}
							},
							if cv.backend == "vault" {
								{
									name: "LOCKER__SECRETS_MANAGEMENT__HASHI_CORP_VAULT__TOKEN"
									valueFrom: secretKeyRef: {
										name: "locker-secrets-\(#config.metadata.name)"
										key:  "LOCKER__SECRETS_MANAGEMENT__HASHI_CORP_VAULT__TOKEN"
									}
								}
							},
							{name: "LOCKER__CACHE__MAX_CAPACITY", value: "5000"},
							{name: "LOCKER__CACHE__TTI", value: "7200"},
							{name: "LOCKER__EXTERNAL_KEY_MANAGER__URL", value: cv.server.externalKeyManager.url},
							if cv.secrets.external_key_manager.cert != "" {
								{
									name: "LOCKER__EXTERNAL_KEY_MANAGER__CERT"
									valueFrom: secretKeyRef: {
										name: "locker-secrets-\(#config.metadata.name)"
										key:  "LOCKER__EXTERNAL_KEY_MANAGER__CERT"
									}
								}
							},
							if cv.secrets.api_client.identity != "" {
								{
									name: "LOCKER__API_CLIENT__IDENTITY"
									valueFrom: secretKeyRef: {
										name: "locker-secrets-\(#config.metadata.name)"
										key:  "LOCKER__API_CLIENT__IDENTITY"
									}
								}
							},
							if cv.secrets.tls.certificate != "" {
								{
									name: "LOCKER__TLS__CERTIFICATE"
									valueFrom: secretKeyRef: {
										name: "locker-secrets-\(#config.metadata.name)"
										key:  "LOCKER__TLS__CERTIFICATE"
									}
								}
							},
							if cv.secrets.tls.private_key != "" {
								{
									name: "LOCKER__TLS__PRIVATE_KEY"
									valueFrom: secretKeyRef: {
										name: "locker-secrets-\(#config.metadata.name)"
										key:  "LOCKER__TLS__PRIVATE_KEY"
									}
								}
							},
							for k, v in cv.server.extra.env {
								{
									name:  "\(k)"
									value: "\(v)"
								}
							},
						]
						lifecycle: preStop: exec: command: ["/bin/bash", "-c", "pkill -15 node"]
						livenessProbe: {
							failureThreshold: 3
							httpGet: {path: "/health", port: 8080, scheme: "HTTP"}
							initialDelaySeconds: 5
							periodSeconds:       30
							successThreshold:    1
							timeoutSeconds:      1
						}
						ports: [{containerPort: 8080, name: "http", protocol: "TCP"}]
						readinessProbe: {
							failureThreshold: 3
							httpGet: {path: "/health", port: 8080, scheme: "HTTP"}
							initialDelaySeconds: 5
							periodSeconds:       50
							successThreshold:    1
							timeoutSeconds:      1
						}
						resources: requests: {cpu: "100m", memory: "200Mi"}
						securityContext: privileged: false
						terminationMessagePath:   "/dev/termination-log"
						terminationMessagePolicy: "File"
						volumeMounts: [{mountPath: "/local/config/development.toml", name: "hyperswitch-vault-config", subPath: "development.toml"}]
					},
				]
				dnsPolicy:     "ClusterFirst"
				restartPolicy: "Always"
				schedulerName: "default-scheduler"
				securityContext: {}
				serviceAccount:                "\(#config.metadata.name)-vault-role"
				serviceAccountName:            "\(#config.metadata.name)-vault-role"
				terminationGracePeriodSeconds: 120
				volumes: [
					{
						name: "hyperswitch-vault-config"
						configMap: {
							defaultMode: 420
							name:        "hyperswitch-vault-config-\(#config.metadata.name)"
						}
					},
				]
			}
		}
	}
}

// 6. /charts/hyperswitch-card-vault/templates/migration-db.yaml
#CardVaultMigrationJob: batchv1.#Job & {
	#config: #Config
	let cv = #config."hyperswitch-app"."hyperswitch-card-vault"
	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		name:      "\(#config.metadata.name)-create-locker-db-\(cv.server.version)"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app": "\(#config.metadata.name)-create-locker-db-\(cv.server.version)"
		}
		annotations: {
			"helm.sh/hook":               "post-install,post-upgrade"
			"helm.sh/hook-delete-policy": "hook-succeeded"
		}
	}
	spec: {
		template: {
			metadata: labels: "sidecar.istio.io/inject": "false"
			spec: {
				restartPolicy: "OnFailure"
				if cv.server.pod.tolerations != _|_ {
					tolerations: cv.server.pod.tolerations
				}
				if cv.server.affinity != _|_ {
					affinity: cv.server.affinity
				}
				if cv.server.nodeSelector != _|_ {
					nodeSelector: cv.server.nodeSelector
				}
				initContainers: [
					{
						name:  "check-postgres"
						image: "\(cv.initDB.checkPGisUp.imageRegistry)/\(cv.initDB.checkPGisUp.image)"
						env: [{
							name:  "PGPASSWORD"
							value: cv.postgresql.auth.password
						}]
						command: ["/bin/sh", "-c"]
						args: ["""
							MAX_ATTEMPTS=\(cv.initDB.checkPGisUp.maxAttempt);
							SLEEP_SECONDS=5;
							attempt=0;
							while ! pg_isready -U \(cv.postgresql.auth.username) -d \(cv.postgresql.auth.database) -h \(#config.metadata.name)-locker-db -p 5432; do
							  if [ $attempt -ge $MAX_ATTEMPTS ]; then
							    echo "PostgreSQL did not become ready in time";
							    exit 1;
							  fi;
							  attempt=$((attempt+1));
							  echo "Waiting for PostgreSQL to be ready... Attempt: $attempt";
							  sleep $SLEEP_SECONDS;
							done;
							""",
						]
					},
				]
				containers: [
					{
						name:            "run-locker-db-migration"
						image:           "\(cv.initDB.migration.imageRegistry)/\(cv.initDB.migration.image)"
						imagePullPolicy: "IfNotPresent"
						command: ["/bin/sh", "-c"]
						args: ["""
							echo "Downloading migrations..."
							curl -L -o hyperswitch-card-vault.tar.gz https://github.com/juspay/hyperswitch-card-vault/archive/refs/tags/$VERSION.tar.gz
							mkdir -p hyperswitch-card-vault
							tar -xzvf hyperswitch-card-vault.tar.gz -C hyperswitch-card-vault --strip-components=1
							cd hyperswitch-card-vault
							
							echo "Running Diesel migrations"
							diesel migration run --database-url postgres://$POSTGRES_USER:$POSTGRES_PASSWORD@$POSTGRES_HOST:$POSTGRES_PORT/$DBNAME

							echo "Completed Card-Vault database migration"
							""",
						]
						env: [
							{name: "POSTGRES_HOST", value: "\(#config.metadata.name)-locker-db"},
							{name: "POSTGRES_PORT", value: "5432"},
							{name: "DBNAME", value: cv.postgresql.auth.database},
							{name: "POSTGRES_USER", value: cv.postgresql.auth.username},
							{name: "VERSION", value: cv.server.version},
							{
								name: "POSTGRES_PASSWORD"
								valueFrom: secretKeyRef: {
									name: "locker-secrets-\(#config.metadata.name)"
									key:  "LOCKER__DATABASE__PASSWORD"
								}
							},
						]
					},
				]
			}
		}
	}
}

// 7. /charts/hyperswitch-card-vault/templates/vault-keys-job-dev.yaml
#CardVaultKeysJobDev: batchv1.#Job & {
	#config: #Config
	let cv = #config."hyperswitch-app"."hyperswitch-card-vault"
	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		name:      "\(#config.metadata.name)-vault-keys-config"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app": "hyperswitch-vault-keys"
		}
		annotations: {
			"helm.sh/hook":               "post-install,post-upgrade"
			"helm.sh/hook-delete-policy": "hook-succeeded"
		}
	}
	spec: {
		template: {
			metadata: labels: "sidecar.istio.io/inject": "false"
			spec: {
				restartPolicy: "OnFailure"
				initContainers: [
					{
						name:  "check-vault-service-ready"
						image: "\(cv.vaultKeysJob.checkVaultService.imageRegistry)/\(cv.vaultKeysJob.checkVaultService.image)"
						command: ["/bin/sh", "-c"]
						args: ["""
							MAX_ATTEMPTS=\(cv.vaultKeysJob.checkVaultService.maxAttempt);
							SLEEP_SECONDS=5;
							attempt=0;
							while true; do
							  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://\(#config.metadata.name)-vault.\(#config.metadata.namespace).svc.cluster.local/health)
							  if [ "$HTTP_STATUS" = "200" ]; then
							    echo " Vault service is healthy.";
							    break;
							  fi
							  if [ $attempt -ge $MAX_ATTEMPTS ]; then
							    echo "Vault service did not become healthy in time (last HTTP status: $HTTP_STATUS)";
							    exit 1;
							  fi;
							  attempt=$((attempt+1));
							  echo "Waiting for Vault service to be healthy... Attempt: $attempt";
							  sleep $SLEEP_SECONDS;
							done;
							""",
						]
					},
				]
				containers: [
					{
						name:  "run-vault-key-setup"
						image: "\(cv.vaultKeysJob.checkVaultService.imageRegistry)/\(cv.vaultKeysJob.checkVaultService.image)"
						command: ["/bin/sh", "-c"]
						args: ["""
							set -e
							echo "Posting key1..."
							curl -X POST http://\(#config.metadata.name)-vault.\(#config.metadata.namespace).svc.cluster.local/custodian/key1 -H "Content-Type: application/json" -H "x-tenant-id: public" -d '{"key": "\(cv.vaultKeysJob.keys.key1)"}'
							
							echo "Posting key2..."
							curl -X POST http://\(#config.metadata.name)-vault.\(#config.metadata.namespace).svc.cluster.local/custodian/key2 -H "Content-Type: application/json" -H "x-tenant-id: public" -d '{"key": "\(cv.vaultKeysJob.keys.key2)"}'
							
							echo "Calling decrypt endpoint..."
							curl -X POST http://\(#config.metadata.name)-vault.\(#config.metadata.namespace).svc.cluster.local/custodian/decrypt -H "Content-Type: application/json" -H "x-tenant-id: public"
							""",
						]
						resources: requests: {cpu: "100m", memory: "128Mi"}
					},
				]
			}
		}
	}
}
