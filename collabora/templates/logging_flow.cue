package templates

#LoggingFlow: {
	#config: #Config
	apiVersion: "logging.banzaicloud.io/v1beta1"
	kind:       "Flow"
	metadata: {
		name:      "\(#config.metadata.name)"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
	spec: {
		match: [
			{
				select: {
					labels: #config.selector.labels
					container_names: [
						#config.metadata.name,
					]
				}
			},
		]
		filters: [
			{
				parser: {
					hash_value_field:      "collabora"
					remove_key_name_field: true
					reserve_data:          true
					parse: {
						type: "multi_format"
						patterns: [
							{
								format:      "regexp"
								expression:  #"^(?<process>\w+)-(?<pid>\d+)-(?<thread>\d+)\s+(?<time>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}.\d+ \+\d{4})\s+\[\s+(?<compenent>\w+)\s+\]\s+(?<level>\w+)\s+(?<message>.*(session (to|on) \[?(?<wopidoc>[^\s\]]*)\]?.*)No acceptable WOPI hosts found matching the target host \[(?<wopihost>.+)\] in config.)\|\s(?<code>[^:]+):(?<codeline>[0-9]+)"#
								types:       "pid:integer,thread:integer,codeline:integer"
								time_key:    "time"
								time_type:   "string"
								time_format: "%Y-%m-%d %H:%M:%S.%N %z"
							},
							{
								format:      "regexp"
								expression:  #"^(?<process>\w+)-(?<pid>\d+)-(?<thread>\d+)\s+(?<time>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}.\d+ \+\d{4})\s+\[\s+(?<compenent>\w+)\s+\]\s+(?<level>\w+)\s+(?<message>.*No acceptable WOPI hosts found matching the target host \[(?<wopihost>.+)\] in config.)\|\s(?<code>[^:]+):(?<codeline>[0-9]+)"#
								types:       "pid:integer,thread:integer,codeline:integer"
								time_key:    "time"
								time_type:   "string"
								time_format: "%Y-%m-%d %H:%M:%S.%N %z"
							},
							{
								format:     "none"
							},
						]
					}
				}
			},
			if #config.logging.additionalFilters != _|_ {
				for f in #config.logging.additionalFilters {f}
			},
		]
		if #config.logging.globalOutputRefs != _|_ {
			globalOutputRefs: #config.logging.globalOutputRefs
		}
		if #config.logging.localOutputRefs != _|_ {
			localOutputRefs: #config.logging.localOutputRefs
		}
	}
}

