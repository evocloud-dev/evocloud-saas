package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#Secret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: corev1.#SecretTypeOpaque
	stringData: {
		"humhub-admin-password": #config.humhub.admin.password
		"humhub-admin-email":    #config.humhub.admin.email
		"humhub-admin-login":    #config.humhub.admin.login

		"mariadb-password": #config.mariadb.password
		"mariadb-user":     #config.mariadb.mariadbUsername
		"mariadb-database": #config.mariadb.mariadbDatabase

		"redis-password": #config.redis.password

		"mailer-user":     #config.humhub.mailer.user
		"mailer-password": #config.humhub.mailer.password
	}
}

#MariaDBCredsSecret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config.mariadb.credsSecretName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: corev1.#SecretTypeOpaque
	stringData: {
		"jdbc":                  #config.mariadb.jdbc
		"jdbc-mariadb":          #config.mariadb.jdbcMariadb
		"jdbc-mysql":            #config.mariadb.jdbcMysql
		"mariadb-password":      #config.mariadb.password
		"mariadb-root-password": #config.mariadb.rootPassword
		"plainhost":             #config.mariadb.host
		"plainporthost":         #config.mariadb.plainporthost
		"url":                   #config.mariadb.url
		"urlnossl":              #config.mariadb.urlnossl
	}
}

#RedisCredsSecret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config.redis.credsSecretName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: corev1.#SecretTypeOpaque
	stringData: {
		"plain":          #config.redis.host
		"plainhost":      #config.redis.host
		"plainhostpass":  #config.redis.plainhostpass
		"plainporthost":  #config.redis.plainporthost
		"redis-password": #config.redis.password
		"url":            #config.redis.url
	}
}
