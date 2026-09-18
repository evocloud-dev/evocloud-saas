package templates

#PrometheusRule: {
	#config: #Config
	apiVersion: "monitoring.coreos.com/v1"
	kind:       "PrometheusRule"
	metadata: {
		name: #config.metadata.name
		if #config.prometheus.rules.namespace != _|_ {
			namespace: #config.prometheus.rules.namespace
		}
		if #config.prometheus.rules.namespace == _|_ {
			namespace: #config.metadata.namespace
		}
		labels: #config.metadata.labels & {
			"app.kubernetes.io/instance": #config.metadata.name
			if #config.prometheus.rules.additionalLabels != _|_ {
				#config.prometheus.rules.additionalLabels
			}
		}
	}
	spec: {
		groups: [
			if #config.prometheus.rules.defaults.enabled {
				name: "\(#config.metadata.name)-Defaults"
				rules: [
					{
						alert: "Collabora NoProcess"
						expr:  "coolwsd_count < 1"
						for:   "1m"
						labels: severity: "critical"
						annotations: summary: "no coolwsd process running: in namespace {{ $labels.namespace }} on pod {{ $labels.pod }}."
					},
					for k, v in #config.prometheus.rules.defaults.docs.pod {
						alert: "Collabora Open Docs by Pod"
						expr:  "kit_assigned_count > \(v)"
						for:   "1m"
						labels: severity: k
						annotations: summary: "too many docs (\(v)) are open in namespace {{ $labels.namespace }} on pod {{ $labels.pod }}."
					},
					for k, v in #config.prometheus.rules.defaults.docs.sum {
						alert: "Collabora Open Docs by Namespace"
						expr:  "sum(kit_assigned_count) without (instance, pod) > \(v)"
						for:   "1m"
						labels: severity: k
						annotations: summary: "too many docs (\(v)) are open in namespace {{ $labels.namespace }}."
					},
					for k, v in #config.prometheus.rules.defaults.viewers.pod {
						alert: "Collabora Viewers by Pod"
						expr:  "document_active_views_active_count_total > \(v)"
						for:   "1m"
						labels: severity: k
						annotations: summary: "too many viewers (\(v)) in namespace {{ $labels.namespace }} on pod {{ $labels.pod }}."
					},
					for k, v in #config.prometheus.rules.defaults.viewers.doc {
						alert: "Collabora Viewers by Document"
						expr:  "doc_views_active  * on(pid,namespace,job,service,pod,container,endpoint,instance) group_left(key,host,filename) doc_info > \(v)"
						for:   "1m"
						labels: severity: k
						annotations: summary: "too many viewers (\(v)) on document {{ $labels.key }} in namespace {{ $labels.namespace }}."
					},
					for k, v in #config.prometheus.rules.defaults.viewers.sum {
						alert: "Collabora Viewers by Namespace"
						expr:  "sum(document_active_views_active_count_total) without (instance, pod) > \(v)"
						for:   "1m"
						labels: severity: k
						annotations: summary: "too many viewers (\(v)) in namespace {{ $labels.namespace }}."
					},
					{
						alert: "Collabora DocumentsOpenSimultaneously"
						expr:  "count(count (doc_info) by (key, namespace) > 1) by (namespace) / count (doc_info) by (namespace) * 100 > \(#config.prometheus.rules.defaults.docs.duplicated)"
						labels: severity: "critical"
						annotations: summary: #"{{ printf "%.0f" $value }}% of all documents are opened simultaneously on different pods in namespace {{ $labels.namespace }}. Viewers can not see each others."#
					},
					{
						alert: "Collabora DocumentsOpenSimultaneously"
						expr:  "count(doc_info) by (key, namespace, host, filename) > 1"
						labels: severity: "warning"
						annotations: summary: "the document {{ $labels.key }} is opened simultaneously on different pods in namespace {{ $labels.namespace }}. Viewers can not see each others."
					},
					{
						alert: "Collabora Error StorageSpaceLow"
						expr:  "increase(error_storage_space_low[1m]) > 0"
						labels: severity: "warning"
						annotations: summary: "local storage space too low to operate in namespace {{ $labels.namespace }} on pod {{ $labels.pod }}."
					},
					for k, v in #config.prometheus.rules.defaults.errorStorageConnections {
						alert: "Collabora Error StorageConnection"
						expr:  "increase(error_storage_connection[1m]) > \(v)"
						labels: severity: k
						annotations: summary: "unable to connect to storage in namespace {{ $labels.namespace }} on pod {{ $labels.pod }}."
					},
					{
						alert: "Collabora Error BadRequest"
						expr:  "increase(error_bad_request[1m]) > 0"
						labels: severity: "warning"
						annotations: summary: "we returned an HTTP bad request to a caller in namespace {{ $labels.namespace }} on pod {{ $labels.pod }}."
					},
					{
						alert: "Collabora Error BadArgument"
						expr:  "increase(error_bad_argument[1m]) > 0"
						labels: severity: "warning"
						annotations: summary: "we returned an HTTP bad argument to a caller in namespace {{ $labels.namespace }} on pod {{ $labels.pod }}."
					},
					{
						alert: "Collabora Error UnauthorizedRequest"
						expr:  "increase(error_unauthorized_request[\(#config.prometheus.rules.defaults.errorUnauthorizedRequest.observationInterval)]) > \(#config.prometheus.rules.defaults.errorUnauthorizedRequest.eventCounter)"
						labels: severity: "warning"
						annotations: summary: "an authorization exception usually on CheckFileInfo in namespace {{ $labels.namespace }} on pod {{ $labels.pod }}."
					},
					for k, v in #config.prometheus.rules.defaults.errorServiceUnavailable {
						alert: "Collabora Error ServiceUnavailable"
						expr:  "increase(error_service_unavailable[30m]) > \(v)"
						labels: severity: k
						annotations: summary: "internal error, service is unavailable in namespace {{ $labels.namespace }} on pod {{ $labels.pod }}."
					},
					{
						alert: "Collabora Error ParseError"
						expr:  "increase(error_parse_error[1m]) > 0"
						labels: severity: "warning"
						annotations: summary: "badly formed data provided for us to parse in namespace {{ $labels.namespace }} on pod {{ $labels.pod }}."
					},
				]
			},
			if #config.prometheus.rules.additionalRules != _|_ && len(#config.prometheus.rules.additionalRules) > 0 {
				{
					name: "\(#config.metadata.name)-Additional"
					rules: #config.prometheus.rules.additionalRules
				}
			},
		]
	}
}
