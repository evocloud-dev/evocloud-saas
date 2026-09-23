// SPDX-License-Identifier: Apache-2.0

@extern(embed)

package templates

import (
	"encoding/json"
	"text/template"
	corev1 "k8s.io/api/core/v1"
)

// Embed templates/nginx.conf at the file level
_nginxConfTpl: _ @embed(file=nginx.conf, type=text)

// #ConfigMap mirrors templates/configmap.yaml
#ConfigMap: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata:   #config.metadata
	data: {
		"config.json": json.Marshal(#config.config)
		"nginx.conf":  template.Execute(_nginxConfTpl, {Values: #config})
	}
}
