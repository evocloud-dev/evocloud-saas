package templates

#PDBMysql: {
	#config: #Config

	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      "mysql-mariadb-pdb"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: {
		minAvailable: 1
		selector: matchLabels: {
			"app.kubernetes.io/name":      "mariadb"
			"app.kubernetes.io/instance":  "mysql"
			"app.kubernetes.io/component": "primary"
		}
	}
}
