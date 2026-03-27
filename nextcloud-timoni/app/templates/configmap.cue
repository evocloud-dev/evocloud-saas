package templates

import (
	corev1 "k8s.io/api/core/v1"
)

// #ConfigMap emits the nextcloud-config ConfigMap.
// This is the Timoni equivalent of Helm's config.yaml.
//
// Helm:
//   data:
//     {{- range $filename, $content := .Values.nextcloud.configs }}
//     {{ $filename }}: |- {{ $content }}
//     {{- end }}
//     {{- range $filename, $enabled := .Values.nextcloud.defaultConfigs }}
//     {{- if $enabled }}
//     {{ $filename }}: |-
//       {{- tpl ($.Files.Get (printf "files/defaultConfigs/%s.tpl" $filename)) $ }}
//     {{- end }}
//     {{- end }}
//
// Timoni: user configs come directly from #in.nextcloud.configs.
// Built-in default config content is sourced from configmap-defaults.cue.
#ConfigMap: corev1.#ConfigMap & {
	#in:    #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#in.metadata.name)-config"
		namespace: #in.metadata.namespace
		labels:    #in.metadata.labels
		if #in.metadata.annotations != _|_ {
			annotations: #in.metadata.annotations
		}
	}
	data: {
		// User-supplied PHP config files
		for filename, content in #in.nextcloud.configs {
			"\(filename)": content
		}
		// Built-in default PHP config files — content sourced from configmap-defaults.cue
		for filename, enabled in #in.nextcloud.defaultConfigs if enabled {
			"\(filename)": _defaultConfigs[filename]
		}
	}
}