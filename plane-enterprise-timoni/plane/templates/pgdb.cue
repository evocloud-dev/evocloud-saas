package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#PostgresSecret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-pgdb-secrets"
	}
	type: "Opaque"
	stringData: {
		POSTGRES_USER:     #config.env.pgdb_username
		POSTGRES_PASSWORD: #config.env.pgdb_password
		POSTGRES_DB:       #config.env.pgdb_name
	}
}

#PostgresConfigMap: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-pgdb-vars"
	}
	data: {
		POSTGRES_USER: #config.env.pgdb_username
		"init-dbs.sql": """
			CREATE EXTENSION IF NOT EXISTS dblink;
			
			SELECT 'CREATE DATABASE \"\(#config.env.pgdb_name)\"'
			WHERE NOT EXISTS (
			    SELECT FROM pg_database WHERE datname = '\(#config.env.pgdb_name)'
			)\\gexec
			
			SELECT 'CREATE DATABASE \"\(#config.env.pg_pi_db_name)\"'
			WHERE NOT EXISTS (
			    SELECT FROM pg_database WHERE datname = '\(#config.env.pg_pi_db_name)'
			)\\gexec
			
			"""
	}
}
