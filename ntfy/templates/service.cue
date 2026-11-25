package templates

import (
	"strconv"
	"strings"

	corev1 "k8s.io/api/core/v1"
)

// #Service mirrors templates/service.yaml.
#Service: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if len(#config.commonAnnotations) > 0 || len(#config.service.annotations) > 0 {
			annotations: {
				for k, v in #config.commonAnnotations if #config.service.annotations[k] == _|_ {(k): v}
				#config.service.annotations
			}
		}
	}
	spec: corev1.#ServiceSpec & {
		type: #config.service.type
		if #config.service.ipFamilyPolicy != null && #config.service.ipFamilyPolicy != "" {
			ipFamilyPolicy: #config.service.ipFamilyPolicy
		}
		if len(#config.service.ipFamilies) > 0 {
			ipFamilies: #config.service.ipFamilies
		}
		ports: [
			{
				name:       "http"
				port:       #config.service.port
				targetPort: "http"
				protocol:   "TCP"
			},
			if #config.ntfy.enableMetrics && #config.ntfy.metricsListenHttp != "" {
				let _parts = strings.Split(#config.ntfy.metricsListenHttp, ":")
				{
					name:       "metrics"
					port:       strconv.Atoi(_parts[len(_parts)-1])
					targetPort: "metrics"
					protocol:   "TCP"
				}
			},
		]
		selector: #config.selector.labels & {
			"app.kubernetes.io/component": "server"
		}
	}
}
