package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#RouterConfigMap: corev1.#ConfigMap & {
	#config: #Config
	let app = #config."hyperswitch-app"

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-configs"
		namespace: #config.metadata.namespace
		labels: #config.global.labels & {
			"app.kubernetes.io/component": "config-map"
		}
	}
	data: {
		"ROUTER__MASTER_DATABASE__DBNAME": [if app.postgresql.enabled {app.postgresql.global.postgresql.auth.database}, app.externalPostgresql.master.auth.database][0]
		"ROUTER__MASTER_DATABASE__HOST": [if app.postgresql.enabled {"\(#config.metadata.name)-postgresql"}, app.externalPostgresql.master.host][0]
		"ROUTER__MASTER_DATABASE__PORT": "5432"
		"ROUTER__MASTER_DATABASE__USERNAME": [if app.postgresql.enabled {app.postgresql.global.postgresql.auth.username}, app.externalPostgresql.master.auth.username][0]
		"ROUTER__REPLICA_DATABASE__DBNAME": [if app.postgresql.enabled {app.postgresql.global.postgresql.auth.database}, app.externalPostgresql.readOnly.auth.database][0]
		"ROUTER__REPLICA_DATABASE__HOST": [if app.postgresql.enabled {"\(#config.metadata.name)-postgresql-read"}, app.externalPostgresql.readOnly.host][0]
		"ROUTER__REPLICA_DATABASE__PORT": "5432"
		"ROUTER__REPLICA_DATABASE__USERNAME": [if app.postgresql.enabled {app.postgresql.global.postgresql.auth.username}, app.externalPostgresql.readOnly.auth.username][0]
		"ROUTER__REDIS__HOST": [if app.redis.enabled {"\(#config.metadata.name)-redis-master"}, app.externalRedis.host][0]
		"ROUTER__REDIS__PORT": "6379"
		"ROUTER__REDIS__ENABLED": "true"
		// Configs from values.server.configs
		"ROUTER__PROXY__ENABLED":                                             "\((app.server.configs.proxy.enabled | *false))"
		"ROUTER__MULTITENANCY__ENABLED":                                                 "\(app.server.configs.multitenancy.enabled)"
		"ROUTER__MULTITENANCY__GLOBAL_TENANT__CLICKHOUSE_DATABASE":                       app.server.configs.multitenancy.global_tenant.clickhouse_database
		"ROUTER__MULTITENANCY__GLOBAL_TENANT__REDIS_KEY_PREFIX":                           app.server.configs.multitenancy.global_tenant.redis_key_prefix
		"ROUTER__MULTITENANCY__GLOBAL_TENANT__SCHEMA":                                    app.server.configs.multitenancy.global_tenant.schema
		"ROUTER__MULTITENANCY__GLOBAL_TENANT__TENANT_ID":                                 app.server.configs.multitenancy.global_tenant.tenant_id
		"ROUTER__MULTITENANCY__TENANTS__PUBLIC__BASE_URL":                                app.server.configs.multitenancy.tenants.public.base_url
		"ROUTER__MULTITENANCY__TENANTS__PUBLIC__SCHEMA":                                   app.server.configs.multitenancy.tenants.public.schema
		"ROUTER__MULTITENANCY__TENANTS__PUBLIC__ACCOUNTS_SCHEMA":                          app.server.configs.multitenancy.tenants.public.accounts_schema
		"ROUTER__MULTITENANCY__TENANTS__PUBLIC__REDIS_KEY_PREFIX":                         app.server.configs.multitenancy.tenants.public.redis_key_prefix
		"ROUTER__MULTITENANCY__TENANTS__PUBLIC__CLICKHOUSE_DATABASE":                      app.server.configs.multitenancy.tenants.public.clickhouse_database
		"ROUTER__MULTITENANCY__TENANTS__PUBLIC__USER__CONTROL_CENTER_URL":                 app.server.configs.multitenancy.tenants.public.user.control_center_url
		"ROUTER__MASTER_DATABASE__CONNECTION_TIMEOUT":                        "10"
		"ROUTER__REPLICA_DATABASE__CONNECTION_TIMEOUT":                       "10"
		"ROUTER__MASTER_DATABASE__POOL_SIZE":                                 "5"
		"ROUTER__REPLICA_DATABASE__POOL_SIZE":                                "5"
		"ROUTER__EMAIL__SMTP__TIMEOUT":                                        "10"
		"ROUTER__GRPC_CLIENT__UNIFIED_CONNECTOR_SERVICE__CONNECTION_TIMEOUT": "10"
		"ROUTER__CONNECTORS__HYPERSWITCH_VAULT__BASE_URL":                    "http://localhost:8080"
		"ROUTER__CONNECTORS__UNIFIED_AUTHENTICATION_SERVICE__BASE_URL":       "http://localhost:8080"
		"ROUTER__LOCK_SETTINGS__REDIS_LOCK_EXPIRY_SECONDS":                  "180"
		"ROUTER__LOCK_SETTINGS__DELAY_BETWEEN_RETRIES_IN_MILLISECONDS":      "500"
		"ROUTER__EMAIL__SMTP__USERNAME":                                      "hyperswitch"
		"ROUTER__EMAIL__SMTP__PASSWORD":                                      "hyperswitch"
	}
}

#RouterSecret: corev1.#Secret & {
	#config: #Config
	let app = #config."hyperswitch-app"

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-secrets"
		namespace: #config.metadata.namespace
		labels: #config.global.labels & {
			"app.kubernetes.io/component": "secret"
		}
	}
	stringData: {
		"ROUTER__FOREX_API_KEY":          app.server.secrets.forex_api_key
		"ROUTER__FOREX_FALLBACK_API_KEY": app.server.secrets.forex_fallback_api_key
		"ROUTER__SECRETS__JWT_SECRET":    app.server.secrets.jwt_secret
		"ROUTER__SECRETS__ADMIN_API_KEY": app.server.secrets.admin_api_key
		"ROUTER__SECRETS__MASTER_ENC_KEY": app.server.secrets.master_enc_key
		"ROUTER__SECRETS__RECON_ADMIN_API_KEY": app.server.secrets.recon_admin_api_key
		"ROUTER__API_KEYS__HASH_KEY": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
	}
}
