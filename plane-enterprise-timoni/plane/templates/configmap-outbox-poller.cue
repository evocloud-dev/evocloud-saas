package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#OutboxPollerConfigMap: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-outbox-poller-vars"
	}
	data: {
		OUTBOX_POLLER_MEMORY_LIMIT_MB:        *"400" | string
		OUTBOX_POLLER_INTERVAL_MIN:           *"0.25" | string
		OUTBOX_POLLER_INTERVAL_MAX:           *"2" | string
		OUTBOX_POLLER_BATCH_SIZE:             *"250" | string
		OUTBOX_POLLER_MEMORY_CHECK_INTERVAL:  *"30" | string
		OUTBOX_POLLER_POOL_SIZE:              *"4" | string
		OUTBOX_POLLER_POOL_MIN_SIZE:          *"2" | string
		OUTBOX_POLLER_POOL_MAX_SIZE:          *"10" | string
		OUTBOX_POLLER_POOL_TIMEOUT:           *"30.0" | string
		OUTBOX_POLLER_POOL_MAX_IDLE:          *"300.0" | string
		OUTBOX_POLLER_POOL_MAX_LIFETIME:      *"3600" | string
		OUTBOX_POLLER_POOL_RECONNECT_TIMEOUT: *"5.0" | string
		OUTBOX_POLLER_POOL_HEALTH_CHECK_INTERVAL: *"60" | string
	}
}
