package templates

import (
	"strings"
	corev1 "k8s.io/api/core/v1"
)

#ConfigMap: corev1.#ConfigMap & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\( #config.fullname )-config"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "sonarqube"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}

	let _properties = [
		if #config.sonarqube.context != "" {
			"sonar.web.context=\(#config.sonarqube.context)"
		},
		if #config.communityBranchPlugin.enabled {
			"sonar.web.javaAdditionalOpts=-javaagent:/opt/sonarqube/extensions/plugins/\(#config.communityBranchJarName)=web\nsonar.ce.javaAdditionalOpts=-javaagent:/opt/sonarqube/extensions/plugins/\(#config.communityBranchJarName)=ce"
		},
		for k, v in #config.sonarqube.sonarProperties {
			"\(k)=\(v)"
		},
	]

	data: {
		"sonar.properties": strings.Join(_properties, "\n") + "\n"
	}
}
