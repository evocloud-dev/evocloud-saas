package templates


#StatsD: {
	#config: #Config

	// Helper to check if the statsd exporter is enabled and no address is provided
	// (matching Helm logic: and .Values.mastodon.metrics.statsd.exporter.enabled (not .Values.mastodon.metrics.statsd.address))
	#enabled: #config.mastodon.metrics.statsd.exporter.enabled && #config.mastodon.metrics.statsd.address == ""

	// Definition for the sidecar container (matching mastodon.statsdExporterContainer helper in _statsd.yaml)
	#container: {
		if #enabled {
			[
				{
					name:  "statsd-exporter"
					image: "prom/statsd-exporter"
					args: ["--statsd.mapping-config=/statsd-mappings/mastodon.yml"]
					resources: {
						requests: {
							cpu:    "0.1"
							memory: "180M"
						}
						limits: {
							cpu:    "0.5"
							memory: "250M"
						}
					}
					ports: [{
						name:          "statsd"
						containerPort: #config.mastodon.metrics.statsd.exporter.port
					}]
					volumeMounts: [{
						name:      "statsd-mappings"
						mountPath: "/statsd-mappings"
					}]
				},
			]
		}
		if !#enabled {
			[]
		}
	}

	// Definition for the volume (matching mastodon.statsdExporterVolume helper in _statsd.yaml)
	#volume: {
		if #enabled {
			[
				{
					name: "statsd-mappings"
					configMap: {
						name: "\(#config.metadata.name)-statsd-mappings"
						items: [{
							key:  "mastodon-statsd-mappings.yml"
							path: "mastodon.yml"
						}]
					}
				},
			]
		}
		if !#enabled {
			[]
		}
	}

	// Labels (matching mastodon.statsdExporterLabels helper in _statsd.yaml)
	#labels: {
		if #enabled {
			"mastodon/statsd-exporter": "true"
		}
	}
}
