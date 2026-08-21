@extern(embed)

package templates

import (
	corev1 "k8s.io/api/core/v1"
	"text/template"
)

// The Nginx configuration templates embedded as text strings.
_invoiceninjaConf: string @embed(file="invoiceninja.conf", type=text)
_laravelConf:      string @embed(file="laravel.conf", type=text)

#ConfigMap: corev1.#ConfigMap & {
	#config: #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      #config.#configName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	data: {
		APP_URL:                  #config.env.appUrl
		APP_ENV:                  #config.env.appEnv
		APP_DEBUG:                #config.env.appDebug
		REQUIRE_HTTPS:            #config.env.requireHttps
		PHANTOMJS_PDF_GENERATION: #config.env.phantomjsPdfGeneration
		PDF_GENERATOR:            #config.env.pdfGenerator
		TRUSTED_PROXIES:          #config.env.trustedProxies
		CACHE_DRIVER:             #config.env.cacheDriver
		QUEUE_CONNECTION:         #config.env.queueConnection
		SESSION_DRIVER:           #config.env.sessionDriver
		REDIS_HOST:               #config.#redisServiceName
		REDIS_PORT:               #config.env.redisPort
		FILESYSTEM_DISK:          #config.env.filesystemDisk
		DB_HOST:                  #config.#mysqlServiceName
		DB_PORT:                  #config.env.dbPort
		DB_DATABASE:              #config.env.dbDatabase
		DB_USERNAME:              #config.env.dbUsername
		DB_CONNECTION:            #config.env.dbConnection
		MAIL_MAILER:              #config.env.mailMailer
		MAIL_HOST:                #config.env.mailHost
		MAIL_PORT:                #config.env.mailPort
		MAIL_USERNAME:            #config.env.mailUsername
		MAIL_PASSWORD:            #config.env.mailPassword
		MAIL_ENCRYPTION:          #config.env.mailEncryption
		MAIL_FROM_ADDRESS:         #config.env.mailFromAddress
		MAIL_FROM_NAME:            #config.env.mailFromName
		MYSQL_DATABASE:           #config.env.dbDatabase
		MYSQL_USER:               #config.env.dbUsername
		NORDIGEN_SECRET_ID:       #config.env.nordigenSecretId
		NORDIGEN_SECRET_KEY:      #config.env.nordigenSecretKey
		IS_DOCKER:                #config.env.isDocker
		SCOUT_DRIVER:             #config.env.scoutDriver
	}
}

#NginxConfigMap: corev1.#ConfigMap & {
	#config: #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      #config.#nginxServiceName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	data: {
		"invoiceninja.conf": _invoiceninjaConf
		"laravel.conf":      template.Execute(_laravelConf, {
			appServiceName:     #config.#appServiceName
			nginxContainerPort: #config.nginx.containerPort
		})
	}
}
