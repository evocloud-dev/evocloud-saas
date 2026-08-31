package templates

#UploadsPVCBuilder: {
	_config: #Config

	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      _config.uploadsPvcName
		namespace: _config.namespace
		labels:    _config.metadata.labels & _config.commonLabels
	}
	spec: {
		accessModes: _config.server.persistence.accessModes
		if _config.server.persistence.storageClass != "" {
			storageClassName: _config.server.persistence.storageClass
		}
		resources: requests: storage: _config.server.persistence.size
	}
}

#MLCachePVCBuilder: {
	_config: #Config

	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      _config.mlCachePvcName
		namespace: _config.namespace
		labels:    _config.metadata.labels & _config.commonLabels
	}
	spec: {
		accessModes: _config.machineLearning.persistence.accessModes
		if _config.machineLearning.persistence.storageClass != "" {
			storageClassName: _config.machineLearning.persistence.storageClass
		}
		resources: requests: storage: _config.machineLearning.persistence.size
	}
}
