package templates

import (
	"encoding/yaml"
	corev1 "k8s.io/api/core/v1"
)

#ServerConfigMap: corev1.#ConfigMap & {
	#config: #Config
	let c = #config
	let h = #ServerComputed & {#config: c}

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name: *"\((#config.metadata.name))-server-config" | string
		if #config.server.config.configMapName != _|_ && #config.server.config.configMapName != null && #config.server.config.configMapName != "" {
			name: #config.server.config.configMapName
		}
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "server"
		}
		if len(#config.server.config.configMapAnnotations) > 0 {
			annotations: #config.server.config.configMapAnnotations
		}
	}
	data: "production.yaml": h.#productionYAML
}

#ServerComputed: {
	#config: #Config
	let c = #config

	#rawConfig: {
		if c.server.config.raw != "" {
			yaml.Unmarshal(c.server.config.raw)
		}
		if c.server.config.raw == "" {
			{}
		}
	}

	#productionYAML: yaml.Marshal(#mergedConfig)

	#mergedConfig: {
		for k, v in #rawConfig if k != "webserver" {
			"\(k)": v
		}

		database: {
			if !c.postgresql.enabled {
				hostname: c.server.externalPostgres.hostname
				port:     c.server.externalPostgres.port
				name:     *c.server.externalPostgres.db | string
			}
			if c.postgresql.enabled {
				hostname: "\((c.metadata.name))-postgresql"
				port:     5432
				name:     "peertube"
			}
			ssl: *false | bool
			if !c.postgresql.enabled && c.server.externalPostgres.ssl != _|_ {
				ssl: c.server.externalPostgres.ssl
			}
			suffix: *"" | string
			if !c.postgresql.enabled && c.server.externalPostgres.suffix != _|_ {
				suffix: c.server.externalPostgres.suffix
			}
			username: "$(PEERTUBE_DB_USERNAME)"
			pool: {
				max: *5 | int
				if !c.postgresql.enabled && c.server.externalPostgres.pool.max != _|_ {
					max: c.server.externalPostgres.pool.max
				}
			}
		}

		redis: {
			if !c.redis.enabled {
				hostname: c.server.externalRedis.hostname
				port:     c.server.externalRedis.port
			}
			if c.redis.enabled {
				hostname: "\((c.metadata.name))-redis"
				port:     6379
			}
			db: *0 | int
			if !c.redis.enabled && c.server.externalRedis.db != _|_ {
				db: c.server.externalRedis.db
			}
			auth: "$(PEERTUBE_REDIS_AUTH)"
			sentinel: {
				enabled: *false | bool
				if !c.redis.enabled && c.server.externalRedis.sentinel.enabled != _|_ {
					enabled: c.server.externalRedis.sentinel.enabled
				}
				enable_tls: *false | bool
				if !c.redis.enabled && c.server.externalRedis.sentinel.enableTls != _|_ {
					enable_tls: c.server.externalRedis.sentinel.enableTls
				}
				if enabled {
					master_name: c.server.externalRedis.sentinel.masterName
					hostname:    c.server.externalRedis.sentinel.hostname
					port:        *26379 | int
					if c.server.externalRedis.sentinel.port != _|_ {
						port: c.server.externalRedis.sentinel.port
					}
				}
			}
		}
		webserver: {
			if #rawConfig.webserver != _|_ {
				for k, v in #rawConfig.webserver if k != "hostname" {
					"\(k)": v
				}
			}
			if #rawConfig.webserver == _|_ {
				https: true
				port:  443
			}

			#defaultHost: string
			if len(c.server.httpRoute.hostnames) > 0 {
				#defaultHost: c.server.httpRoute.hostnames[0]
			}
			if len(c.server.httpRoute.hostnames) == 0 {
				if len(c.server.ingress.hosts) > 0 {
					#defaultHost: c.server.ingress.hosts[0]
				}
				if len(c.server.ingress.hosts) == 0 {
					#defaultHost: "localhost"
				}
			}

			hostname: string
			if #rawConfig.webserver != _|_ && #rawConfig.webserver.hostname != _|_ && #rawConfig.webserver.hostname != "" {
				hostname: #rawConfig.webserver.hostname
			}
			if #rawConfig.webserver == _|_ || #rawConfig.webserver.hostname == _|_ || #rawConfig.webserver.hostname == "" {
				hostname: #defaultHost
			}
		}


		if c.server.objectStorage.enabled {
			object_storage: {
				force_path_style: true
				enabled:          true
				credentials: {
					access_key_id:     "$(PEERTUBE_OBJECT_STORAGE_CREDENTIALS_ACCESS_KEY_ID)"
					secret_access_key: "$(PEERTUBE_OBJECT_STORAGE_CREDENTIALS_SECRET_ACCESS_KEY)"
				}
				for k, v in c.server.objectStorage.config {
					if k != "enabled" && k != "credentials" {
						"\(k)": v
					}
				}
			}
		}
	}
}
