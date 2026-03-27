package templates

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
	"strings"
)

#VarnishConfigMap: corev1.#ConfigMap & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "varnish"
	}
	data: {
		if #config.varnish.varnishConfigContent != _|_ {
			// Replace BACKEND_HOST placeholder with the actual service name
			"default.vcl": strings.Replace(
				#config.varnish.varnishConfigContent,
				"BACKEND_HOST",
				"\(#config.metadata.name)-nginx",
				-1,
			)
		}
		if #config.varnish.varnishConfigContent == _|_ {
			"default.vcl": "vcl 4.0;\nbackend placeholder {\n  .host = \"localhost\";\n  .port = \"80\";\n}\nsub vcl_recv {\n  return (synth(700, \"Service Unavailable\"));\n}\nsub vcl_synth {\n  set resp.status = 503;\n  return (deliver);\n}\n"
		}
	}
}
