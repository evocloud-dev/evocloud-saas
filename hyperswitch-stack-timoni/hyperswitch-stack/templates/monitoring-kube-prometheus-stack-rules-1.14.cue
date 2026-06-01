package templates

monitoringPrometheusRules: {
	#config: #Config
	let mon = #config."hyperswitch-monitoring"
	let kps = mon."kube-prometheus-stack"
	let fullname = (#KubePrometheusStackFullname & {#config: #config}).result
	let chartName = (#KubePrometheusStackName & {#config: #config}).result
	let amLabels = (#KubePrometheusStackLabels & {#config: #config}).result
	let amNamespace = [if kps.namespaceOverride != "" {kps.namespaceOverride}, #config.metadata.namespace][0]
	let promNamespace = amNamespace

	// alertmanager.rules.yaml
	if true && true && kps.defaultRules.create && kps.defaultRules.rules.alertmanager {
		let alertmanagerJob = "\(fullname)-alertmanager"
		"rule-alertmanager-rules": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "PrometheusRule"
			metadata: {
				name: (#KubePrometheusStackTruncatedName & {#name: "\(fullname)-alertmanager.rules"}).result
				namespace: promNamespace
				labels: amLabels & kps.defaultRules.labels & {
					app: chartName
				}
				if len(kps.defaultRules.annotations) > 0 {
					annotations: kps.defaultRules.annotations
				}
			}
			spec: groups: [
				{
					name: "alertmanager.rules"
					rules: [
						if !kps.defaultRules.disabled.AlertmanagerFailedReload {
							{
								alert: "AlertmanagerFailedReload"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.alertmanager != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.alertmanager
									}
								}
								expr: """
									# Without max_over_time, failed scrapes could create false negatives, see
									        # https://www.robustperception.io/alerting-on-gauges-in-prometheus-2-0 for details.
									        max_over_time(alertmanager_config_last_reload_successful{job="\(alertmanagerJob)",namespace="\(promNamespace)"}[5m]) == 0
									"""
								for:  kps.customRules.AlertmanagerFailedReload.for | *"10m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.alertmanager != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.alertmanager
									}
								}
							}
						},
						if !kps.defaultRules.disabled.AlertmanagerFailedReload {
							{
								alert: "AlertmanagerMembersInconsistent"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.alertmanager != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.alertmanager
									}
								}
								expr: """
									# Without max_over_time, failed scrapes could create false negatives, see
									        # https://www.robustperception.io/alerting-on-gauges-in-prometheus-2-0 for details.
									          max_over_time(alertmanager_cluster_members{job="\(alertmanagerJob)",namespace="\(promNamespace)"}[5m])
									        < on (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )namespace,service,cluster) group_left
									          count by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )namespace,service,cluster) (max_over_time(alertmanager_cluster_members{job="\(alertmanagerJob)",namespace="\(promNamespace)"}[5m]))
									"""
								for:  kps.customRules.AlertmanagerMembersInconsistent.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.alertmanager != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.alertmanager
									}
								}
							}
						},
						if !kps.defaultRules.disabled.AlertmanagerFailedReload {
							{
								alert: "AlertmanagerFailedToSendAlerts"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.alertmanager != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.alertmanager
									}
								}
								expr: """
									(
									          rate(alertmanager_notifications_failed_total{job="\(alertmanagerJob)",namespace="\(promNamespace)"}[5m])
									        /
									          ignoring (reason) group_left rate(alertmanager_notifications_total{job="\(alertmanagerJob)",namespace="\(promNamespace)"}[5m])
									        )
									        > 0.01
									"""
								for:  kps.customRules.AlertmanagerFailedToSendAlerts.for | *"5m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.alertmanager != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.alertmanager
									}
								}
							}
						},
						if !kps.defaultRules.disabled.AlertmanagerFailedReload {
							{
								alert: "AlertmanagerClusterFailedToSendAlerts"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.alertmanager != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.alertmanager
									}
								}
								expr: """
									min by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )namespace,service, integration) (
									          rate(alertmanager_notifications_failed_total{job="\(alertmanagerJob)",namespace="\(promNamespace)", integration=~`.*`}[5m])
									        /
									          ignoring (reason) group_left rate(alertmanager_notifications_total{job="\(alertmanagerJob)",namespace="\(promNamespace)", integration=~`.*`}[5m])
									        )
									        > 0.01
									"""
								for:  kps.customRules.AlertmanagerClusterFailedToSendAlerts.for | *"5m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.alertmanager != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.alertmanager
									}
								}
							}
						},
						if !kps.defaultRules.disabled.AlertmanagerFailedReload {
							{
								alert: "AlertmanagerClusterFailedToSendAlerts"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.alertmanager != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.alertmanager
									}
								}
								expr: """
									min by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )namespace,service, integration) (
									          rate(alertmanager_notifications_failed_total{job="\(alertmanagerJob)",namespace="\(promNamespace)", integration!~`.*`}[5m])
									        /
									          ignoring (reason) group_left rate(alertmanager_notifications_total{job="\(alertmanagerJob)",namespace="\(promNamespace)", integration!~`.*`}[5m])
									        )
									        > 0.01
									"""
								for:  kps.customRules.AlertmanagerClusterFailedToSendAlerts.for | *"5m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.alertmanager != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.alertmanager
									}
								}
							}
						},
						if !kps.defaultRules.disabled.AlertmanagerFailedReload {
							{
								alert: "AlertmanagerConfigInconsistent"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.alertmanager != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.alertmanager
									}
								}
								expr: """
									count by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )namespace,service,cluster) (
									          count_values by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )namespace,service,cluster) ("config_hash", alertmanager_config_hash{job="\(alertmanagerJob)",namespace="\(promNamespace)"})
									        )
									        != 1
									"""
								for:  kps.customRules.AlertmanagerConfigInconsistent.for | *"20m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.alertmanager != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.alertmanager
									}
								}
							}
						},
						if !kps.defaultRules.disabled.AlertmanagerFailedReload {
							{
								alert: "AlertmanagerClusterDown"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.alertmanager != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.alertmanager
									}
								}
								expr: """
									(
									          count by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )namespace,service,cluster) (
									            avg_over_time(up{job="\(alertmanagerJob)",namespace="\(promNamespace)"}[5m]) < 0.5
									          )
									        /
									          count by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )namespace,service,cluster) (
									            up{job="\(alertmanagerJob)",namespace="\(promNamespace)"}
									          )
									        )
									        >= 0.5
									"""
								for:  kps.customRules.AlertmanagerClusterDown.for | *"5m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.alertmanager != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.alertmanager
									}
								}
							}
						},
						if !kps.defaultRules.disabled.AlertmanagerFailedReload {
							{
								alert: "AlertmanagerClusterCrashlooping"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.alertmanager != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.alertmanager
									}
								}
								expr: """
									(
									          count by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )namespace,service,cluster) (
									            changes(process_start_time_seconds{job="\(alertmanagerJob)",namespace="\(promNamespace)"}[10m]) > 4
									          )
									        /
									          count by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )namespace,service,cluster) (
									            up{job="\(alertmanagerJob)",namespace="\(promNamespace)"}
									          )
									        )
									        >= 0.5
									"""
								for:  kps.customRules.AlertmanagerClusterCrashlooping.for | *"5m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.alertmanager != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.alertmanager
									}
								}
							}
						},
					]
				},
			]
		}
	}

	// config-reloaders.yaml
	if true && true && kps.defaultRules.create && kps.defaultRules.rules.configReloaders {
		"rule-config-reloaders": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "PrometheusRule"
			metadata: {
				name: (#KubePrometheusStackTruncatedName & {#name: "\(fullname)-config-reloaders"}).result
				namespace: promNamespace
				labels: amLabels & kps.defaultRules.labels & {
					app: chartName
				}
				if len(kps.defaultRules.annotations) > 0 {
					annotations: kps.defaultRules.annotations
				}
			}
			spec: groups: [
				{
					name: "config-reloaders"
					rules: [
						if !kps.defaultRules.disabled.ConfigReloaderSidecarErrors {
							{
								alert: "ConfigReloaderSidecarErrors"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.configReloaders != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.configReloaders
									}
								}
								expr: """
									max_over_time(reloader_last_reload_successful{namespace=~".+"}[5m]) == 0
									"""
								for: kps.customRules.ConfigReloaderSidecarErrors.for | *"10m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.configReloaders != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.configReloaders
									}
								}
							}
						},
					]
				},
			]
		}
	}

	// etcd.yaml
	if true && true && kps.defaultRules.create && kps.kubeEtcd.enabled && kps.defaultRules.rules.etcd {
		"rule-etcd": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "PrometheusRule"
			metadata: {
				name: (#KubePrometheusStackTruncatedName & {#name: "\(fullname)-etcd"}).result
				namespace: promNamespace
				labels: amLabels & kps.defaultRules.labels & {
					app: chartName
				}
				if len(kps.defaultRules.annotations) > 0 {
					annotations: kps.defaultRules.annotations
				}
			}
			spec: groups: [
				{
					name: "etcd"
					rules: [
						if !kps.defaultRules.disabled.etcdMembersDown {
							{
								alert: "etcdMembersDown"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.etcd != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.etcd
									}
								}
								expr: """
									max without (endpoint) (
									          sum without (instance, pod) (up{job=~".*etcd.*"} == bool 0)
									        or
									          count without (To) (
									            sum without (instance, pod) (rate(etcd_network_peer_sent_failures_total{job=~".*etcd.*"}[120s])) > 0.01
									          )
									        )
									        > 0
									"""
								for: kps.customRules.etcdMembersDown.for | *"10m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.etcd != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.etcd
									}
								}
							}
						},
						if !kps.defaultRules.disabled.etcdMembersDown {
							{
								alert: "etcdInsufficientMembers"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.etcd != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.etcd
									}
								}
								expr: """
									sum(up{job=~".*etcd.*"} == bool 1) without (instance, pod) < ((count(up{job=~".*etcd.*"}) without (instance, pod) + 1) / 2)
									"""
								for: kps.customRules.etcdInsufficientMembers.for | *"3m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.etcd != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.etcd
									}
								}
							}
						},
						if !kps.defaultRules.disabled.etcdMembersDown {
							{
								alert: "etcdNoLeader"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.etcd != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.etcd
									}
								}
								expr: """
									etcd_server_has_leader{job=~".*etcd.*"} == 0
									"""
								for: kps.customRules.etcdNoLeader.for | *"1m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.etcd != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.etcd
									}
								}
							}
						},
						if !kps.defaultRules.disabled.etcdMembersDown {
							{
								alert: "etcdHighNumberOfLeaderChanges"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.etcd != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.etcd
									}
								}
								expr: """
									increase((max without (instance, pod) (etcd_server_leader_changes_seen_total{job=~".*etcd.*"}) or 0*absent(etcd_server_leader_changes_seen_total{job=~".*etcd.*"}))[15m:1m]) >= 4
									"""
								for: kps.customRules.etcdHighNumberOfLeaderChanges.for | *"5m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.etcd != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.etcd
									}
								}
							}
						},
						if !kps.defaultRules.disabled.etcdMembersDown {
							{
								alert: "etcdHighNumberOfFailedGRPCRequests"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.etcd != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.etcd
									}
								}
								expr: """
									100 * sum(rate(grpc_server_handled_total{job=~".*etcd.*", grpc_code=~"Unknown|FailedPrecondition|ResourceExhausted|Internal|Unavailable|DataLoss|DeadlineExceeded"}[5m])) without (grpc_type, grpc_code)
									          /
									        sum(rate(grpc_server_handled_total{job=~".*etcd.*"}[5m])) without (grpc_type, grpc_code)
									          > 1
									"""
								for: kps.customRules.etcdHighNumberOfFailedGRPCRequests.for | *"10m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.etcd != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.etcd
									}
								}
							}
						},
						if !kps.defaultRules.disabled.etcdMembersDown {
							{
								alert: "etcdHighNumberOfFailedGRPCRequests"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.etcd != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.etcd
									}
								}
								expr: """
									100 * sum(rate(grpc_server_handled_total{job=~".*etcd.*", grpc_code=~"Unknown|FailedPrecondition|ResourceExhausted|Internal|Unavailable|DataLoss|DeadlineExceeded"}[5m])) without (grpc_type, grpc_code)
									          /
									        sum(rate(grpc_server_handled_total{job=~".*etcd.*"}[5m])) without (grpc_type, grpc_code)
									          > 5
									"""
								for: kps.customRules.etcdHighNumberOfFailedGRPCRequests.for | *"5m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.etcd != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.etcd
									}
								}
							}
						},
						if !kps.defaultRules.disabled.etcdMembersDown {
							{
								alert: "etcdGRPCRequestsSlow"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.etcd != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.etcd
									}
								}
								expr: """
									histogram_quantile(0.99, sum(rate(grpc_server_handling_seconds_bucket{job=~".*etcd.*", grpc_method!="Defragment", grpc_type="unary"}[5m])) without(grpc_type))
									        > 0.15
									"""
								for: kps.customRules.etcdGRPCRequestsSlow.for | *"10m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.etcd != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.etcd
									}
								}
							}
						},
						if !kps.defaultRules.disabled.etcdMembersDown {
							{
								alert: "etcdMemberCommunicationSlow"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.etcd != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.etcd
									}
								}
								expr: """
									histogram_quantile(0.99, rate(etcd_network_peer_round_trip_time_seconds_bucket{job=~".*etcd.*"}[5m]))
									        > 0.15
									"""
								for: kps.customRules.etcdMemberCommunicationSlow.for | *"10m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.etcd != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.etcd
									}
								}
							}
						},
						if !kps.defaultRules.disabled.etcdMembersDown {
							{
								alert: "etcdHighNumberOfFailedProposals"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.etcd != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.etcd
									}
								}
								expr: """
									rate(etcd_server_proposals_failed_total{job=~".*etcd.*"}[15m]) > 5
									"""
								for: kps.customRules.etcdHighNumberOfFailedProposals.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.etcd != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.etcd
									}
								}
							}
						},
						if !kps.defaultRules.disabled.etcdMembersDown {
							{
								alert: "etcdHighFsyncDurations"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.etcd != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.etcd
									}
								}
								expr: """
									histogram_quantile(0.99, rate(etcd_disk_wal_fsync_duration_seconds_bucket{job=~".*etcd.*"}[5m]))
									        > 0.5
									"""
								for: kps.customRules.etcdHighFsyncDurations.for | *"10m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.etcd != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.etcd
									}
								}
							}
						},
						if !kps.defaultRules.disabled.etcdMembersDown {
							{
								alert: "etcdHighFsyncDurations"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.etcd != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.etcd
									}
								}
								expr: """
									histogram_quantile(0.99, rate(etcd_disk_wal_fsync_duration_seconds_bucket{job=~".*etcd.*"}[5m]))
									        > 1
									"""
								for: kps.customRules.etcdHighFsyncDurations.for | *"10m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.etcd != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.etcd
									}
								}
							}
						},
						if !kps.defaultRules.disabled.etcdMembersDown {
							{
								alert: "etcdHighCommitDurations"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.etcd != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.etcd
									}
								}
								expr: """
									histogram_quantile(0.99, rate(etcd_disk_backend_commit_duration_seconds_bucket{job=~".*etcd.*"}[5m]))
									        > 0.25
									"""
								for: kps.customRules.etcdHighCommitDurations.for | *"10m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.etcd != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.etcd
									}
								}
							}
						},
						if !kps.defaultRules.disabled.etcdMembersDown {
							{
								alert: "etcdDatabaseQuotaLowSpace"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.etcd != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.etcd
									}
								}
								expr: """
									(last_over_time(etcd_mvcc_db_total_size_in_bytes{job=~".*etcd.*"}[5m]) / last_over_time(etcd_server_quota_backend_bytes{job=~".*etcd.*"}[5m]))*100 > 95
									"""
								for: kps.customRules.etcdDatabaseQuotaLowSpace.for | *"10m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.etcd != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.etcd
									}
								}
							}
						},
						if !kps.defaultRules.disabled.etcdMembersDown {
							{
								alert: "etcdExcessiveDatabaseGrowth"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.etcd != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.etcd
									}
								}
								expr: """
									predict_linear(etcd_mvcc_db_total_size_in_bytes{job=~".*etcd.*"}[4h], 4*60*60) > etcd_server_quota_backend_bytes{job=~".*etcd.*"}
									"""
								for: kps.customRules.etcdExcessiveDatabaseGrowth.for | *"10m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.etcd != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.etcd
									}
								}
							}
						},
						if !kps.defaultRules.disabled.etcdMembersDown {
							{
								alert: "etcdDatabaseHighFragmentationRatio"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.etcd != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.etcd
									}
								}
								expr: """
									(last_over_time(etcd_mvcc_db_total_size_in_use_in_bytes{job=~".*etcd.*"}[5m]) / last_over_time(etcd_mvcc_db_total_size_in_bytes{job=~".*etcd.*"}[5m])) < 0.5 and etcd_mvcc_db_total_size_in_use_in_bytes{job=~".*etcd.*"} > 104857600
									"""
								for: kps.customRules.etcdDatabaseHighFragmentationRatio.for | *"10m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.etcd != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.etcd
									}
								}
							}
						},
					]
				},
			]
		}
	}

	// general.rules.yaml
	if true && true && kps.defaultRules.create && kps.defaultRules.rules.general {
		"rule-general-rules": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "PrometheusRule"
			metadata: {
				name: (#KubePrometheusStackTruncatedName & {#name: "\(fullname)-general.rules"}).result
				namespace: promNamespace
				labels: amLabels & kps.defaultRules.labels & {
					app: chartName
				}
				if len(kps.defaultRules.annotations) > 0 {
					annotations: kps.defaultRules.annotations
				}
			}
			spec: groups: [
				{
					name: "general.rules"
					rules: [
						if !kps.defaultRules.disabled.TargetDown {
							{
								alert: "TargetDown"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.general != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.general
									}
								}
								expr: """
									100 * (count(up == 0) BY (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster, job, namespace, service) / count(up) BY (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster, job, namespace, service)) > 10
									"""
								for:  kps.customRules.TargetDown.for | *"10m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.general != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.general
									}
								}
							}
						},
						if !kps.defaultRules.disabled.TargetDown {
							{
								alert: "Watchdog"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.general != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.general
									}
								}
								expr: """
									vector(1)
									"""
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.general != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.general
									}
								}
							}
						},
						if !kps.defaultRules.disabled.TargetDown {
							{
								alert: "InfoInhibitor"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.general != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.general
									}
								}
								expr: """
									ALERTS{severity = "info"} == 1 unless on (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )namespace) ALERTS{alertname != "InfoInhibitor", severity =~ "warning|critical", alertstate="firing"} == 1
									"""
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.general != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.general
									}
								}
							}
						},
					]
				},
			]
		}
	}

	// k8s.rules.container_cpu_limits.yaml
	if true && true && kps.defaultRules.create && kps.defaultRules.rules.k8sContainerCpuLimits {
		"rule-k8s-rules-container-cpu-limits": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "PrometheusRule"
			metadata: {
				name: (#KubePrometheusStackTruncatedName & {#name: "\(fullname)-k8s.rules.container-cpu-limits"}).result
				namespace: promNamespace
				labels: amLabels & kps.defaultRules.labels & {
					app: chartName
				}
				if len(kps.defaultRules.annotations) > 0 {
					annotations: kps.defaultRules.annotations
				}
			}
			spec: groups: [
				{
					name: "k8s.rules.container_cpu_limits"
					rules: []
				},
			]
		}
	}

	// k8s.rules.container_cpu_requests.yaml
	if true && true && kps.defaultRules.create && kps.defaultRules.rules.k8sContainerCpuRequests {
		"rule-k8s-rules-container-cpu-requests": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "PrometheusRule"
			metadata: {
				name: (#KubePrometheusStackTruncatedName & {#name: "\(fullname)-k8s.rules.container-cpu-requests"}).result
				namespace: promNamespace
				labels: amLabels & kps.defaultRules.labels & {
					app: chartName
				}
				if len(kps.defaultRules.annotations) > 0 {
					annotations: kps.defaultRules.annotations
				}
			}
			spec: groups: [
				{
					name: "k8s.rules.container_cpu_requests"
					rules: []
				},
			]
		}
	}

	// k8s.rules.container_cpu_usage_seconds_total.yaml
	if true && true && kps.defaultRules.create && kps.defaultRules.rules.k8sContainerCpuUsageSecondsTotal {
		"rule-k8s-rules-container-cpu-usage-seconds-total": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "PrometheusRule"
			metadata: {
				name: (#KubePrometheusStackTruncatedName & {#name: "\(fullname)-k8s.rules.container-cpu-usage-seconds-total"}).result
				namespace: promNamespace
				labels: amLabels & kps.defaultRules.labels & {
					app: chartName
				}
				if len(kps.defaultRules.annotations) > 0 {
					annotations: kps.defaultRules.annotations
				}
			}
			spec: groups: [
				{
					name: "k8s.rules.container_cpu_usage_seconds_total"
					rules: []
				},
			]
		}
	}

	// k8s.rules.container_memory_cache.yaml
	if true && true && kps.defaultRules.create && kps.defaultRules.rules.k8sContainerMemoryCache {
		"rule-k8s-rules-container-memory-cache": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "PrometheusRule"
			metadata: {
				name: (#KubePrometheusStackTruncatedName & {#name: "\(fullname)-k8s.rules.container-memory-cache"}).result
				namespace: promNamespace
				labels: amLabels & kps.defaultRules.labels & {
					app: chartName
				}
				if len(kps.defaultRules.annotations) > 0 {
					annotations: kps.defaultRules.annotations
				}
			}
			spec: groups: [
				{
					name: "k8s.rules.container_memory_cache"
					rules: []
				},
			]
		}
	}

	// k8s.rules.container_memory_limits.yaml
	if true && true && kps.defaultRules.create && kps.defaultRules.rules.k8sContainerMemoryLimits {
		"rule-k8s-rules-container-memory-limits": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "PrometheusRule"
			metadata: {
				name: (#KubePrometheusStackTruncatedName & {#name: "\(fullname)-k8s.rules.container-memory-limits"}).result
				namespace: promNamespace
				labels: amLabels & kps.defaultRules.labels & {
					app: chartName
				}
				if len(kps.defaultRules.annotations) > 0 {
					annotations: kps.defaultRules.annotations
				}
			}
			spec: groups: [
				{
					name: "k8s.rules.container_memory_limits"
					rules: []
				},
			]
		}
	}

	// k8s.rules.container_memory_requests.yaml
	if true && true && kps.defaultRules.create && kps.defaultRules.rules.k8sContainerMemoryRequests {
		"rule-k8s-rules-container-memory-requests": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "PrometheusRule"
			metadata: {
				name: (#KubePrometheusStackTruncatedName & {#name: "\(fullname)-k8s.rules.container-memory-requests"}).result
				namespace: promNamespace
				labels: amLabels & kps.defaultRules.labels & {
					app: chartName
				}
				if len(kps.defaultRules.annotations) > 0 {
					annotations: kps.defaultRules.annotations
				}
			}
			spec: groups: [
				{
					name: "k8s.rules.container_memory_requests"
					rules: []
				},
			]
		}
	}

	// k8s.rules.container_memory_rss.yaml
	if true && true && kps.defaultRules.create && kps.defaultRules.rules.k8sContainerMemoryRss {
		"rule-k8s-rules-container-memory-rss": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "PrometheusRule"
			metadata: {
				name: (#KubePrometheusStackTruncatedName & {#name: "\(fullname)-k8s.rules.container-memory-rss"}).result
				namespace: promNamespace
				labels: amLabels & kps.defaultRules.labels & {
					app: chartName
				}
				if len(kps.defaultRules.annotations) > 0 {
					annotations: kps.defaultRules.annotations
				}
			}
			spec: groups: [
				{
					name: "k8s.rules.container_memory_rss"
					rules: []
				},
			]
		}
	}

	// k8s.rules.container_memory_swap.yaml
	if true && true && kps.defaultRules.create && kps.defaultRules.rules.k8sContainerMemorySwap {
		"rule-k8s-rules-container-memory-swap": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "PrometheusRule"
			metadata: {
				name: (#KubePrometheusStackTruncatedName & {#name: "\(fullname)-k8s.rules.container-memory-swap"}).result
				namespace: promNamespace
				labels: amLabels & kps.defaultRules.labels & {
					app: chartName
				}
				if len(kps.defaultRules.annotations) > 0 {
					annotations: kps.defaultRules.annotations
				}
			}
			spec: groups: [
				{
					name: "k8s.rules.container_memory_swap"
					rules: []
				},
			]
		}
	}

	// k8s.rules.container_memory_working_set_bytes.yaml
	if true && true && kps.defaultRules.create && kps.defaultRules.rules.k8sContainerMemoryWorkingSetBytes {
		"rule-k8s-rules-container-memory-working-set-bytes": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "PrometheusRule"
			metadata: {
				name: (#KubePrometheusStackTruncatedName & {#name: "\(fullname)-k8s.rules.container-memory-working-set-bytes"}).result
				namespace: promNamespace
				labels: amLabels & kps.defaultRules.labels & {
					app: chartName
				}
				if len(kps.defaultRules.annotations) > 0 {
					annotations: kps.defaultRules.annotations
				}
			}
			spec: groups: [
				{
					name: "k8s.rules.container_memory_working_set_bytes"
					rules: []
				},
			]
		}
	}

	// k8s.rules.container_resource.yaml
	if true && true && kps.defaultRules.create && kps.defaultRules.rules.k8sContainerResource {
		"rule-k8s-rules-container-resource": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "PrometheusRule"
			metadata: {
				name: (#KubePrometheusStackTruncatedName & {#name: "\(fullname)-k8s.rules.container-resource"}).result
				namespace: promNamespace
				labels: amLabels & kps.defaultRules.labels & {
					app: chartName
				}
				if len(kps.defaultRules.annotations) > 0 {
					annotations: kps.defaultRules.annotations
				}
			}
			spec: groups: [
				{
					name: "k8s.rules.container_resource"
					rules: []
				},
			]
		}
	}

	// k8s.rules.pod_owner.yaml
	if true && true && kps.defaultRules.create && kps.defaultRules.rules.k8sPodOwner {
		"rule-k8s-rules-pod-owner": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "PrometheusRule"
			metadata: {
				name: (#KubePrometheusStackTruncatedName & {#name: "\(fullname)-k8s.rules.pod-owner"}).result
				namespace: promNamespace
				labels: amLabels & kps.defaultRules.labels & {
					app: chartName
				}
				if len(kps.defaultRules.annotations) > 0 {
					annotations: kps.defaultRules.annotations
				}
			}
			spec: groups: [
				{
					name: "k8s.rules.pod_owner"
					rules: []
				},
			]
		}
	}

	// kube-apiserver-availability.rules.yaml
	if true && true && kps.defaultRules.create && kps.kubeApiServer.enabled && kps.defaultRules.rules.kubeApiserverAvailability {
		"rule-kube-apiserver-availability-rules": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "PrometheusRule"
			metadata: {
				name: (#KubePrometheusStackTruncatedName & {#name: "\(fullname)-kube-apiserver-availability.rules"}).result
				namespace: promNamespace
				labels: amLabels & kps.defaultRules.labels & {
					app: chartName
				}
				if len(kps.defaultRules.annotations) > 0 {
					annotations: kps.defaultRules.annotations
				}
			}
			spec: groups: []
		}
	}

	// kube-apiserver-burnrate.rules.yaml
	if true && true && kps.defaultRules.create && kps.kubeApiServer.enabled && kps.defaultRules.rules.kubeApiserverBurnrate {
		"rule-kube-apiserver-burnrate-rules": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "PrometheusRule"
			metadata: {
				name: (#KubePrometheusStackTruncatedName & {#name: "\(fullname)-kube-apiserver-burnrate.rules"}).result
				namespace: promNamespace
				labels: amLabels & kps.defaultRules.labels & {
					app: chartName
				}
				if len(kps.defaultRules.annotations) > 0 {
					annotations: kps.defaultRules.annotations
				}
			}
			spec: groups: [
				{
					name: "kube-apiserver-burnrate.rules"
					rules: []
				},
			]
		}
	}

	// kube-apiserver-histogram.rules.yaml
	if true && true && kps.defaultRules.create && kps.kubeApiServer.enabled && kps.defaultRules.rules.kubeApiserverHistogram {
		"rule-kube-apiserver-histogram-rules": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "PrometheusRule"
			metadata: {
				name: (#KubePrometheusStackTruncatedName & {#name: "\(fullname)-kube-apiserver-histogram.rules"}).result
				namespace: promNamespace
				labels: amLabels & kps.defaultRules.labels & {
					app: chartName
				}
				if len(kps.defaultRules.annotations) > 0 {
					annotations: kps.defaultRules.annotations
				}
			}
			spec: groups: [
				{
					name: "kube-apiserver-histogram.rules"
					rules: []
				},
			]
		}
	}

	// kube-apiserver-slos.yaml
	if true && true && kps.defaultRules.create && kps.kubeApiServer.enabled && kps.defaultRules.rules.kubeApiserverSlos {
		"rule-kube-apiserver-slos": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "PrometheusRule"
			metadata: {
				name: (#KubePrometheusStackTruncatedName & {#name: "\(fullname)-kube-apiserver-slos"}).result
				namespace: promNamespace
				labels: amLabels & kps.defaultRules.labels & {
					app: chartName
				}
				if len(kps.defaultRules.annotations) > 0 {
					annotations: kps.defaultRules.annotations
				}
			}
			spec: groups: [
				{
					name: "kube-apiserver-slos"
					rules: [
						if !kps.defaultRules.disabled.KubeAPIErrorBudgetBurn {
							{
								alert: "KubeAPIErrorBudgetBurn"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubeApiserverSlos != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubeApiserverSlos
									}
								}
								expr: """
									sum by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster) (apiserver_request:burnrate1h) > (14.40 * 0.01000)
									        and on (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster)
									        sum by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster) (apiserver_request:burnrate5m) > (14.40 * 0.01000)
									"""
								for:  kps.customRules.KubeAPIErrorBudgetBurn.for | *"2m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubeApiserverSlos != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubeApiserverSlos
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubeAPIErrorBudgetBurn {
							{
								alert: "KubeAPIErrorBudgetBurn"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubeApiserverSlos != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubeApiserverSlos
									}
								}
								expr: """
									sum by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster) (apiserver_request:burnrate6h) > (6.00 * 0.01000)
									        and on (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster)
									        sum by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster) (apiserver_request:burnrate30m) > (6.00 * 0.01000)
									"""
								for:  kps.customRules.KubeAPIErrorBudgetBurn.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubeApiserverSlos != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubeApiserverSlos
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubeAPIErrorBudgetBurn {
							{
								alert: "KubeAPIErrorBudgetBurn"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubeApiserverSlos != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubeApiserverSlos
									}
								}
								expr: """
									sum by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster) (apiserver_request:burnrate1d) > (3.00 * 0.01000)
									        and on (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster)
									        sum by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster) (apiserver_request:burnrate2h) > (3.00 * 0.01000)
									"""
								for:  kps.customRules.KubeAPIErrorBudgetBurn.for | *"1h"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubeApiserverSlos != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubeApiserverSlos
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubeAPIErrorBudgetBurn {
							{
								alert: "KubeAPIErrorBudgetBurn"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubeApiserverSlos != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubeApiserverSlos
									}
								}
								expr: """
									sum by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster) (apiserver_request:burnrate3d) > (1.00 * 0.01000)
									        and on (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster)
									        sum by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster) (apiserver_request:burnrate6h) > (1.00 * 0.01000)
									"""
								for:  kps.customRules.KubeAPIErrorBudgetBurn.for | *"3h"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubeApiserverSlos != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubeApiserverSlos
									}
								}
							}
						},
					]
				},
			]
		}
	}

	// kube-prometheus-general.rules.yaml
	if true && true && kps.defaultRules.create && kps.defaultRules.rules.kubePrometheusGeneral {
		"rule-kube-prometheus-general-rules": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "PrometheusRule"
			metadata: {
				name: (#KubePrometheusStackTruncatedName & {#name: "\(fullname)-kube-prometheus-general.rules"}).result
				namespace: promNamespace
				labels: amLabels & kps.defaultRules.labels & {
					app: chartName
				}
				if len(kps.defaultRules.annotations) > 0 {
					annotations: kps.defaultRules.annotations
				}
			}
			spec: groups: [
				{
					name: "kube-prometheus-general.rules"
					rules: []
				},
			]
		}
	}

	// kube-prometheus-node-recording.rules.yaml
	if true && true && kps.defaultRules.create && kps.defaultRules.rules.kubePrometheusNodeRecording {
		"rule-kube-prometheus-node-recording-rules": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "PrometheusRule"
			metadata: {
				name: (#KubePrometheusStackTruncatedName & {#name: "\(fullname)-kube-prometheus-node-recording.rules"}).result
				namespace: promNamespace
				labels: amLabels & kps.defaultRules.labels & {
					app: chartName
				}
				if len(kps.defaultRules.annotations) > 0 {
					annotations: kps.defaultRules.annotations
				}
			}
			spec: groups: [
				{
					name: "kube-prometheus-node-recording.rules"
					rules: []
				},
			]
		}
	}

	// kube-scheduler.rules.yaml
	if true && true && kps.defaultRules.create && kps.kubeScheduler.enabled && kps.defaultRules.rules.kubeSchedulerRecording {
		"rule-kube-scheduler-rules": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "PrometheusRule"
			metadata: {
				name: (#KubePrometheusStackTruncatedName & {#name: "\(fullname)-kube-scheduler.rules"}).result
				namespace: promNamespace
				labels: amLabels & kps.defaultRules.labels & {
					app: chartName
				}
				if len(kps.defaultRules.annotations) > 0 {
					annotations: kps.defaultRules.annotations
				}
			}
			spec: groups: [
				{
					name: "kube-scheduler.rules"
					rules: []
				},
			]
		}
	}

	// kube-state-metrics.yaml
	if true && true && kps.defaultRules.create && kps.defaultRules.rules.kubeStateMetrics {
		let kubeStateMetricsJob = "\(fullname)-kube-state-metrics"
		"rule-kube-state-metrics": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "PrometheusRule"
			metadata: {
				name: (#KubePrometheusStackTruncatedName & {#name: "\(fullname)-kube-state-metrics"}).result
				namespace: promNamespace
				labels: amLabels & kps.defaultRules.labels & {
					app: chartName
				}
				if len(kps.defaultRules.annotations) > 0 {
					annotations: kps.defaultRules.annotations
				}
			}
			spec: groups: [
				{
					name: "kube-state-metrics"
					rules: [
						if !kps.defaultRules.disabled.KubeStateMetricsListErrors {
							{
								alert: "KubeStateMetricsListErrors"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubeStateMetrics != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubeStateMetrics
									}
								}
								expr: """
									(sum(rate(kube_state_metrics_list_total{job="\(kubeStateMetricsJob)",result="error"}[5m])) by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster)
									          /
									        sum(rate(kube_state_metrics_list_total{job="\(kubeStateMetricsJob)"}[5m])) by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster))
									        > 0.01
									"""
								for:  kps.customRules.KubeStateMetricsListErrors.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubeStateMetrics != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubeStateMetrics
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubeStateMetricsListErrors {
							{
								alert: "KubeStateMetricsWatchErrors"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubeStateMetrics != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubeStateMetrics
									}
								}
								expr: """
									(sum(rate(kube_state_metrics_watch_total{job="\(kubeStateMetricsJob)",result="error"}[5m])) by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster)
									          /
									        sum(rate(kube_state_metrics_watch_total{job="\(kubeStateMetricsJob)"}[5m])) by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster))
									        > 0.01
									"""
								for:  kps.customRules.KubeStateMetricsWatchErrors.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubeStateMetrics != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubeStateMetrics
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubeStateMetricsListErrors {
							{
								alert: "KubeStateMetricsShardingMismatch"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubeStateMetrics != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubeStateMetrics
									}
								}
								expr: """
									stdvar (kube_state_metrics_total_shards{job="\(kubeStateMetricsJob)"}) by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster) != 0
									"""
								for:  kps.customRules.KubeStateMetricsShardingMismatch.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubeStateMetrics != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubeStateMetrics
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubeStateMetricsListErrors {
							{
								alert: "KubeStateMetricsShardsMissing"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubeStateMetrics != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubeStateMetrics
									}
								}
								expr: """
									2^max(kube_state_metrics_total_shards{job="\(kubeStateMetricsJob)"}) by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster) - 1
									          -
									        sum( 2 ^ max by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster, shard_ordinal) (kube_state_metrics_shard_ordinal{job="\(kubeStateMetricsJob)"}) ) by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster)
									        != 0
									"""
								for:  kps.customRules.KubeStateMetricsShardsMissing.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubeStateMetrics != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubeStateMetrics
									}
								}
							}
						},
					]
				},
			]
		}
	}

	// kubelet.rules.yaml
	if true && true && kps.defaultRules.create && kps.kubelet.enabled && kps.defaultRules.rules.kubelet {
		"rule-kubelet-rules": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "PrometheusRule"
			metadata: {
				name: (#KubePrometheusStackTruncatedName & {#name: "\(fullname)-kubelet.rules"}).result
				namespace: promNamespace
				labels: amLabels & kps.defaultRules.labels & {
					app: chartName
				}
				if len(kps.defaultRules.annotations) > 0 {
					annotations: kps.defaultRules.annotations
				}
			}
			spec: groups: [
				{
					name: "kubelet.rules"
					rules: []
				},
			]
		}
	}

	// kubernetes-apps.yaml
	if true && true && kps.defaultRules.create && kps.defaultRules.rules.kubernetesApps {
		let kubeStateMetricsJob = "\(fullname)-kube-state-metrics"
		"rule-kubernetes-apps": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "PrometheusRule"
			metadata: {
				name: (#KubePrometheusStackTruncatedName & {#name: "\(fullname)-kubernetes-apps"}).result
				namespace: promNamespace
				labels: amLabels & kps.defaultRules.labels & {
					app: chartName
				}
				if len(kps.defaultRules.annotations) > 0 {
					annotations: kps.defaultRules.annotations
				}
			}
			spec: groups: [
				{
					name: "kubernetes-apps"
					rules: [
						if !kps.defaultRules.disabled.KubePodCrashLooping {
							{
								alert: "KubePodCrashLooping"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesApps != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesApps
									}
								}
								expr: """
									max_over_time(kube_pod_container_status_waiting_reason{reason="CrashLoopBackOff", job="\(kubeStateMetricsJob)", namespace=~"\(promNamespace)"}[5m]) >= 1
									"""
								for:  kps.customRules.KubePodCrashLooping.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesApps != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesApps
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubePodCrashLooping {
							{
								alert: "KubePodNotReady"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesApps != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesApps
									}
								}
								expr: """
									sum by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )namespace, pod, cluster) (
									          max by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )namespace, pod, cluster) (
									            kube_pod_status_phase{job="\(kubeStateMetricsJob)", namespace=~"\(promNamespace)", phase=~"Pending|Unknown|Failed"}
									          ) * on (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )namespace, pod, cluster) group_left(owner_kind) topk by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )namespace, pod, cluster) (
									            1, max by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )namespace, pod, owner_kind, cluster) (kube_pod_owner{owner_kind!="Job"})
									          )
									        ) > 0
									"""
								for:  kps.customRules.KubePodNotReady.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesApps != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesApps
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubePodCrashLooping {
							{
								alert: "KubeDeploymentGenerationMismatch"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesApps != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesApps
									}
								}
								expr: """
									kube_deployment_status_observed_generation{job="\(kubeStateMetricsJob)", namespace=~"\(promNamespace)"}
									          !=
									        kube_deployment_metadata_generation{job="\(kubeStateMetricsJob)", namespace=~"\(promNamespace)"}
									"""
								for:  kps.customRules.KubeDeploymentGenerationMismatch.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesApps != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesApps
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubePodCrashLooping {
							{
								alert: "KubeDeploymentReplicasMismatch"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesApps != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesApps
									}
								}
								expr: """
									(
									          kube_deployment_spec_replicas{job="\(kubeStateMetricsJob)", namespace=~"\(promNamespace)"}
									            >
									          kube_deployment_status_replicas_available{job="\(kubeStateMetricsJob)", namespace=~"\(promNamespace)"}
									        ) and (
									          changes(kube_deployment_status_replicas_updated{job="\(kubeStateMetricsJob)", namespace=~"\(promNamespace)"}[10m])
									            ==
									          0
									        )
									"""
								for:  kps.customRules.KubeDeploymentReplicasMismatch.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesApps != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesApps
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubePodCrashLooping {
							{
								alert: "KubeDeploymentRolloutStuck"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesApps != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesApps
									}
								}
								expr: """
									kube_deployment_status_condition{condition="Progressing", status="false",job="\(kubeStateMetricsJob)", namespace=~"\(promNamespace)"}
									        != 0
									"""
								for:  kps.customRules.KubeDeploymentRolloutStuck.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesApps != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesApps
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubePodCrashLooping {
							{
								alert: "KubeStatefulSetReplicasMismatch"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesApps != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesApps
									}
								}
								expr: """
									(
									          kube_statefulset_status_replicas_ready{job="\(kubeStateMetricsJob)", namespace=~"\(promNamespace)"}
									            !=
									          kube_statefulset_status_replicas{job="\(kubeStateMetricsJob)", namespace=~"\(promNamespace)"}
									        ) and (
									          changes(kube_statefulset_status_replicas_updated{job="\(kubeStateMetricsJob)", namespace=~"\(promNamespace)"}[10m])
									            ==
									          0
									        )
									"""
								for:  kps.customRules.KubeStatefulSetReplicasMismatch.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesApps != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesApps
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubePodCrashLooping {
							{
								alert: "KubeStatefulSetGenerationMismatch"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesApps != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesApps
									}
								}
								expr: """
									kube_statefulset_status_observed_generation{job="\(kubeStateMetricsJob)", namespace=~"\(promNamespace)"}
									          !=
									        kube_statefulset_metadata_generation{job="\(kubeStateMetricsJob)", namespace=~"\(promNamespace)"}
									"""
								for:  kps.customRules.KubeStatefulSetGenerationMismatch.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesApps != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesApps
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubePodCrashLooping {
							{
								alert: "KubeStatefulSetUpdateNotRolledOut"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesApps != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesApps
									}
								}
								expr: """
									(
									          max by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )namespace, statefulset, job, cluster) (
									            kube_statefulset_status_current_revision{job="\(kubeStateMetricsJob)", namespace=~"\(promNamespace)"}
									              unless
									            kube_statefulset_status_update_revision{job="\(kubeStateMetricsJob)", namespace=~"\(promNamespace)"}
									          )
									            *
									          (
									            kube_statefulset_replicas{job="\(kubeStateMetricsJob)", namespace=~"\(promNamespace)"}
									              !=
									            kube_statefulset_status_replicas_updated{job="\(kubeStateMetricsJob)", namespace=~"\(promNamespace)"}
									          )
									        )  and (
									          changes(kube_statefulset_status_replicas_updated{job="\(kubeStateMetricsJob)", namespace=~"\(promNamespace)"}[5m])
									            ==
									          0
									        )
									"""
								for:  kps.customRules.KubeStatefulSetUpdateNotRolledOut.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesApps != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesApps
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubePodCrashLooping {
							{
								alert: "KubeDaemonSetRolloutStuck"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesApps != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesApps
									}
								}
								expr: """
									(
									          (
									            kube_daemonset_status_current_number_scheduled{job="\(kubeStateMetricsJob)", namespace=~"\(promNamespace)"}
									             !=
									            kube_daemonset_status_desired_number_scheduled{job="\(kubeStateMetricsJob)", namespace=~"\(promNamespace)"}
									          ) or (
									            kube_daemonset_status_number_misscheduled{job="\(kubeStateMetricsJob)", namespace=~"\(promNamespace)"}
									             !=
									            0
									          ) or (
									            kube_daemonset_status_updated_number_scheduled{job="\(kubeStateMetricsJob)", namespace=~"\(promNamespace)"}
									             !=
									            kube_daemonset_status_desired_number_scheduled{job="\(kubeStateMetricsJob)", namespace=~"\(promNamespace)"}
									          ) or (
									            kube_daemonset_status_number_available{job="\(kubeStateMetricsJob)", namespace=~"\(promNamespace)"}
									             !=
									            kube_daemonset_status_desired_number_scheduled{job="\(kubeStateMetricsJob)", namespace=~"\(promNamespace)"}
									          )
									        ) and (
									          changes(kube_daemonset_status_updated_number_scheduled{job="\(kubeStateMetricsJob)", namespace=~"\(promNamespace)"}[5m])
									            ==
									          0
									        )
									"""
								for:  kps.customRules.KubeDaemonSetRolloutStuck.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesApps != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesApps
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubePodCrashLooping {
							{
								alert: "KubeContainerWaiting"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesApps != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesApps
									}
								}
								expr: """
									sum by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )namespace, pod, container, cluster) (kube_pod_container_status_waiting_reason{job="\(kubeStateMetricsJob)", namespace=~"\(promNamespace)"}) > 0
									"""
								for:  kps.customRules.KubeContainerWaiting.for | *"1h"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesApps != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesApps
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubePodCrashLooping {
							{
								alert: "KubeDaemonSetNotScheduled"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesApps != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesApps
									}
								}
								expr: """
									kube_daemonset_status_desired_number_scheduled{job="\(kubeStateMetricsJob)", namespace=~"\(promNamespace)"}
									          -
									        kube_daemonset_status_current_number_scheduled{job="\(kubeStateMetricsJob)", namespace=~"\(promNamespace)"} > 0
									"""
								for:  kps.customRules.KubeDaemonSetNotScheduled.for | *"10m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesApps != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesApps
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubePodCrashLooping {
							{
								alert: "KubeDaemonSetMisScheduled"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesApps != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesApps
									}
								}
								expr: """
									kube_daemonset_status_number_misscheduled{job="\(kubeStateMetricsJob)", namespace=~"\(promNamespace)"} > 0
									"""
								for:  kps.customRules.KubeDaemonSetMisScheduled.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesApps != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesApps
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubePodCrashLooping {
							{
								alert: "KubeJobNotCompleted"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesApps != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesApps
									}
								}
								expr: """
									time() - max by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )namespace, job_name, cluster) (kube_job_status_start_time{job="\(kubeStateMetricsJob)", namespace=~"\(promNamespace)"}
									          and
									        kube_job_status_active{job="\(kubeStateMetricsJob)", namespace=~"\(promNamespace)"} > 0) > 43200
									"""
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesApps != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesApps
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubePodCrashLooping {
							{
								alert: "KubeJobFailed"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesApps != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesApps
									}
								}
								expr: """
									kube_job_failed{job="\(kubeStateMetricsJob)", namespace=~"\(promNamespace)"}  > 0
									"""
								for:  kps.customRules.KubeJobFailed.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesApps != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesApps
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubePodCrashLooping {
							{
								alert: "KubeHpaReplicasMismatch"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesApps != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesApps
									}
								}
								expr: """
									(kube_horizontalpodautoscaler_status_desired_replicas{job="\(kubeStateMetricsJob)", namespace=~"\(promNamespace)"}
									          !=
									        kube_horizontalpodautoscaler_status_current_replicas{job="\(kubeStateMetricsJob)", namespace=~"\(promNamespace)"})
									          and
									        (kube_horizontalpodautoscaler_status_current_replicas{job="\(kubeStateMetricsJob)", namespace=~"\(promNamespace)"}
									          >
									        kube_horizontalpodautoscaler_spec_min_replicas{job="\(kubeStateMetricsJob)", namespace=~"\(promNamespace)"})
									          and
									        (kube_horizontalpodautoscaler_status_current_replicas{job="\(kubeStateMetricsJob)", namespace=~"\(promNamespace)"}
									          <
									        kube_horizontalpodautoscaler_spec_max_replicas{job="\(kubeStateMetricsJob)", namespace=~"\(promNamespace)"})
									          and
									        changes(kube_horizontalpodautoscaler_status_current_replicas{job="\(kubeStateMetricsJob)", namespace=~"\(promNamespace)"}[15m]) == 0
									"""
								for:  kps.customRules.KubeHpaReplicasMismatch.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesApps != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesApps
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubePodCrashLooping {
							{
								alert: "KubeHpaMaxedOut"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesApps != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesApps
									}
								}
								expr: """
									kube_horizontalpodautoscaler_status_current_replicas{job="\(kubeStateMetricsJob)", namespace=~"\(promNamespace)"}
									          ==
									        kube_horizontalpodautoscaler_spec_max_replicas{job="\(kubeStateMetricsJob)", namespace=~"\(promNamespace)"}
									"""
								for:  kps.customRules.KubeHpaMaxedOut.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesApps != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesApps
									}
								}
							}
						},
					]
				},
			]
		}
	}

	// kubernetes-resources.yaml
	if true && true && kps.defaultRules.create && kps.defaultRules.rules.kubernetesResources {
		let kubeStateMetricsJob = "\(fullname)-kube-state-metrics"
		"rule-kubernetes-resources": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "PrometheusRule"
			metadata: {
				name: (#KubePrometheusStackTruncatedName & {#name: "\(fullname)-kubernetes-resources"}).result
				namespace: promNamespace
				labels: amLabels & kps.defaultRules.labels & {
					app: chartName
				}
				if len(kps.defaultRules.annotations) > 0 {
					annotations: kps.defaultRules.annotations
				}
			}
			spec: groups: [
				{
					name: "kubernetes-resources"
					rules: [
						if !kps.defaultRules.disabled.KubeCPUOvercommit {
							{
								alert: "KubeCPUOvercommit"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesResources != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesResources
									}
								}
								expr: """
									sum(namespace_cpu:kube_pod_container_resource_requests:sum{}) by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster) - (sum(kube_node_status_allocatable{job="\(kubeStateMetricsJob)",resource="cpu"}) by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster) - max(kube_node_status_allocatable{job="\(kubeStateMetricsJob)",resource="cpu"}) by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster)) > 0
									        and
									        (sum(kube_node_status_allocatable{job="\(kubeStateMetricsJob)",resource="cpu"}) by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster) - max(kube_node_status_allocatable{job="\(kubeStateMetricsJob)",resource="cpu"}) by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster)) > 0
									"""
								for:  kps.customRules.KubeCPUOvercommit.for | *"10m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesResources != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesResources
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubeCPUOvercommit {
							{
								alert: "KubeMemoryOvercommit"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesResources != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesResources
									}
								}
								expr: """
									sum(namespace_memory:kube_pod_container_resource_requests:sum{}) by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster) - (sum(kube_node_status_allocatable{resource="memory", job="\(kubeStateMetricsJob)"}) by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster) - max(kube_node_status_allocatable{resource="memory", job="\(kubeStateMetricsJob)"}) by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster)) > 0
									        and
									        (sum(kube_node_status_allocatable{resource="memory", job="\(kubeStateMetricsJob)"}) by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster) - max(kube_node_status_allocatable{resource="memory", job="\(kubeStateMetricsJob)"}) by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster)) > 0
									"""
								for:  kps.customRules.KubeMemoryOvercommit.for | *"10m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesResources != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesResources
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubeCPUOvercommit {
							{
								alert: "KubeCPUQuotaOvercommit"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesResources != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesResources
									}
								}
								expr: """
									sum(min without(resource) (kube_resourcequota{job="\(kubeStateMetricsJob)", type="hard", resource=~"(cpu|requests.cpu)"})) by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster)
									          /
									        sum(kube_node_status_allocatable{resource="cpu", job="\(kubeStateMetricsJob)"}) by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster)
									          > 1.5
									"""
								for:  kps.customRules.KubeCPUQuotaOvercommit.for | *"5m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesResources != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesResources
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubeCPUOvercommit {
							{
								alert: "KubeMemoryQuotaOvercommit"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesResources != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesResources
									}
								}
								expr: """
									sum(min without(resource) (kube_resourcequota{job="\(kubeStateMetricsJob)", type="hard", resource=~"(memory|requests.memory)"})) by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster)
									          /
									        sum(kube_node_status_allocatable{resource="memory", job="\(kubeStateMetricsJob)"}) by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster)
									          > 1.5
									"""
								for:  kps.customRules.KubeMemoryQuotaOvercommit.for | *"5m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesResources != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesResources
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubeCPUOvercommit {
							{
								alert: "KubeQuotaAlmostFull"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesResources != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesResources
									}
								}
								expr: """
									kube_resourcequota{job="\(kubeStateMetricsJob)", type="used"}
									          / ignoring(instance, job, type)
									        (kube_resourcequota{job="\(kubeStateMetricsJob)", type="hard"} > 0)
									          > 0.9 < 1
									"""
								for:  kps.customRules.KubeQuotaAlmostFull.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesResources != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesResources
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubeCPUOvercommit {
							{
								alert: "KubeQuotaFullyUsed"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesResources != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesResources
									}
								}
								expr: """
									kube_resourcequota{job="\(kubeStateMetricsJob)", type="used"}
									          / ignoring(instance, job, type)
									        (kube_resourcequota{job="\(kubeStateMetricsJob)", type="hard"} > 0)
									          == 1
									"""
								for:  kps.customRules.KubeQuotaFullyUsed.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesResources != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesResources
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubeCPUOvercommit {
							{
								alert: "KubeQuotaExceeded"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesResources != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesResources
									}
								}
								expr: """
									kube_resourcequota{job="\(kubeStateMetricsJob)", type="used"}
									          / ignoring(instance, job, type)
									        (kube_resourcequota{job="\(kubeStateMetricsJob)", type="hard"} > 0)
									          > 1
									"""
								for:  kps.customRules.KubeQuotaExceeded.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesResources != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesResources
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubeCPUOvercommit {
							{
								alert: "CPUThrottlingHigh"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesResources != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesResources
									}
								}
								expr: """
									sum(increase(container_cpu_cfs_throttled_periods_total{container!="", }[5m])) by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster, container, pod, namespace)
									          /
									        sum(increase(container_cpu_cfs_periods_total{}[5m])) by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster, container, pod, namespace)
									          > ( 25 / 100 )
									"""
								for:  kps.customRules.CPUThrottlingHigh.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesResources != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesResources
									}
								}
							}
						},
					]
				},
			]
		}
	}

	// kubernetes-storage.yaml
	if true && true && kps.defaultRules.create && kps.defaultRules.rules.kubernetesStorage {
		let kubeStateMetricsJob = "\(fullname)-kube-state-metrics"
		"rule-kubernetes-storage": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "PrometheusRule"
			metadata: {
				name: (#KubePrometheusStackTruncatedName & {#name: "\(fullname)-kubernetes-storage"}).result
				namespace: promNamespace
				labels: amLabels & kps.defaultRules.labels & {
					app: chartName
				}
				if len(kps.defaultRules.annotations) > 0 {
					annotations: kps.defaultRules.annotations
				}
			}
			spec: groups: [
				{
					name: "kubernetes-storage"
					rules: [
						if !kps.defaultRules.disabled.KubePersistentVolumeFillingUp {
							{
								alert: "KubePersistentVolumeFillingUp"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesStorage != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesStorage
									}
								}
								expr: """
									(
									          kubelet_volume_stats_available_bytes{job="kubelet", namespace=~"\(promNamespace)", metrics_path="/metrics"}
									            /
									          kubelet_volume_stats_capacity_bytes{job="kubelet", namespace=~"\(promNamespace)", metrics_path="/metrics"}
									        ) < 0.03
									        and
									        kubelet_volume_stats_used_bytes{job="kubelet", namespace=~"\(promNamespace)", metrics_path="/metrics"} > 0
									        unless on (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster, namespace, persistentvolumeclaim)
									        kube_persistentvolumeclaim_access_mode{ access_mode="ReadOnlyMany"} == 1
									        unless on (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster, namespace, persistentvolumeclaim)
									        kube_persistentvolumeclaim_labels{label_excluded_from_alerts="true"} == 1
									"""
								for:  kps.customRules.KubePersistentVolumeFillingUp.for | *"1m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesStorage != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesStorage
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubePersistentVolumeFillingUp {
							{
								alert: "KubePersistentVolumeFillingUp"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesStorage != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesStorage
									}
								}
								expr: """
									(
									          kubelet_volume_stats_available_bytes{job="kubelet", namespace=~"\(promNamespace)", metrics_path="/metrics"}
									            /
									          kubelet_volume_stats_capacity_bytes{job="kubelet", namespace=~"\(promNamespace)", metrics_path="/metrics"}
									        ) < 0.15
									        and
									        kubelet_volume_stats_used_bytes{job="kubelet", namespace=~"\(promNamespace)", metrics_path="/metrics"} > 0
									        and
									        predict_linear(kubelet_volume_stats_available_bytes{job="kubelet", namespace=~"\(promNamespace)", metrics_path="/metrics"}[6h], 4 * 24 * 3600) < 0
									        unless on (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster, namespace, persistentvolumeclaim)
									        kube_persistentvolumeclaim_access_mode{ access_mode="ReadOnlyMany"} == 1
									        unless on (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster, namespace, persistentvolumeclaim)
									        kube_persistentvolumeclaim_labels{label_excluded_from_alerts="true"} == 1
									"""
								for:  kps.customRules.KubePersistentVolumeFillingUp.for | *"1h"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesStorage != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesStorage
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubePersistentVolumeFillingUp {
							{
								alert: "KubePersistentVolumeInodesFillingUp"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesStorage != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesStorage
									}
								}
								expr: """
									(
									          kubelet_volume_stats_inodes_free{job="kubelet", namespace=~"\(promNamespace)", metrics_path="/metrics"}
									            /
									          kubelet_volume_stats_inodes{job="kubelet", namespace=~"\(promNamespace)", metrics_path="/metrics"}
									        ) < 0.03
									        and
									        kubelet_volume_stats_inodes_used{job="kubelet", namespace=~"\(promNamespace)", metrics_path="/metrics"} > 0
									        unless on (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster, namespace, persistentvolumeclaim)
									        kube_persistentvolumeclaim_access_mode{ access_mode="ReadOnlyMany"} == 1
									        unless on (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster, namespace, persistentvolumeclaim)
									        kube_persistentvolumeclaim_labels{label_excluded_from_alerts="true"} == 1
									"""
								for:  kps.customRules.KubePersistentVolumeInodesFillingUp.for | *"1m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesStorage != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesStorage
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubePersistentVolumeFillingUp {
							{
								alert: "KubePersistentVolumeInodesFillingUp"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesStorage != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesStorage
									}
								}
								expr: """
									(
									          kubelet_volume_stats_inodes_free{job="kubelet", namespace=~"\(promNamespace)", metrics_path="/metrics"}
									            /
									          kubelet_volume_stats_inodes{job="kubelet", namespace=~"\(promNamespace)", metrics_path="/metrics"}
									        ) < 0.15
									        and
									        kubelet_volume_stats_inodes_used{job="kubelet", namespace=~"\(promNamespace)", metrics_path="/metrics"} > 0
									        and
									        predict_linear(kubelet_volume_stats_inodes_free{job="kubelet", namespace=~"\(promNamespace)", metrics_path="/metrics"}[6h], 4 * 24 * 3600) < 0
									        unless on (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster, namespace, persistentvolumeclaim)
									        kube_persistentvolumeclaim_access_mode{ access_mode="ReadOnlyMany"} == 1
									        unless on (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster, namespace, persistentvolumeclaim)
									        kube_persistentvolumeclaim_labels{label_excluded_from_alerts="true"} == 1
									"""
								for:  kps.customRules.KubePersistentVolumeInodesFillingUp.for | *"1h"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesStorage != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesStorage
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubePersistentVolumeFillingUp {
							{
								alert: "KubePersistentVolumeErrors"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesStorage != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesStorage
									}
								}
								expr: """
									kube_persistentvolume_status_phase{phase=~"Failed|Pending",job="\(kubeStateMetricsJob)"} > 0
									"""
								for:  kps.customRules.KubePersistentVolumeErrors.for | *"5m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesStorage != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesStorage
									}
								}
							}
						},
					]
				},
			]
		}
	}

	// kubernetes-system-apiserver.yaml
	if true && true && kps.defaultRules.create && kps.defaultRules.rules.kubernetesSystem {
		"rule-kubernetes-system-apiserver": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "PrometheusRule"
			metadata: {
				name: (#KubePrometheusStackTruncatedName & {#name: "\(fullname)-kubernetes-system-apiserver"}).result
				namespace: promNamespace
				labels: amLabels & kps.defaultRules.labels & {
					app: chartName
				}
				if len(kps.defaultRules.annotations) > 0 {
					annotations: kps.defaultRules.annotations
				}
			}
			spec: groups: [
				{
					name: "kubernetes-system-apiserver"
					rules: [
						if !kps.defaultRules.disabled.KubeClientCertificateExpiration {
							{
								alert: "KubeClientCertificateExpiration"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesSystem != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesSystem
									}
								}
								expr: """
									apiserver_client_certificate_expiration_seconds_count{job="apiserver"} > 0 and on (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster, job) histogram_quantile(0.01, sum by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster, job, le) (rate(apiserver_client_certificate_expiration_seconds_bucket{job="apiserver"}[5m]))) < 604800
									"""
								for:  kps.customRules.KubeClientCertificateExpiration.for | *"5m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesSystem != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesSystem
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubeClientCertificateExpiration {
							{
								alert: "KubeClientCertificateExpiration"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesSystem != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesSystem
									}
								}
								expr: """
									apiserver_client_certificate_expiration_seconds_count{job="apiserver"} > 0 and on (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster, job) histogram_quantile(0.01, sum by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster, job, le) (rate(apiserver_client_certificate_expiration_seconds_bucket{job="apiserver"}[5m]))) < 86400
									"""
								for:  kps.customRules.KubeClientCertificateExpiration.for | *"5m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesSystem != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesSystem
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubeClientCertificateExpiration {
							{
								alert: "KubeAggregatedAPIErrors"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesSystem != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesSystem
									}
								}
								expr: """
									sum by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )name, namespace, cluster)(increase(aggregator_unavailable_apiservice_total{job="apiserver"}[10m])) > 4
									"""
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesSystem != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesSystem
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubeClientCertificateExpiration {
							{
								alert: "KubeAggregatedAPIDown"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesSystem != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesSystem
									}
								}
								expr: """
									(1 - max by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )name, namespace, cluster)(avg_over_time(aggregator_unavailable_apiservice{job="apiserver"}[10m]))) * 100 < 85
									"""
								for:  kps.customRules.KubeAggregatedAPIDown.for | *"5m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesSystem != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesSystem
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubeClientCertificateExpiration {
							{
								alert: "KubeAPIDown"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesSystem != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesSystem
									}
								}
								expr: """
									absent(up{job="apiserver"} == 1)
									"""
								for: kps.customRules.KubeAPIDown.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesSystem != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesSystem
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubeClientCertificateExpiration {
							{
								alert: "KubeAPITerminatedRequests"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesSystem != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesSystem
									}
								}
								expr: """
									sum by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster) (rate(apiserver_request_terminations_total{job="apiserver"}[10m])) / ( sum by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster) (rate(apiserver_request_total{job="apiserver"}[10m])) + sum by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster) (rate(apiserver_request_terminations_total{job="apiserver"}[10m])) ) > 0.20
									"""
								for:  kps.customRules.KubeAPITerminatedRequests.for | *"5m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesSystem != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesSystem
									}
								}
							}
						},
					]
				},
			]
		}
	}

	// kubernetes-system-controller-manager.yaml
	if true && true && kps.defaultRules.create && kps.kubeControllerManager.enabled && kps.defaultRules.rules.kubeControllerManager {
		"rule-kubernetes-system-controller-manager": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "PrometheusRule"
			metadata: {
				name: (#KubePrometheusStackTruncatedName & {#name: "\(fullname)-kubernetes-system-controller-manager"}).result
				namespace: promNamespace
				labels: amLabels & kps.defaultRules.labels & {
					app: chartName
				}
				if len(kps.defaultRules.annotations) > 0 {
					annotations: kps.defaultRules.annotations
				}
			}
			spec: groups: [
				{
					name: "kubernetes-system-controller-manager"
					rules: [
						if !kps.defaultRules.disabled.KubeControllerManagerDown {
							{
								alert: "KubeControllerManagerDown"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubeControllerManager != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubeControllerManager
									}
								}
								expr: """
									absent(up{job="kube-controller-manager"} == 1)
									"""
								for: kps.customRules.KubeControllerManagerDown.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubeControllerManager != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubeControllerManager
									}
								}
							}
						},
					]
				},
			]
		}
	}

	// kubernetes-system-kube-proxy.yaml
	if true && true && kps.defaultRules.create && kps.kubeProxy.enabled && kps.defaultRules.rules.kubeProxy {
		"rule-kubernetes-system-kube-proxy": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "PrometheusRule"
			metadata: {
				name: (#KubePrometheusStackTruncatedName & {#name: "\(fullname)-kubernetes-system-kube-proxy"}).result
				namespace: promNamespace
				labels: amLabels & kps.defaultRules.labels & {
					app: chartName
				}
				if len(kps.defaultRules.annotations) > 0 {
					annotations: kps.defaultRules.annotations
				}
			}
			spec: groups: [
				{
					name: "kubernetes-system-kube-proxy"
					rules: [
						if !kps.defaultRules.disabled.KubeProxyDown {
							{
								alert: "KubeProxyDown"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubeProxy != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubeProxy
									}
								}
								expr: """
									absent(up{job="kube-proxy"} == 1)
									"""
								for: kps.customRules.KubeProxyDown.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubeProxy != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubeProxy
									}
								}
							}
						},
					]
				},
			]
		}
	}

	// kubernetes-system-kubelet.yaml
	if true && true && kps.defaultRules.create && kps.defaultRules.rules.kubernetesSystem {
		let kubeStateMetricsJob = "\(fullname)-kube-state-metrics"
		"rule-kubernetes-system-kubelet": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "PrometheusRule"
			metadata: {
				name: (#KubePrometheusStackTruncatedName & {#name: "\(fullname)-kubernetes-system-kubelet"}).result
				namespace: promNamespace
				labels: amLabels & kps.defaultRules.labels & {
					app: chartName
				}
				if len(kps.defaultRules.annotations) > 0 {
					annotations: kps.defaultRules.annotations
				}
			}
			spec: groups: [
				{
					name: "kubernetes-system-kubelet"
					rules: [
						if !kps.defaultRules.disabled.KubeNodeNotReady {
							{
								alert: "KubeNodeNotReady"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesSystem != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesSystem
									}
								}
								expr: """
									kube_node_status_condition{job="\(kubeStateMetricsJob)",condition="Ready",status="true"} == 0
									"""
								for:  kps.customRules.KubeNodeNotReady.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesSystem != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesSystem
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubeNodeNotReady {
							{
								alert: "KubeNodeUnreachable"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesSystem != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesSystem
									}
								}
								expr: """
									(kube_node_spec_taint{job="\(kubeStateMetricsJob)",key="node.kubernetes.io/unreachable",effect="NoSchedule"} unless ignoring(key,value) kube_node_spec_taint{job="\(kubeStateMetricsJob)",key=~"ToBeDeletedByClusterAutoscaler|cloud.google.com/impending-node-termination|aws-node-termination-handler/spot-itn"}) == 1
									"""
								for:  kps.customRules.KubeNodeUnreachable.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesSystem != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesSystem
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubeNodeNotReady {
							{
								alert: "KubeletTooManyPods"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesSystem != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesSystem
									}
								}
								expr: """
									count by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster, node) (
									          (kube_pod_status_phase{job="\(kubeStateMetricsJob)",phase="Running"} == 1) * on (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )instance,pod,namespace,cluster) group_left(node) topk by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )instance,pod,namespace,cluster) (1, kube_pod_info{job="\(kubeStateMetricsJob)"})
									        )
									        /
									        max by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster, node) (
									          kube_node_status_capacity{job="\(kubeStateMetricsJob)",resource="pods"} != 1
									        ) > 0.95
									"""
								for:  kps.customRules.KubeletTooManyPods.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesSystem != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesSystem
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubeNodeNotReady {
							{
								alert: "KubeNodeReadinessFlapping"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesSystem != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesSystem
									}
								}
								expr: """
									sum(changes(kube_node_status_condition{job="\(kubeStateMetricsJob)",status="true",condition="Ready"}[15m])) by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster, node) > 2
									"""
								for:  kps.customRules.KubeNodeReadinessFlapping.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesSystem != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesSystem
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubeNodeNotReady {
							{
								alert: "KubeletPlegDurationHigh"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesSystem != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesSystem
									}
								}
								expr: """
									node_quantile:kubelet_pleg_relist_duration_seconds:histogram_quantile{quantile="0.99"} >= 10
									"""
								for: kps.customRules.KubeletPlegDurationHigh.for | *"5m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesSystem != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesSystem
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubeNodeNotReady {
							{
								alert: "KubeletPodStartUpLatencyHigh"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesSystem != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesSystem
									}
								}
								expr: """
									histogram_quantile(0.99, sum(rate(kubelet_pod_worker_duration_seconds_bucket{job="kubelet", metrics_path="/metrics"}[5m])) by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster, instance, le)) * on (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster, instance) group_left(node) kubelet_node_name{job="kubelet", metrics_path="/metrics"} > 60
									"""
								for:  kps.customRules.KubeletPodStartUpLatencyHigh.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesSystem != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesSystem
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubeNodeNotReady {
							{
								alert: "KubeletClientCertificateExpiration"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesSystem != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesSystem
									}
								}
								expr: """
									kubelet_certificate_manager_client_ttl_seconds < 604800
									"""
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesSystem != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesSystem
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubeNodeNotReady {
							{
								alert: "KubeletClientCertificateExpiration"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesSystem != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesSystem
									}
								}
								expr: """
									kubelet_certificate_manager_client_ttl_seconds < 86400
									"""
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesSystem != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesSystem
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubeNodeNotReady {
							{
								alert: "KubeletServerCertificateExpiration"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesSystem != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesSystem
									}
								}
								expr: """
									kubelet_certificate_manager_server_ttl_seconds < 604800
									"""
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesSystem != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesSystem
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubeNodeNotReady {
							{
								alert: "KubeletServerCertificateExpiration"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesSystem != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesSystem
									}
								}
								expr: """
									kubelet_certificate_manager_server_ttl_seconds < 86400
									"""
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesSystem != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesSystem
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubeNodeNotReady {
							{
								alert: "KubeletClientCertificateRenewalErrors"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesSystem != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesSystem
									}
								}
								expr: """
									increase(kubelet_certificate_manager_client_expiration_renew_errors[5m]) > 0
									"""
								for: kps.customRules.KubeletClientCertificateRenewalErrors.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesSystem != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesSystem
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubeNodeNotReady {
							{
								alert: "KubeletServerCertificateRenewalErrors"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesSystem != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesSystem
									}
								}
								expr: """
									increase(kubelet_server_expiration_renew_errors[5m]) > 0
									"""
								for: kps.customRules.KubeletServerCertificateRenewalErrors.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesSystem != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesSystem
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubeNodeNotReady {
							{
								alert: "KubeletDown"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesSystem != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesSystem
									}
								}
								expr: """
									absent(up{job="kubelet", metrics_path="/metrics"} == 1)
									"""
								for: kps.customRules.KubeletDown.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesSystem != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesSystem
									}
								}
							}
						},
					]
				},
			]
		}
	}

	// kubernetes-system-scheduler.yaml
	if true && true && kps.defaultRules.create && kps.kubeScheduler.enabled && kps.defaultRules.rules.kubeSchedulerAlerting {
		"rule-kubernetes-system-scheduler": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "PrometheusRule"
			metadata: {
				name: (#KubePrometheusStackTruncatedName & {#name: "\(fullname)-kubernetes-system-scheduler"}).result
				namespace: promNamespace
				labels: amLabels & kps.defaultRules.labels & {
					app: chartName
				}
				if len(kps.defaultRules.annotations) > 0 {
					annotations: kps.defaultRules.annotations
				}
			}
			spec: groups: [
				{
					name: "kubernetes-system-scheduler"
					rules: [
						if !kps.defaultRules.disabled.KubeSchedulerDown {
							{
								alert: "KubeSchedulerDown"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubeSchedulerAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubeSchedulerAlerting
									}
								}
								expr: """
									absent(up{job="kube-scheduler"} == 1)
									"""
								for: kps.customRules.KubeSchedulerDown.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubeSchedulerAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubeSchedulerAlerting
									}
								}
							}
						},
					]
				},
			]
		}
	}

	// kubernetes-system.yaml
	if true && true && kps.defaultRules.create && kps.defaultRules.rules.kubernetesSystem {
		"rule-kubernetes-system": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "PrometheusRule"
			metadata: {
				name: (#KubePrometheusStackTruncatedName & {#name: "\(fullname)-kubernetes-system"}).result
				namespace: promNamespace
				labels: amLabels & kps.defaultRules.labels & {
					app: chartName
				}
				if len(kps.defaultRules.annotations) > 0 {
					annotations: kps.defaultRules.annotations
				}
			}
			spec: groups: [
				{
					name: "kubernetes-system"
					rules: [
						if !kps.defaultRules.disabled.KubeVersionMismatch {
							{
								alert: "KubeVersionMismatch"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesSystem != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesSystem
									}
								}
								expr: """
									count by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster) (count by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )git_version, cluster) (label_replace(kubernetes_build_info{job!~"kube-dns|coredns"},"git_version","$1","git_version","(v[0-9]*.[0-9]*).*"))) > 1
									"""
								for:  kps.customRules.KubeVersionMismatch.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesSystem != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesSystem
									}
								}
							}
						},
						if !kps.defaultRules.disabled.KubeVersionMismatch {
							{
								alert: "KubeClientErrors"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.kubernetesSystem != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.kubernetesSystem
									}
								}
								expr: """
									(sum(rate(rest_client_requests_total{job="apiserver",code=~"5.."}[5m])) by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster, instance, job, namespace)
									          /
									        sum(rate(rest_client_requests_total{job="apiserver"}[5m])) by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster, instance, job, namespace))
									        > 0.01
									"""
								for:  kps.customRules.KubeClientErrors.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.kubernetesSystem != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.kubernetesSystem
									}
								}
							}
						},
					]
				},
			]
		}
	}

	// node-exporter.rules.yaml
	if true && true && kps.defaultRules.create && kps.defaultRules.rules.nodeExporterRecording {
		"rule-node-exporter-rules": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "PrometheusRule"
			metadata: {
				name: (#KubePrometheusStackTruncatedName & {#name: "\(fullname)-node-exporter.rules"}).result
				namespace: promNamespace
				labels: amLabels & kps.defaultRules.labels & {
					app: chartName
				}
				if len(kps.defaultRules.annotations) > 0 {
					annotations: kps.defaultRules.annotations
				}
			}
			spec: groups: [
				{
					name: "node-exporter.rules"
					rules: []
				},
			]
		}
	}

	// node-exporter.yaml
	if true && true && kps.defaultRules.create && kps.defaultRules.rules.nodeExporterAlerting {
		"rule-node-exporter": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "PrometheusRule"
			metadata: {
				name: (#KubePrometheusStackTruncatedName & {#name: "\(fullname)-node-exporter"}).result
				namespace: promNamespace
				labels: amLabels & kps.defaultRules.labels & {
					app: chartName
				}
				if len(kps.defaultRules.annotations) > 0 {
					annotations: kps.defaultRules.annotations
				}
			}
			spec: groups: [
				{
					name: "node-exporter"
					rules: [
						if !kps.defaultRules.disabled.NodeFilesystemSpaceFillingUp {
							{
								alert: "NodeFilesystemSpaceFillingUp"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting
									}
								}
								expr: """
									(
									          node_filesystem_avail_bytes{job="node-exporter",\(kps.defaultRules.node.fsSelector ),mountpoint!=""} / node_filesystem_size_bytes{job="node-exporter",\(kps.defaultRules.node.fsSelector ),mountpoint!=""} * 100 < 15
									        and
									          predict_linear(node_filesystem_avail_bytes{job="node-exporter",\(kps.defaultRules.node.fsSelector ),mountpoint!=""}[6h], 24*60*60) < 0
									        and
									          node_filesystem_readonly{job="node-exporter",\(kps.defaultRules.node.fsSelector ),mountpoint!=""} == 0
									        )
									"""
								for:  kps.customRules.NodeFilesystemSpaceFillingUp.for | *"1h"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting
									}
								}
							}
						},
						if !kps.defaultRules.disabled.NodeFilesystemSpaceFillingUp {
							{
								alert: "NodeFilesystemSpaceFillingUp"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting
									}
								}
								expr: """
									(
									          node_filesystem_avail_bytes{job="node-exporter",\(kps.defaultRules.node.fsSelector ),mountpoint!=""} / node_filesystem_size_bytes{job="node-exporter",\(kps.defaultRules.node.fsSelector ),mountpoint!=""} * 100 < 10
									        and
									          predict_linear(node_filesystem_avail_bytes{job="node-exporter",\(kps.defaultRules.node.fsSelector ),mountpoint!=""}[6h], 4*60*60) < 0
									        and
									          node_filesystem_readonly{job="node-exporter",\(kps.defaultRules.node.fsSelector ),mountpoint!=""} == 0
									        )
									"""
								for:  kps.customRules.NodeFilesystemSpaceFillingUp.for | *"1h"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting
									}
								}
							}
						},
						if !kps.defaultRules.disabled.NodeFilesystemSpaceFillingUp {
							{
								alert: "NodeFilesystemAlmostOutOfSpace"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting
									}
								}
								expr: """
									(
									          node_filesystem_avail_bytes{job="node-exporter",\(kps.defaultRules.node.fsSelector ),mountpoint!=""} / node_filesystem_size_bytes{job="node-exporter",\(kps.defaultRules.node.fsSelector ),mountpoint!=""} * 100 < 5
									        and
									          node_filesystem_readonly{job="node-exporter",\(kps.defaultRules.node.fsSelector ),mountpoint!=""} == 0
									        )
									"""
								for:  kps.customRules.NodeFilesystemAlmostOutOfSpace.for | *"30m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting
									}
								}
							}
						},
						if !kps.defaultRules.disabled.NodeFilesystemSpaceFillingUp {
							{
								alert: "NodeFilesystemAlmostOutOfSpace"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting
									}
								}
								expr: """
									(
									          node_filesystem_avail_bytes{job="node-exporter",\(kps.defaultRules.node.fsSelector ),mountpoint!=""} / node_filesystem_size_bytes{job="node-exporter",\(kps.defaultRules.node.fsSelector ),mountpoint!=""} * 100 < 3
									        and
									          node_filesystem_readonly{job="node-exporter",\(kps.defaultRules.node.fsSelector ),mountpoint!=""} == 0
									        )
									"""
								for:  kps.customRules.NodeFilesystemAlmostOutOfSpace.for | *"30m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting
									}
								}
							}
						},
						if !kps.defaultRules.disabled.NodeFilesystemSpaceFillingUp {
							{
								alert: "NodeFilesystemFilesFillingUp"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting
									}
								}
								expr: """
									(
									          node_filesystem_files_free{job="node-exporter",\(kps.defaultRules.node.fsSelector ),mountpoint!=""} / node_filesystem_files{job="node-exporter",\(kps.defaultRules.node.fsSelector ),mountpoint!=""} * 100 < 40
									        and
									          predict_linear(node_filesystem_files_free{job="node-exporter",\(kps.defaultRules.node.fsSelector ),mountpoint!=""}[6h], 24*60*60) < 0
									        and
									          node_filesystem_readonly{job="node-exporter",\(kps.defaultRules.node.fsSelector ),mountpoint!=""} == 0
									        )
									"""
								for:  kps.customRules.NodeFilesystemFilesFillingUp.for | *"1h"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting
									}
								}
							}
						},
						if !kps.defaultRules.disabled.NodeFilesystemSpaceFillingUp {
							{
								alert: "NodeFilesystemFilesFillingUp"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting
									}
								}
								expr: """
									(
									          node_filesystem_files_free{job="node-exporter",\(kps.defaultRules.node.fsSelector ),mountpoint!=""} / node_filesystem_files{job="node-exporter",\(kps.defaultRules.node.fsSelector ),mountpoint!=""} * 100 < 20
									        and
									          predict_linear(node_filesystem_files_free{job="node-exporter",\(kps.defaultRules.node.fsSelector ),mountpoint!=""}[6h], 4*60*60) < 0
									        and
									          node_filesystem_readonly{job="node-exporter",\(kps.defaultRules.node.fsSelector ),mountpoint!=""} == 0
									        )
									"""
								for:  kps.customRules.NodeFilesystemFilesFillingUp.for | *"1h"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting
									}
								}
							}
						},
						if !kps.defaultRules.disabled.NodeFilesystemSpaceFillingUp {
							{
								alert: "NodeFilesystemAlmostOutOfFiles"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting
									}
								}
								expr: """
									(
									          node_filesystem_files_free{job="node-exporter",\(kps.defaultRules.node.fsSelector ),mountpoint!=""} / node_filesystem_files{job="node-exporter",\(kps.defaultRules.node.fsSelector ),mountpoint!=""} * 100 < 5
									        and
									          node_filesystem_readonly{job="node-exporter",\(kps.defaultRules.node.fsSelector ),mountpoint!=""} == 0
									        )
									"""
								for:  kps.customRules.NodeFilesystemAlmostOutOfFiles.for | *"1h"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting
									}
								}
							}
						},
						if !kps.defaultRules.disabled.NodeFilesystemSpaceFillingUp {
							{
								alert: "NodeFilesystemAlmostOutOfFiles"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting
									}
								}
								expr: """
									(
									          node_filesystem_files_free{job="node-exporter",\(kps.defaultRules.node.fsSelector ),mountpoint!=""} / node_filesystem_files{job="node-exporter",\(kps.defaultRules.node.fsSelector ),mountpoint!=""} * 100 < 3
									        and
									          node_filesystem_readonly{job="node-exporter",\(kps.defaultRules.node.fsSelector ),mountpoint!=""} == 0
									        )
									"""
								for:  kps.customRules.NodeFilesystemAlmostOutOfFiles.for | *"1h"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting
									}
								}
							}
						},
						if !kps.defaultRules.disabled.NodeFilesystemSpaceFillingUp {
							{
								alert: "NodeNetworkReceiveErrs"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting
									}
								}
								expr: """
									rate(node_network_receive_errs_total{job="node-exporter"}[2m]) / rate(node_network_receive_packets_total{job="node-exporter"}[2m]) > 0.01
									"""
								for: kps.customRules.NodeNetworkReceiveErrs.for | *"1h"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting
									}
								}
							}
						},
						if !kps.defaultRules.disabled.NodeFilesystemSpaceFillingUp {
							{
								alert: "NodeNetworkTransmitErrs"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting
									}
								}
								expr: """
									rate(node_network_transmit_errs_total{job="node-exporter"}[2m]) / rate(node_network_transmit_packets_total{job="node-exporter"}[2m]) > 0.01
									"""
								for: kps.customRules.NodeNetworkTransmitErrs.for | *"1h"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting
									}
								}
							}
						},
						if !kps.defaultRules.disabled.NodeFilesystemSpaceFillingUp {
							{
								alert: "NodeHighNumberConntrackEntriesUsed"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting
									}
								}
								expr: """
									(node_nf_conntrack_entries{job="node-exporter"} / node_nf_conntrack_entries_limit) > 0.75
									"""
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting
									}
								}
							}
						},
						if !kps.defaultRules.disabled.NodeFilesystemSpaceFillingUp {
							{
								alert: "NodeTextFileCollectorScrapeError"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting
									}
								}
								expr: """
									node_textfile_scrape_error{job="node-exporter"} == 1
									"""
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting
									}
								}
							}
						},
						if !kps.defaultRules.disabled.NodeFilesystemSpaceFillingUp {
							{
								alert: "NodeClockSkewDetected"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting
									}
								}
								expr: """
									(
									          node_timex_offset_seconds{job="node-exporter"} > 0.05
									        and
									          deriv(node_timex_offset_seconds{job="node-exporter"}[5m]) >= 0
									        )
									        or
									        (
									          node_timex_offset_seconds{job="node-exporter"} < -0.05
									        and
									          deriv(node_timex_offset_seconds{job="node-exporter"}[5m]) <= 0
									        )
									"""
								for: kps.customRules.NodeClockSkewDetected.for | *"10m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting
									}
								}
							}
						},
						if !kps.defaultRules.disabled.NodeFilesystemSpaceFillingUp {
							{
								alert: "NodeClockNotSynchronising"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting
									}
								}
								expr: """
									min_over_time(node_timex_sync_status{job="node-exporter"}[5m]) == 0
									        and
									        node_timex_maxerror_seconds{job="node-exporter"} >= 16
									"""
								for: kps.customRules.NodeClockNotSynchronising.for | *"10m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting
									}
								}
							}
						},
						if !kps.defaultRules.disabled.NodeFilesystemSpaceFillingUp {
							{
								alert: "NodeRAIDDegraded"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting
									}
								}
								expr: """
									node_md_disks_required{job="node-exporter",device=~"(/dev/)?(mmcblk.p.+|nvme.+|rbd.+|sd.+|vd.+|xvd.+|dm-.+|md.+|dasd.+)"} - ignoring (state) (node_md_disks{state="active",job="node-exporter",device=~"(/dev/)?(mmcblk.p.+|nvme.+|rbd.+|sd.+|vd.+|xvd.+|dm-.+|md.+|dasd.+)"}) > 0
									"""
								for: kps.customRules.NodeRAIDDegraded.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting
									}
								}
							}
						},
						if !kps.defaultRules.disabled.NodeFilesystemSpaceFillingUp {
							{
								alert: "NodeRAIDDiskFailure"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting
									}
								}
								expr: """
									node_md_disks{state="failed",job="node-exporter",device=~"(/dev/)?(mmcblk.p.+|nvme.+|rbd.+|sd.+|vd.+|xvd.+|dm-.+|md.+|dasd.+)"} > 0
									"""
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting
									}
								}
							}
						},
						if !kps.defaultRules.disabled.NodeFilesystemSpaceFillingUp {
							{
								alert: "NodeFileDescriptorLimit"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting
									}
								}
								expr: """
									(
									          node_filefd_allocated{job="node-exporter"} * 100 / node_filefd_maximum{job="node-exporter"} > 70
									        )
									"""
								for: kps.customRules.NodeFileDescriptorLimit.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting
									}
								}
							}
						},
						if !kps.defaultRules.disabled.NodeFilesystemSpaceFillingUp {
							{
								alert: "NodeFileDescriptorLimit"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting
									}
								}
								expr: """
									(
									          node_filefd_allocated{job="node-exporter"} * 100 / node_filefd_maximum{job="node-exporter"} > 90
									        )
									"""
								for: kps.customRules.NodeFileDescriptorLimit.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting
									}
								}
							}
						},
						if !kps.defaultRules.disabled.NodeFilesystemSpaceFillingUp {
							{
								alert: "NodeCPUHighUsage"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting
									}
								}
								expr: """
									sum without(mode) (avg without (cpu) (rate(node_cpu_seconds_total{job="node-exporter", mode!="idle"}[2m]))) * 100 > 90
									"""
								for: kps.customRules.NodeCPUHighUsage.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting
									}
								}
							}
						},
						if !kps.defaultRules.disabled.NodeFilesystemSpaceFillingUp {
							{
								alert: "NodeSystemSaturation"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting
									}
								}
								expr: """
									node_load1{job="node-exporter"}
									        / count without (cpu, mode) (node_cpu_seconds_total{job="node-exporter", mode="idle"}) > 2
									"""
								for: kps.customRules.NodeSystemSaturation.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting
									}
								}
							}
						},
						if !kps.defaultRules.disabled.NodeFilesystemSpaceFillingUp {
							{
								alert: "NodeMemoryMajorPagesFaults"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting
									}
								}
								expr: """
									rate(node_vmstat_pgmajfault{job="node-exporter"}[5m]) > 500
									"""
								for: kps.customRules.NodeMemoryMajorPagesFaults.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting
									}
								}
							}
						},
						if !kps.defaultRules.disabled.NodeFilesystemSpaceFillingUp {
							{
								alert: "NodeMemoryHighUtilization"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting
									}
								}
								expr: """
									100 - (node_memory_MemAvailable_bytes{job="node-exporter"} / node_memory_MemTotal_bytes{job="node-exporter"} * 100) > 90
									"""
								for: kps.customRules.NodeMemoryHighUtilization.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting
									}
								}
							}
						},
						if !kps.defaultRules.disabled.NodeFilesystemSpaceFillingUp {
							{
								alert: "NodeDiskIOSaturation"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting
									}
								}
								expr: """
									rate(node_disk_io_time_weighted_seconds_total{job="node-exporter", device=~"(/dev/)?(mmcblk.p.+|nvme.+|rbd.+|sd.+|vd.+|xvd.+|dm-.+|md.+|dasd.+)"}[5m]) > 10
									"""
								for: kps.customRules.NodeDiskIOSaturation.for | *"30m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting
									}
								}
							}
						},
						if !kps.defaultRules.disabled.NodeFilesystemSpaceFillingUp {
							{
								alert: "NodeSystemdServiceFailed"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting
									}
								}
								expr: """
									node_systemd_unit_state{job="node-exporter", state="failed"} == 1
									"""
								for: kps.customRules.NodeSystemdServiceFailed.for | *"5m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting
									}
								}
							}
						},
						if !kps.defaultRules.disabled.NodeFilesystemSpaceFillingUp {
							{
								alert: "NodeBondingDegraded"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.nodeExporterAlerting
									}
								}
								expr: """
									(node_bonding_slaves - node_bonding_active) != 0
									"""
								for: kps.customRules.NodeBondingDegraded.for | *"5m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.nodeExporterAlerting
									}
								}
							}
						},
					]
				},
			]
		}
	}

	// node-network.yaml
	if true && true && kps.defaultRules.create && kps.defaultRules.rules.network {
		"rule-node-network": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "PrometheusRule"
			metadata: {
				name: (#KubePrometheusStackTruncatedName & {#name: "\(fullname)-node-network"}).result
				namespace: promNamespace
				labels: amLabels & kps.defaultRules.labels & {
					app: chartName
				}
				if len(kps.defaultRules.annotations) > 0 {
					annotations: kps.defaultRules.annotations
				}
			}
			spec: groups: [
				{
					name: "node-network"
					rules: [
						if !kps.defaultRules.disabled.NodeNetworkInterfaceFlapping {
							{
								alert: "NodeNetworkInterfaceFlapping"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.network != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.network
									}
								}
								expr: """
									changes(node_network_up{job="node-exporter",device!~"veth.+"}[2m]) > 2
									"""
								for: kps.customRules.NodeNetworkInterfaceFlapping.for | *"2m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.network != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.network
									}
								}
							}
						},
					]
				},
			]
		}
	}

	// node.rules.yaml
	if true && true && kps.defaultRules.create && kps.defaultRules.rules.node {
		"rule-node-rules": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "PrometheusRule"
			metadata: {
				name: (#KubePrometheusStackTruncatedName & {#name: "\(fullname)-node.rules"}).result
				namespace: promNamespace
				labels: amLabels & kps.defaultRules.labels & {
					app: chartName
				}
				if len(kps.defaultRules.annotations) > 0 {
					annotations: kps.defaultRules.annotations
				}
			}
			spec: groups: [
				{
					name: "node.rules"
					rules: []
				},
			]
		}
	}

	// prometheus-operator.yaml
	if true && true && kps.defaultRules.create && kps.defaultRules.rules.prometheusOperator {
		let operatorJob = "\(fullname)-operator"
		"rule-prometheus-operator": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "PrometheusRule"
			metadata: {
				name: (#KubePrometheusStackTruncatedName & {#name: "\(fullname)-prometheus-operator"}).result
				namespace: promNamespace
				labels: amLabels & kps.defaultRules.labels & {
					app: chartName
				}
				if len(kps.defaultRules.annotations) > 0 {
					annotations: kps.defaultRules.annotations
				}
			}
			spec: groups: [
				{
					name: "prometheus-operator"
					rules: [
						if !kps.defaultRules.disabled.PrometheusOperatorListErrors {
							{
								alert: "PrometheusOperatorListErrors"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.prometheusOperator != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.prometheusOperator
									}
								}
								expr: """
									(sum by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster,controller,namespace) (rate(prometheus_operator_list_operations_failed_total{job="\(operatorJob)",namespace="\(promNamespace)"}[10m])) / sum by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster,controller,namespace) (rate(prometheus_operator_list_operations_total{job="\(operatorJob)",namespace="\(promNamespace)"}[10m]))) > 0.4
									"""
								for:  kps.customRules.PrometheusOperatorListErrors.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.prometheusOperator != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.prometheusOperator
									}
								}
							}
						},
						if !kps.defaultRules.disabled.PrometheusOperatorListErrors {
							{
								alert: "PrometheusOperatorWatchErrors"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.prometheusOperator != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.prometheusOperator
									}
								}
								expr: """
									(sum by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster,controller,namespace) (rate(prometheus_operator_watch_operations_failed_total{job="\(operatorJob)",namespace="\(promNamespace)"}[5m])) / sum by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster,controller,namespace) (rate(prometheus_operator_watch_operations_total{job="\(operatorJob)",namespace="\(promNamespace)"}[5m]))) > 0.4
									"""
								for:  kps.customRules.PrometheusOperatorWatchErrors.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.prometheusOperator != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.prometheusOperator
									}
								}
							}
						},
						if !kps.defaultRules.disabled.PrometheusOperatorListErrors {
							{
								alert: "PrometheusOperatorSyncFailed"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.prometheusOperator != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.prometheusOperator
									}
								}
								expr: """
									min_over_time(prometheus_operator_syncs{status="failed",job="\(operatorJob)",namespace="\(promNamespace)"}[5m]) > 0
									"""
								for:  kps.customRules.PrometheusOperatorSyncFailed.for | *"10m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.prometheusOperator != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.prometheusOperator
									}
								}
							}
						},
						if !kps.defaultRules.disabled.PrometheusOperatorListErrors {
							{
								alert: "PrometheusOperatorReconcileErrors"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.prometheusOperator != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.prometheusOperator
									}
								}
								expr: """
									(sum by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster,controller,namespace) (rate(prometheus_operator_reconcile_errors_total{job="\(operatorJob)",namespace="\(promNamespace)"}[5m]))) / (sum by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster,controller,namespace) (rate(prometheus_operator_reconcile_operations_total{job="\(operatorJob)",namespace="\(promNamespace)"}[5m]))) > 0.1
									"""
								for:  kps.customRules.PrometheusOperatorReconcileErrors.for | *"10m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.prometheusOperator != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.prometheusOperator
									}
								}
							}
						},
						if !kps.defaultRules.disabled.PrometheusOperatorListErrors {
							{
								alert: "PrometheusOperatorStatusUpdateErrors"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.prometheusOperator != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.prometheusOperator
									}
								}
								expr: """
									(sum by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster,controller,namespace) (rate(prometheus_operator_status_update_errors_total{job="\(operatorJob)",namespace="\(promNamespace)"}[5m]))) / (sum by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster,controller,namespace) (rate(prometheus_operator_status_update_operations_total{job="\(operatorJob)",namespace="\(promNamespace)"}[5m]))) > 0.1
									"""
								for:  kps.customRules.PrometheusOperatorStatusUpdateErrors.for | *"10m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.prometheusOperator != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.prometheusOperator
									}
								}
							}
						},
						if !kps.defaultRules.disabled.PrometheusOperatorListErrors {
							{
								alert: "PrometheusOperatorNodeLookupErrors"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.prometheusOperator != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.prometheusOperator
									}
								}
								expr: """
									rate(prometheus_operator_node_address_lookup_errors_total{job="\(operatorJob)",namespace="\(promNamespace)"}[5m]) > 0.1
									"""
								for:  kps.customRules.PrometheusOperatorNodeLookupErrors.for | *"10m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.prometheusOperator != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.prometheusOperator
									}
								}
							}
						},
						if !kps.defaultRules.disabled.PrometheusOperatorListErrors {
							{
								alert: "PrometheusOperatorNotReady"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.prometheusOperator != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.prometheusOperator
									}
								}
								expr: """
									min by (\( [for l in kps.defaultRules.additionalAggregationLabels {l + ","}] )cluster,controller,namespace) (max_over_time(prometheus_operator_ready{job="\(operatorJob)",namespace="\(promNamespace)"}[5m]) == 0)
									"""
								for:  kps.customRules.PrometheusOperatorNotReady.for | *"5m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.prometheusOperator != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.prometheusOperator
									}
								}
							}
						},
						if !kps.defaultRules.disabled.PrometheusOperatorListErrors {
							{
								alert: "PrometheusOperatorRejectedResources"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.prometheusOperator != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.prometheusOperator
									}
								}
								expr: """
									min_over_time(prometheus_operator_managed_resources{state="rejected",job="\(operatorJob)",namespace="\(promNamespace)"}[5m]) > 0
									"""
								for:  kps.customRules.PrometheusOperatorRejectedResources.for | *"5m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.prometheusOperator != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.prometheusOperator
									}
								}
							}
						},
					]
				},
			]
		}
	}

	// prometheus.yaml
	if true && true && kps.defaultRules.create && kps.defaultRules.rules.prometheus {
		let prometheusJob = "\(fullname)-prometheus"
		"rule-prometheus": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "PrometheusRule"
			metadata: {
				name: (#KubePrometheusStackTruncatedName & {#name: "\(fullname)-prometheus"}).result
				namespace: promNamespace
				labels: amLabels & kps.defaultRules.labels & {
					app: chartName
				}
				if len(kps.defaultRules.annotations) > 0 {
					annotations: kps.defaultRules.annotations
				}
			}
			spec: groups: [
				{
					name: "prometheus"
					rules: [
						if !kps.defaultRules.disabled.PrometheusBadConfig {
							{
								alert: "PrometheusBadConfig"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.prometheus
									}
								}
								expr: """
									# Without max_over_time, failed scrapes could create false negatives, see
									        # https://www.robustperception.io/alerting-on-gauges-in-prometheus-2-0 for details.
									        max_over_time(prometheus_config_last_reload_successful{job="\(prometheusJob)",namespace="\(promNamespace)"}[5m]) == 0
									"""
								for:  kps.customRules.PrometheusBadConfig.for | *"10m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.prometheus
									}
								}
							}
						},
						if !kps.defaultRules.disabled.PrometheusBadConfig {
							{
								alert: "PrometheusSDRefreshFailure"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.prometheus
									}
								}
								expr: """
									increase(prometheus_sd_refresh_failures_total{job="\(prometheusJob)",namespace="\(promNamespace)"}[10m]) > 0
									"""
								for:  kps.customRules.PrometheusSDRefreshFailure.for | *"20m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.prometheus
									}
								}
							}
						},
						if !kps.defaultRules.disabled.PrometheusBadConfig {
							{
								alert: "PrometheusKubernetesListWatchFailures"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.prometheus
									}
								}
								expr: """
									increase(prometheus_sd_kubernetes_failures_total{job="\(prometheusJob)",namespace="\(promNamespace)"}[5m]) > 0
									"""
								for:  kps.customRules.PrometheusKubernetesListWatchFailures.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.prometheus
									}
								}
							}
						},
						if !kps.defaultRules.disabled.PrometheusBadConfig {
							{
								alert: "PrometheusNotificationQueueRunningFull"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.prometheus
									}
								}
								expr: """
									# Without min_over_time, failed scrapes could create false negatives, see
									        # https://www.robustperception.io/alerting-on-gauges-in-prometheus-2-0 for details.
									        (
									          predict_linear(prometheus_notifications_queue_length{job="\(prometheusJob)",namespace="\(promNamespace)"}[5m], 60 * 30)
									        >
									          min_over_time(prometheus_notifications_queue_capacity{job="\(prometheusJob)",namespace="\(promNamespace)"}[5m])
									        )
									"""
								for:  kps.customRules.PrometheusNotificationQueueRunningFull.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.prometheus
									}
								}
							}
						},
						if !kps.defaultRules.disabled.PrometheusBadConfig {
							{
								alert: "PrometheusErrorSendingAlertsToSomeAlertmanagers"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.prometheus
									}
								}
								expr: """
									(
									          rate(prometheus_notifications_errors_total{job="\(prometheusJob)",namespace="\(promNamespace)"}[5m])
									        /
									          rate(prometheus_notifications_sent_total{job="\(prometheusJob)",namespace="\(promNamespace)"}[5m])
									        )
									        * 100
									        > 1
									"""
								for:  kps.customRules.PrometheusErrorSendingAlertsToSomeAlertmanagers.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.prometheus
									}
								}
							}
						},
						if !kps.defaultRules.disabled.PrometheusBadConfig {
							{
								alert: "PrometheusNotConnectedToAlertmanagers"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.prometheus
									}
								}
								expr: """
									# Without max_over_time, failed scrapes could create false negatives, see
									        # https://www.robustperception.io/alerting-on-gauges-in-prometheus-2-0 for details.
									        max_over_time(prometheus_notifications_alertmanagers_discovered{job="\(prometheusJob)",namespace="\(promNamespace)"}[5m]) < 1
									"""
								for:  kps.customRules.PrometheusNotConnectedToAlertmanagers.for | *"10m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.prometheus
									}
								}
							}
						},
						if !kps.defaultRules.disabled.PrometheusBadConfig {
							{
								alert: "PrometheusTSDBReloadsFailing"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.prometheus
									}
								}
								expr: """
									increase(prometheus_tsdb_reloads_failures_total{job="\(prometheusJob)",namespace="\(promNamespace)"}[3h]) > 0
									"""
								for:  kps.customRules.PrometheusTSDBReloadsFailing.for | *"4h"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.prometheus
									}
								}
							}
						},
						if !kps.defaultRules.disabled.PrometheusBadConfig {
							{
								alert: "PrometheusTSDBCompactionsFailing"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.prometheus
									}
								}
								expr: """
									increase(prometheus_tsdb_compactions_failed_total{job="\(prometheusJob)",namespace="\(promNamespace)"}[3h]) > 0
									"""
								for:  kps.customRules.PrometheusTSDBCompactionsFailing.for | *"4h"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.prometheus
									}
								}
							}
						},
						if !kps.defaultRules.disabled.PrometheusBadConfig {
							{
								alert: "PrometheusNotIngestingSamples"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.prometheus
									}
								}
								expr: """
									(
									          sum without(type) (rate(prometheus_tsdb_head_samples_appended_total{job="\(prometheusJob)",namespace="\(promNamespace)"}[5m])) <= 0
									        and
									          (
									            sum without(scrape_job) (prometheus_target_metadata_cache_entries{job="\(prometheusJob)",namespace="\(promNamespace)"}) > 0
									          or
									            sum without(rule_group) (prometheus_rule_group_rules{job="\(prometheusJob)",namespace="\(promNamespace)"}) > 0
									          )
									        )
									"""
								for:  kps.customRules.PrometheusNotIngestingSamples.for | *"10m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.prometheus
									}
								}
							}
						},
						if !kps.defaultRules.disabled.PrometheusBadConfig {
							{
								alert: "PrometheusDuplicateTimestamps"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.prometheus
									}
								}
								expr: """
									rate(prometheus_target_scrapes_sample_duplicate_timestamp_total{job="\(prometheusJob)",namespace="\(promNamespace)"}[5m]) > 0
									"""
								for:  kps.customRules.PrometheusDuplicateTimestamps.for | *"10m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.prometheus
									}
								}
							}
						},
						if !kps.defaultRules.disabled.PrometheusBadConfig {
							{
								alert: "PrometheusOutOfOrderTimestamps"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.prometheus
									}
								}
								expr: """
									rate(prometheus_target_scrapes_sample_out_of_order_total{job="\(prometheusJob)",namespace="\(promNamespace)"}[5m]) > 0
									"""
								for:  kps.customRules.PrometheusOutOfOrderTimestamps.for | *"10m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.prometheus
									}
								}
							}
						},
						if !kps.defaultRules.disabled.PrometheusBadConfig {
							{
								alert: "PrometheusRemoteStorageFailures"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.prometheus
									}
								}
								expr: """
									(
									          (rate(prometheus_remote_storage_failed_samples_total{job="\(prometheusJob)",namespace="\(promNamespace)"}[5m]) or rate(prometheus_remote_storage_samples_failed_total{job="\(prometheusJob)",namespace="\(promNamespace)"}[5m]))
									        /
									          (
									            (rate(prometheus_remote_storage_failed_samples_total{job="\(prometheusJob)",namespace="\(promNamespace)"}[5m]) or rate(prometheus_remote_storage_samples_failed_total{job="\(prometheusJob)",namespace="\(promNamespace)"}[5m]))
									          +
									            (rate(prometheus_remote_storage_succeeded_samples_total{job="\(prometheusJob)",namespace="\(promNamespace)"}[5m]) or rate(prometheus_remote_storage_samples_total{job="\(prometheusJob)",namespace="\(promNamespace)"}[5m]))
									          )
									        )
									        * 100
									        > 1
									"""
								for:  kps.customRules.PrometheusRemoteStorageFailures.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.prometheus
									}
								}
							}
						},
						if !kps.defaultRules.disabled.PrometheusBadConfig {
							{
								alert: "PrometheusRemoteWriteBehind"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.prometheus
									}
								}
								expr: """
									# Without max_over_time, failed scrapes could create false negatives, see
									        # https://www.robustperception.io/alerting-on-gauges-in-prometheus-2-0 for details.
									        (
									          max_over_time(prometheus_remote_storage_highest_timestamp_in_seconds{job="\(prometheusJob)",namespace="\(promNamespace)"}[5m])
									        - ignoring(remote_name, url) group_right
									          max_over_time(prometheus_remote_storage_queue_highest_sent_timestamp_seconds{job="\(prometheusJob)",namespace="\(promNamespace)"}[5m])
									        )
									        > 120
									"""
								for:  kps.customRules.PrometheusRemoteWriteBehind.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.prometheus
									}
								}
							}
						},
						if !kps.defaultRules.disabled.PrometheusBadConfig {
							{
								alert: "PrometheusRemoteWriteDesiredShards"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.prometheus
									}
								}
								expr: """
									# Without max_over_time, failed scrapes could create false negatives, see
									        # https://www.robustperception.io/alerting-on-gauges-in-prometheus-2-0 for details.
									        (
									          max_over_time(prometheus_remote_storage_shards_desired{job="\(prometheusJob)",namespace="\(promNamespace)"}[5m])
									        >
									          max_over_time(prometheus_remote_storage_shards_max{job="\(prometheusJob)",namespace="\(promNamespace)"}[5m])
									        )
									"""
								for:  kps.customRules.PrometheusRemoteWriteDesiredShards.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.prometheus
									}
								}
							}
						},
						if !kps.defaultRules.disabled.PrometheusBadConfig {
							{
								alert: "PrometheusRuleFailures"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.prometheus
									}
								}
								expr: """
									increase(prometheus_rule_evaluation_failures_total{job="\(prometheusJob)",namespace="\(promNamespace)"}[5m]) > 0
									"""
								for:  kps.customRules.PrometheusRuleFailures.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.prometheus
									}
								}
							}
						},
						if !kps.defaultRules.disabled.PrometheusBadConfig {
							{
								alert: "PrometheusMissingRuleEvaluations"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.prometheus
									}
								}
								expr: """
									increase(prometheus_rule_group_iterations_missed_total{job="\(prometheusJob)",namespace="\(promNamespace)"}[5m]) > 0
									"""
								for:  kps.customRules.PrometheusMissingRuleEvaluations.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.prometheus
									}
								}
							}
						},
						if !kps.defaultRules.disabled.PrometheusBadConfig {
							{
								alert: "PrometheusTargetLimitHit"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.prometheus
									}
								}
								expr: """
									increase(prometheus_target_scrape_pool_exceeded_target_limit_total{job="\(prometheusJob)",namespace="\(promNamespace)"}[5m]) > 0
									"""
								for:  kps.customRules.PrometheusTargetLimitHit.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.prometheus
									}
								}
							}
						},
						if !kps.defaultRules.disabled.PrometheusBadConfig {
							{
								alert: "PrometheusLabelLimitHit"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.prometheus
									}
								}
								expr: """
									increase(prometheus_target_scrape_pool_exceeded_label_limits_total{job="\(prometheusJob)",namespace="\(promNamespace)"}[5m]) > 0
									"""
								for:  kps.customRules.PrometheusLabelLimitHit.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.prometheus
									}
								}
							}
						},
						if !kps.defaultRules.disabled.PrometheusBadConfig {
							{
								alert: "PrometheusScrapeBodySizeLimitHit"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.prometheus
									}
								}
								expr: """
									increase(prometheus_target_scrapes_exceeded_body_size_limit_total{job="\(prometheusJob)",namespace="\(promNamespace)"}[5m]) > 0
									"""
								for:  kps.customRules.PrometheusScrapeBodySizeLimitHit.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.prometheus
									}
								}
							}
						},
						if !kps.defaultRules.disabled.PrometheusBadConfig {
							{
								alert: "PrometheusScrapeSampleLimitHit"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.prometheus
									}
								}
								expr: """
									increase(prometheus_target_scrapes_exceeded_sample_limit_total{job="\(prometheusJob)",namespace="\(promNamespace)"}[5m]) > 0
									"""
								for:  kps.customRules.PrometheusScrapeSampleLimitHit.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.prometheus
									}
								}
							}
						},
						if !kps.defaultRules.disabled.PrometheusBadConfig {
							{
								alert: "PrometheusTargetSyncFailure"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.prometheus
									}
								}
								expr: """
									increase(prometheus_target_sync_failed_total{job="\(prometheusJob)",namespace="\(promNamespace)"}[30m]) > 0
									"""
								for:  kps.customRules.PrometheusTargetSyncFailure.for | *"5m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.prometheus
									}
								}
							}
						},
						if !kps.defaultRules.disabled.PrometheusBadConfig {
							{
								alert: "PrometheusHighQueryLoad"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.prometheus
									}
								}
								expr: """
									avg_over_time(prometheus_engine_queries{job="\(prometheusJob)",namespace="\(promNamespace)"}[5m]) / max_over_time(prometheus_engine_queries_concurrent_max{job="\(prometheusJob)",namespace="\(promNamespace)"}[5m]) > 0.8
									"""
								for:  kps.customRules.PrometheusHighQueryLoad.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.prometheus
									}
								}
							}
						},
						if !kps.defaultRules.disabled.PrometheusBadConfig {
							{
								alert: "PrometheusErrorSendingAlertsToAnyAlertmanager"
								annotations: {
									if len(kps.defaultRules.additionalRuleAnnotations) > 0 {
										kps.defaultRules.additionalRuleAnnotations
									}
									if kps.defaultRules.additionalRuleGroupAnnotations.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupAnnotations.prometheus
									}
								}
								expr: """
									min without (alertmanager) (
									          rate(prometheus_notifications_errors_total{job="\(prometheusJob)",namespace="\(promNamespace)",alertmanager!~``}[5m])
									        /
									          rate(prometheus_notifications_sent_total{job="\(prometheusJob)",namespace="\(promNamespace)",alertmanager!~``}[5m])
									        )
									        * 100
									        > 3
									"""
								for:  kps.customRules.PrometheusErrorSendingAlertsToAnyAlertmanager.for | *"15m"
								labels: {
									if len(kps.defaultRules.additionalRuleLabels) > 0 {
										kps.defaultRules.additionalRuleLabels
									}
									if kps.defaultRules.additionalRuleGroupLabels.prometheus != _|_ {
										kps.defaultRules.additionalRuleGroupLabels.prometheus
									}
								}
							}
						},
					]
				},
			]
		}
	}

	// windows.node.rules.yaml
	if true && true && kps.defaultRules.create && kps.windowsMonitoring.enabled && kps.defaultRules.rules.windows {
		"rule-windows-node-rules": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "PrometheusRule"
			metadata: {
				name: (#KubePrometheusStackTruncatedName & {#name: "\(fullname)-windows.node.rules"}).result
				namespace: promNamespace
				labels: amLabels & kps.defaultRules.labels & {
					app: chartName
				}
				if len(kps.defaultRules.annotations) > 0 {
					annotations: kps.defaultRules.annotations
				}
			}
			spec: groups: [
				{
					name: "windows.node.rules"
					rules: []
				},
			]
		}
	}

	// windows.pod.rules.yaml
	if true && true && kps.defaultRules.create && kps.windowsMonitoring.enabled && kps.defaultRules.rules.windows {
		"rule-windows-pod-rules": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "PrometheusRule"
			metadata: {
				name: (#KubePrometheusStackTruncatedName & {#name: "\(fullname)-windows.pod.rules"}).result
				namespace: promNamespace
				labels: amLabels & kps.defaultRules.labels & {
					app: chartName
				}
				if len(kps.defaultRules.annotations) > 0 {
					annotations: kps.defaultRules.annotations
				}
			}
			spec: groups: [
				{
					name: "windows.pod.rules"
					rules: []
				},
			]
		}
	}

}
