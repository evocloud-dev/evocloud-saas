package templates

import (
	"encoding/yaml"
	"strings"
	corev1 "k8s.io/api/core/v1"
)

#RunnerConfigMap: corev1.#ConfigMap & {
	#config:    #Config
	#group:     _
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name: *"\((#config.metadata.name))-runner-\(#group.id)-config" | string
		if #group.config.configMapName != _|_ && #group.config.configMapName != null {
			name: #group.config.configMapName
		}
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "runner"
			"peertube.runner/group":       #group.id
		}
		if #group.config.configMapAnnotations != _|_ {
			annotations: #group.config.configMapAnnotations
		}
	}

	#parsed: yaml.Unmarshal(#group.config.raw)
	#base: {
		for k, v in #parsed
		if k != "registeredInstances" {
			"\(k)": v
		}
	}

	#tomlString: strings.Join([
		for section, fields in #base {
			let lines = [
				for key, val in fields {
					if (val & string) != _|_ {
						"\(key) = \"\(val)\""
					}
					if (val & int) != _|_ || (val & bool) != _|_ {
						"\(key) = \(val)"
					}
				}
			]
			"[\(section)]\n" + strings.Join(lines, "\n") + "\n"
		}
	], "\n")

	data: {
		"config.toml": #tomlString
	}
}
