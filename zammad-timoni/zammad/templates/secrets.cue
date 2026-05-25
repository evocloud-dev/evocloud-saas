package templates

import (
	"encoding/base64"
)

#SecretAutowizard: {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config._autowizardSecretName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	type: "Opaque"
	data: {
		"\(#config.secrets.autowizard.secretKey)": base64.Encode(null, #config.autoWizard.config)
	}
}

#SecretElasticsearch: {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config._elasticsearchSecretName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	type: "Opaque"
	data: {
		"\(#config.secrets.elasticsearch.secretKey)": base64.Encode(null, #config.zammadConfig.elasticsearch.pass)
	}
}

#SecretPostgresql: {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config._postgresqlSecretName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	type: "Opaque"
	data: {
		"\(#config.secrets.postgresql.secretKey)": base64.Encode(null, #config.zammadConfig.postgresql.pass)
		"password":                              base64.Encode(null, #config.zammadConfig.postgresql.pass)
		"postgres-password":                     base64.Encode(null, #config.zammadConfig.postgresql.pass)
	}
}

#SecretRedis: {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config._redisSecretName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	type: "Opaque"
	data: {
		"\(#config.secrets.redis.secretKey)": base64.Encode(null, #config.zammadConfig.redis.pass)
		"redis-password":                     base64.Encode(null, #config.zammadConfig.redis.pass)
	}
}

#SecretRedisSentinel: {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config._redisSentinelSecretName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	type: "Opaque"
	data: {
		"\(#config.secrets.redis.sentinel.secretKey)": base64.Encode(null, #config.zammadConfig.redis.sentinel.pass)
	}
}
