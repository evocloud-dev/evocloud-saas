package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#Secret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata:   #config.metadata
	stringData: {
		if #config.config.externalSecrets == "" {
			if #config.mysql.enabled {
				MYSQL_USER:               #config.mysql.mysqlUser
				MYSQL_DATABASE:           #config.mysql.mysqlDatabase
				MYSQL_PASSWORD:           #config.mysql.mysqlPassword
				MYSQL_PORT_3306_TCP_ADDR: "\(#config.metadata.name)-mysql"
				MYSQL_PORT_3306_TCP_PORT: "3306"
				APP_KEY:                  #config.config.snipeit.key
			}
			if !#config.mysql.enabled {
				MYSQL_USER:               #config.config.mysql.externalDatabase.user
				MYSQL_DATABASE:           #config.config.mysql.externalDatabase.name
				MYSQL_PASSWORD:           #config.config.mysql.externalDatabase.pass
				MYSQL_PORT_3306_TCP_ADDR: #config.config.mysql.externalDatabase.host
				MYSQL_PORT_3306_TCP_PORT: "\(#config.config.mysql.externalDatabase.port)"
				APP_KEY:                  #config.config.snipeit.key
			}
		}
		for k, v in #config.config.snipeit.envConfig {
			"\(k)": v
		}
	}
}
