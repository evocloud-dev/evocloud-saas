package templates

import (
	"strings"

	corev1 "k8s.io/api/core/v1"
)

#ConfigMap: corev1.#ConfigMap & {
	#config: #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/instance": #config.metadata.name
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	data: {
		if (#config.collabora.extra_params & string) != _|_ {
			extra_params: #config.collabora.extra_params
		}
		if (#config.collabora.extra_params & [...string]) != _|_ {
			extra_params: strings.Join(#config.collabora.extra_params, " ")
		}
		if #config.collabora.server_name != _|_ && #config.collabora.server_name != "" {
			server_name: #config.collabora.server_name
		}
		if #config.collabora.aliasgroups != _|_ {
			for k, v in #config.collabora.aliasgroups {
				if v.aliases != _|_ {
					"aliasgroup\(k + 1)": "\(v.host),\(strings.Join(v.aliases, ","))"
				}
				if v.aliases == _|_ {
					"aliasgroup\(k + 1)": v.host
				}
			}
		}
		if #config.collabora.aliasgroup1 != _|_ {
			if (#config.collabora.aliasgroup1 & string) != _|_ {
				aliasgroup1: #config.collabora.aliasgroup1
			}
			if (#config.collabora.aliasgroup1 & [...string]) != _|_ {
				aliasgroup1: strings.Join(#config.collabora.aliasgroup1, ",")
			}
		}
		if #config.collabora.dictionaries != _|_ {
			dictionaries: strings.Join(#config.collabora.dictionaries, " ")
		}
		if #config.collabora.no_gen_ssl != _|_ {
			DONT_GEN_SSL_CERT: "\(#config.collabora.no_gen_ssl)"
		}
		if #config.collabora.coolkitconfig_xcu_content != _|_ {
			"coolkitconfig.xcu": #config.collabora.coolkitconfig_xcu_content
		}
		if #config.collabora.coolwsd_xml_content != _|_ {
			"coolwsd.xml": #config.collabora.coolwsd_xml_content
		}
	}
}
