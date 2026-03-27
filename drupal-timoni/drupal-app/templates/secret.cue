package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#DrupalSecret: corev1.#Secret & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		username: #config.drupal.username
		if #config.drupal.password != "" {
			password: #config.drupal.password
		}
		if #config.external.enabled {
			databasePassword: #config.external.password
		}
	}
}

#SSMTPSecret: corev1.#Secret & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-ssmtp"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		"ssmtp.conf": #config.drupal.conf.ssmtp_conf
	}
}

#ProxySQLSecret: corev1.#Secret & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-proxysql"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		"proxysql.conf": #config.drupal.conf.proxysql_conf
	}
}

#PgBouncerSecret: corev1.#Secret & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-pgbouncer"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		"pgbouncer.ini": #config.drupal.conf.pgbouncer_ini
		"userlist.txt":  #config.drupal.conf.userlist_txt
		"password":      #config.pgbouncer.password
	}
}
