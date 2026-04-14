package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#CoreSecret: corev1.#Secret & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-core"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "openproject"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	type: "Opaque"
	stringData: {
		if #config.postgresql.bundled {
			DATABASE_HOST: "\(#config.metadata.name)-postgresql.\(#config.metadata.namespace).svc.\(#config.clusterDomain)"
			DATABASE_PORT: "5432"
			DATABASE_URL:  "postgresql://\(#config.postgresql.auth.username)@\(#config.metadata.name)-postgresql:5432/\(#config.postgresql.auth.database)"
		}
		if !#config.postgresql.bundled {
			DATABASE_HOST: #config.postgresql.connection.host
			DATABASE_PORT: "\(#config.postgresql.connection.port)"
			DATABASE_URL:  "postgresql://\(#config.postgresql.auth.username)@\(#config.postgresql.connection.host):\(#config.postgresql.connection.port)/\(#config.postgresql.auth.database)"
		}

		if #config.postgresql.options.pool != null {
			OPENPROJECT_DB_POOL: "\(#config.postgresql.options.pool)"
		}
		if #config.postgresql.options.requireAuth != null {
			OPENPROJECT_DB_REQUIRE_AUTH: "\( #config.postgresql.options.requireAuth )"
		}
		if #config.postgresql.options.channelBinding != null {
			OPENPROJECT_DB_CHANNEL_BINDING: #config.postgresql.options.channelBinding
		}
		if #config.postgresql.options.connectTimeout != null {
			OPENPROJECT_DB_CONNECT_TIMEOUT: "\(#config.postgresql.options.connectTimeout)"
		}
		if #config.postgresql.options.clientEncoding != null {
			OPENPROJECT_DB_CLIENT_ENCODING: #config.postgresql.options.clientEncoding
		}
		if #config.postgresql.options.keepalives != null {
			OPENPROJECT_DB_KEEPALIVES: "\(#config.postgresql.options.keepalives)"
		}
		if #config.postgresql.options.keepalivesIdle != null {
			OPENPROJECT_DB_KEEPALIVES_IDLE: "\(#config.postgresql.options.keepalivesIdle)"
		}
		if #config.postgresql.options.keepalivesInterval != null {
			OPENPROJECT_DB_KEEPALIVES_INTERVAL: "\(#config.postgresql.options.keepalivesInterval)"
		}
		if #config.postgresql.options.keepalivesCount != null {
			OPENPROJECT_DB_KEEPALIVES_COUNT: "\(#config.postgresql.options.keepalivesCount)"
		}
		if #config.postgresql.options.replication != null {
			OPENPROJECT_DB_REPLICATION: #config.postgresql.options.replication
		}
		if #config.postgresql.options.gssencmode != null {
			OPENPROJECT_DB_GSSENCMODE: #config.postgresql.options.gssencmode
		}
		if #config.postgresql.options.sslmode != null {
			OPENPROJECT_DB_SSLMODE: #config.postgresql.options.sslmode
		}
		if #config.postgresql.options.sslcompression != null {
			OPENPROJECT_DB_SSLCOMPRESSION: "\(#config.postgresql.options.sslcompression)"
		}
		if #config.postgresql.options.sslcert != null {
			OPENPROJECT_DB_SSLCERT: #config.postgresql.options.sslcert
		}
		if #config.postgresql.options.sslkey != null {
			OPENPROJECT_DB_SSLKEY: #config.postgresql.options.sslkey
		}
		if #config.postgresql.options.sslpassword != null {
			OPENPROJECT_DB_SSLPASSWORD: #config.postgresql.options.sslpassword
		}
		if #config.postgresql.options.sslrootcert != null {
			OPENPROJECT_DB_SSLROOTCERT: #config.postgresql.options.sslrootcert
		}
		if #config.postgresql.options.sslcrl != null {
			OPENPROJECT_DB_SSLCRL: #config.postgresql.options.sslcrl
		}
		if #config.postgresql.options.sslMinProtocolVersion != null {
			OPENPROJECT_DB_SSL_MIN_PROTOCOL_VERSION: #config.postgresql.options.sslMinProtocolVersion
		}

		OPENPROJECT_SEED_ADMIN_USER_PASSWORD:       #config.openproject.admin_user.password
		OPENPROJECT_SEED_ADMIN_USER_PASSWORD_RESET: #config.openproject.admin_user.password_reset
		OPENPROJECT_SEED_ADMIN_USER_NAME:           #config.openproject.admin_user.name
		OPENPROJECT_SEED_ADMIN_USER_MAIL:           #config.openproject.admin_user.mail
		if #config.openproject.admin_user.locked {
			OPENPROJECT_SEED_ADMIN_USER_LOCKED: "true"
		}

		OPENPROJECT_HTTPS: "\(#config.openproject.https)"
		if #config.openproject.seed_locale != null {
			OPENPROJECT_SEED_LOCALE: #config.openproject.seed_locale
		}

		// Trust openproject.local for Ingress and internal names for Hocuspocus
		OPENPROJECT_ADDITIONAL__HOST__NAMES: "[\"openproject.local\", \"openproject.local:8080\", \"localhost:9090\", \"op.op-ns.svc.cluster.local:8080\", \"op:8080\", \"op\"]"

		if #config.openproject.host != null {
			OPENPROJECT_HOST__NAME: #config.openproject.host
		}
		if #config.openproject.host == null {
			OPENPROJECT_HOST__NAME: #config.ingress.host
		}

		OPENPROJECT_HSTS:                "\(#config.openproject.hsts)"
		OPENPROJECT_RAILS__CACHE__STORE: #config.openproject.cache.store
		if #config.openproject.cache.store == "memcache" {
			if #config.memcached.bundled {
				OPENPROJECT_CACHE_MEMCACHE_SERVER: "\(#config.metadata.name)-memcached:11211"
			}
			if !#config.memcached.bundled && #config.memcached.connection.host != null {
				OPENPROJECT_CACHE_MEMCACHE_SERVER: "\(#config.memcached.connection.host):\(#config.memcached.connection.port)"
			}
		}

		if #config.openproject.railsRelativeUrlRoot != null {
			OPENPROJECT_RAILS__RELATIVE__URL__ROOT: #config.openproject.railsRelativeUrlRoot
		}

		POSTGRES_STATEMENT_TIMEOUT: #config.openproject.postgresStatementTimeout

		if #config.openproject.realtime_collaboration.enabled {
			let protocol = [
				if #config.openproject.https { "wss" },
				"ws",
			][0]
			let hostname = [
				if #config.openproject.realtime_collaboration.hocuspocus.host != null && #config.openproject.realtime_collaboration.hocuspocus.host != "" {
					#config.openproject.realtime_collaboration.hocuspocus.host
				},
				if #config.openproject.host != null && #config.openproject.host != "" {
					#config.openproject.host
				},
				if #config.ingress.host != null {
					#config.ingress.host
				},
			][0]
			// Construct the URL. If the hostname already starts with a protocol, use it as is.
			// Otherwise combine protocol, hostname and path.
			OPENPROJECT_COLLABORATIVE__EDITING__HOCUSPOCUS__URL: [
				if (hostname =~ "^(ws|http)s?://") {
					"\(hostname)\(#config.openproject.realtime_collaboration.hocuspocus.path)"
				},
				"\(protocol)://\(hostname)\(#config.openproject.realtime_collaboration.hocuspocus.path)",
			][0]
			OPENPROJECT_COLLABORATIVE__EDITING__HOCUSPOCUS__SECRET: #config.openproject.realtime_collaboration.hocuspocus.auth.secret
		}
	}
}
