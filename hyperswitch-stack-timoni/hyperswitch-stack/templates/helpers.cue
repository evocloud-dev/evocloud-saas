package templates

import (
	corev1 "k8s.io/api/core/v1"
)

// Replaces templates/_envs.tpl and templates/_helpers.tpl

#MetadataEnvs: [
	{
		name: "POD_NAME"
		valueFrom: fieldRef: fieldPath: "metadata.name"
	},
	{
		name: "SERVICE_NAME"
		valueFrom: fieldRef: fieldPath: "metadata.labels['app']"
	},
	{
		name: "VERSION_VALUE"
		valueFrom: fieldRef: fieldPath: "metadata.labels['version']"
	},
]

#GenericEnvs: {
	#config: #Config
	let app = #config."hyperswitch-app"
	env: [
		{
			name:  "ROUTER__SERVER__HOST"
			value: "0.0.0.0"
		},
		{
			name:  "CONFIG_DIR"
			value: "/local/config"
		},
		{
			name:  "ROUTER__LOG__FILE__ENABLED"
			value: "false"
		},
		{
			name:  "ROUTER__LOG__CONSOLE__ENABLED"
			value: "true"
		},
		{
			name:  "ROUTER__EMAIL__ALLOWED_UNVERIFIED_DAYS"
			value: "\((app.server.configs.email.allowed_unverified_days | *7))"
		},
		{
			name:  "ROUTER__EMAIL__ACTIVE_EMAIL_CLIENT"
			value: app.server.email.active_email_client
		},
		{
			name:  "ROUTER__EMAIL__SMTP__HOST"
			value: "mailhog"
		},
		{
			name:  "ROUTER__EMAIL__SMTP__PORT"
			value: "1025"
		},
		{
			name:  "ROUTER__EMAIL__SMTP__USERNAME"
			value: "hyperswitch"
		},
		{
			name:  "ROUTER__EMAIL__SMTP__PASSWORD"
			value: "hyperswitch"
		},
		{
			name:  "ROUTER__EMAIL__SMTP__FROM_NAME"
			value: "Hyperswitch"
		},
		{
			name:  "ROUTER__EMAIL__SMTP__FROM_EMAIL"
			value: "admin@hyperswitch.local"
		},
		{
			name: "RUN_ENV"
			if app.server.run_env == "production" {
				value: "production"
			}
			if app.server.run_env != "production" {
				value: "sandbox"
			}
		},
	]
}

#PostgresqlSecretsEnvs: {
	#config: #Config
	_app: #config."hyperswitch-app"

	_secretName: string
	if _app.postgresql.enabled {
		_secretName: #config.metadata.name + "-postgresql"
	}
	if !_app.postgresql.enabled {
		_secretName: "ext-postgresql-" + #config.metadata.name
	}

	_masterKey: string
	if _app.postgresql.enabled {
		_masterKey: "password"
	}
	if !_app.postgresql.enabled {
		_masterKey: "primaryPassword"
	}

	_replicaKey: string
	if _app.postgresql.enabled {
		_replicaKey: "password"
	}
	if !_app.postgresql.enabled {
		_replicaKey: "readOnlyPassword"
	}

	env: [
		{
			name: "ROUTER__MASTER_DATABASE__PASSWORD"
			valueFrom: secretKeyRef: {
				name: _secretName
				key:  _masterKey
			}
		},
		{
			name: "ROUTER__REPLICA_DATABASE__PASSWORD"
			valueFrom: secretKeyRef: {
				name: _secretName
				key:  _replicaKey
			}
		},
	]
}

// Replaces templates/_init-container.tpl

#PostgresqlInitContainer: {
	#config: #Config
	_app: #config."hyperswitch-app"

	pgHost: string
	pgUser: string
	pgDB:   string

	if _app.postgresql.enabled {
		_pg: _app.postgresql
		pgHost: [if _pg.fullnameOverride != "" {_pg.fullnameOverride}, #config.metadata.name + "-postgresql"][0]
		pgUser: _pg.global.postgresql.auth.username
		pgDB:   _pg.global.postgresql.auth.database
	}
	if !_app.postgresql.enabled {
		pgHost: _app.externalPostgresql.primary.host
		pgUser: _app.externalPostgresql.primary.auth.username
		pgDB:   _app.externalPostgresql.primary.database
	}

	_registry: string
	if #config.global.imageRegistry == "" {
		_registry: (_app.initDB.checkPGisUp.imageRegistry | *"docker.io")
	}
	if #config.global.imageRegistry != "" {
		_registry: #config.global.imageRegistry
	}

	container: corev1.#Container & {
		name:            "check-postgres"
		image:           "\(_registry)/\((_app.initDB.checkPGisUp.image | *"postgres:15-alpine"))"
		imagePullPolicy: "IfNotPresent"
		command: ["/bin/sh", "-c"]
		args: [
			"""
			MAX_ATTEMPTS=\((_app.initDB.checkPGisUp.maxAttempt | *30));
			SLEEP_SECONDS=5;
			attempt=0;
			while ! pg_isready -U \(pgUser) -d \(pgDB) -h \(pgHost) -p 5432; do
			  if [ $attempt -ge $MAX_ATTEMPTS ]; then
			    echo "PostgreSQL did not become ready in time";
			    exit 1;
			  fi;
			  attempt=$((attempt+1));
			  echo "Waiting for PostgreSQL to be ready... Attempt: $attempt";
			  sleep $SLEEP_SECONDS;
			done;
			echo "PostgreSQL is ready.";
			""",
		]
	}
}

#RedisInitContainer: {
	#config: #Config
	_app: #config."hyperswitch-app"

	redisHost: string
	if _app.redis.enabled {
		redisHost: #config.metadata.name + "-redis-master"
	}
	if !_app.redis.enabled {
		redisHost: _app.externalRedis.host
	}

	_registry: string
	if #config.global.imageRegistry == "" {
		_registry: (_app.redisMiscConfig.checkRedisIsUp.initContainer.imageRegistry | *"docker.io")
	}
	if #config.global.imageRegistry != "" {
		_registry: #config.global.imageRegistry
	}

	container: corev1.#Container & {
		name:            "check-redis"
		image:           "\(_registry)/\((_app.redisMiscConfig.checkRedisIsUp.initContainer.image | *"redis:7-alpine"))"
		imagePullPolicy: "IfNotPresent"
		command: ["/bin/sh", "-c"]
		args: [
			"""
			MAX_ATTEMPTS=\((_app.redisMiscConfig.checkRedisIsUp.initContainer.maxAttempt | *30));
			SLEEP_SECONDS=5;
			attempt=0;
			while ! redis-cli -h \(redisHost) -p 6379 ping; do
			  if [ $attempt -ge $MAX_ATTEMPTS ]; then
			    echo "Redis did not become ready in time";
			    exit 1;
			  fi;
			  attempt=$((attempt+1));
			  echo "Waiting for Redis to be ready... Attempt: $attempt";
			  sleep $SLEEP_SECONDS;
			done;
			echo "Redis is ready.";
			""",
		]
	}
}
