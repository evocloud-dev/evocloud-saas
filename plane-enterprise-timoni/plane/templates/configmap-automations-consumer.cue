package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#AutomationConsumerConfigMap: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-automation-consumer-vars"
	}
	data: {
		AUTOMATION_EVENT_STREAM_QUEUE_NAME: *"plane.event_stream.automations" | string
		AUTOMATION_EVENT_STREAM_PREFETCH:   *"10" | string
		AUTOMATION_EXCHANGE_NAME:           *"plane.event_stream" | string
		AUTOMATION_EVENT_TYPES:             *"issue" | string
	}
}
