package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#DotenvSecret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-dotenv"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	type: "Opaque"
	stringData: {
		DATABASE_URL:                          "mysql://\(#config.pimcore.db.username):\(#config.pimcore.db.password)@\(#config.pimcore.db.host):\(#config.pimcore.db.port)/\(#config.pimcore.db.name)"
		DB_ROOT_PASSWORD:                      "#config.pimcore.db.root_password"
		DB_HOST:                               #config.pimcore.db.host
		DB_USER:                               #config.pimcore.db.username
		DB_PASSWORD:                           #config.pimcore.db.password
		DB_DATABASE:                           #config.pimcore.db.name
		DB_PORT:                               "\(#config.pimcore.db.port)"
		PIMCORE_DB_HOST:                       #config.pimcore.db.host
		PIMCORE_DB_PORT:                       "\(#config.pimcore.db.port)"
		PIMCORE_DB_NAME:                       #config.pimcore.db.name
		PIMCORE_DB_USER:                       #config.pimcore.db.username
		PIMCORE_DB_PASSWORD:                   #config.pimcore.db.password
		PIMCORE_DATABASE_HOST:                 #config.pimcore.db.host
		PIMCORE_DATABASE_PORT:                 "\(#config.pimcore.db.port)"
		PIMCORE_DATABASE_NAME:                 #config.pimcore.db.name
		PIMCORE_DATABASE_USER:                 #config.pimcore.db.username
		PIMCORE_DATABASE_PASSWORD:             #config.pimcore.db.password
		PIMCORE_TEST_DB_DSN:                   "mysql://\(#config.pimcore.db.username):\(#config.pimcore.db.password)@\(#config.pimcore.db.host):\(#config.pimcore.db.port)/\(#config.pimcore.db.name)"
		APP_ENV:                               #config.pimcore.appEnv
		APP_SECRET:                            #config.pimcore.appSecret
		OPENSEARCH_URL:                        "http://\(#config.metadata.name)-opensearch:9200"
		OPENSEARCH_HOST:                       "\(#config.metadata.name)-opensearch"
		OPENSEARCH_PORT:                       "9200"
		OPENSEARCH_SCHEME:                     "http"
		OPENSEARCH_PROTOCOL:                   "http"
		OPENSEARCH_SSL_VERIFY:                 "false"
		OPENSEARCH_REJECT_UNAUTHORIZED:        "0"
		OPENSEARCH_VERIFY_SSL:                 "false"
		OPENSEARCH_DSN:                        "opensearch://\(#config.metadata.name)-opensearch:9200?scheme=http&ssl=false"
		PIMCORE_OPENSEARCH_HOST:               "\(#config.metadata.name)-opensearch"
		PIMCORE_OPENSEARCH_PORT:               "9200"
		PIMCORE_OPENSEARCH_SCHEME:             "http"
		PIMCORE_OPENSEARCH_PROTOCOL:           "http"
		PIMCORE_OPENSEARCH_SSL:                "false"
		PIMCORE_OPENSEARCH_SSL_VERIFY:         "false"
		PIMCORE_OPENSEARCH_VERIFY_SSL:         "false"
		PIMCORE_OPENSEARCH_DSN:                "opensearch://\(#config.metadata.name)-opensearch:9200?scheme=http&ssl=false"
		PIMCORE_MESSENGER_AMQP_HOST:           "\(#config.metadata.name)-rabbitmq"
		PIMCORE_MESSENGER_AMQP_PORT:           "5672"
		PIMCORE_MESSENGER_AMQP_USER:           #config.rabbitmq.username
		PIMCORE_MESSENGER_AMQP_PASSWORD:       #config.rabbitmq.password
		PIMCORE_MESSENGER_AMQP_VHOST:          "/"
		MESSENGER_TRANSPORT_DSN:               "amqp://\(#config.rabbitmq.username):\(#config.rabbitmq.password)@\(#config.metadata.name)-rabbitmq:5672/%2f"
		PIMCORE_MESSENGER_TRANSPORT_DSN:       "amqp://\(#config.rabbitmq.username):\(#config.rabbitmq.password)@\(#config.metadata.name)-rabbitmq:5672/%2f"
		PIMCORE_PRODUCT_KEY:                   #config.pimcore.productKey
		PIMCORE_INSTANCE_IDENTIFIER:           #config.pimcore.instanceIdentifier
		PIMCORE_ENCRYPTION_SECRET:             #config.pimcore.encryptionSecret
		PIMCORE_ADMIN_USER:                    #config.pimcore.username
		PIMCORE_ADMIN_PASSWORD:                #config.pimcore.password
		REDIS_SERVER:                          #config.pimcore.redisServer
		REDIS_PASSWORD:                        #config.pimcore.redisPassword
		REDIS_DSN:                             "redis://\(#config.pimcore.redisPassword)@\(#config.pimcore.redisServer)"

		if #config.s3.enabled {
			S3_STORAGE_KEY:    #config.s3.key
			S3_STORAGE_SECRET: #config.s3.secret
			S3_PUBLIC_BUCKET:  #config.s3.publicBucket
			S3_PRIVATE_BUCKET: #config.s3.privateBucket
		}

		for e in #config.pimcore.customEnvVars {
			if e.value != _|_ && e.value != "" {
				"\(e.name)": e.value
			}
		}
	}
}
