package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ConfigSecret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config._configSecretName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "netbox"
		}
		if #config.commonAnnotations != _|_ {
			annotations: #config.commonAnnotations
		}
	}
	type: "Opaque"
	stringData: {
		if #config.email.existingSecretName == "" {
			email_password: #config.email.password
		}
		secret_key: {
			if #config.secretKey != "" { #config.secretKey }
			if #config.secretKey == "" { "placeholder-secret-key-that-is-at-least-fifty-characters-long-for-migration" }
		}
		if [ for b in #config.remoteAuth.backends if b == "netbox.authentication.LDAPBackend" {b}] != [] {
			ldap_bind_password: #config.remoteAuth.ldap.bindPassword
		}
	}
}

#SuperuserSecret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config._superuserSecretName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "netbox"
		}
		if #config.commonAnnotations != _|_ {
			annotations: #config.commonAnnotations
		}
	}
	type: "kubernetes.io/basic-auth"
	stringData: {
		username:  #config.superuser.name
		password:  #config.superuser.password
		email:     #config.superuser.email
		api_token: #config.superuser.apiToken
	}
}

#PostgresqlSecret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config._fullname)-postgresql"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "netbox"
		}
		if #config.commonAnnotations != _|_ {
			annotations: #config.commonAnnotations
		}
	}
	type: "Opaque"
	stringData: {
		"postgres-password": #config.externalDatabase.password
	}
}

#ValkeySecret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config._fullname)-valkey"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "netbox"
		}
		if #config.commonAnnotations != _|_ {
			annotations: #config.commonAnnotations
		}
	}
	type: "Opaque"
	stringData: {
		if #config.tasksDatabase.existingSecretName == "" {
			"tasks-password": #config.tasksDatabase.password
		}
		if #config.cachingDatabase.existingSecretName == "" {
			"cache-password": #config.cachingDatabase.password
		}
	}
}
