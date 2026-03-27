package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#MariaDBService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-mariadb-sts"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#ServiceSpec & {
		type:      "ClusterIP"
		clusterIP: "None"
		ports: [
			{
				port:       3306
				targetPort: "mysql"
				protocol:   "TCP"
				name:       "mysql"
			},
		]
		selector: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-mariadb-sts"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
}

#MariaDBConfigMap: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-mariadb-sts"
		namespace: #config.metadata.namespace
	}
	data: {
		if #config["mariadb-sts"].myCnf != _|_ {
			"my.cnf": #config["mariadb-sts"].myCnf
		}
	}
}
