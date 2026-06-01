package templates

import (
	corev1 "k8s.io/api/core/v1"
	batchv1 "k8s.io/api/batch/v1"
	"strings"
)

#KafkaProvisioning: {
	#config: #Config
	let k = #config."hyperswitch-app".kafka
	let p = k.provisioning
	let fullname = "\(#config.metadata.name)-\(k.name)"

	_saName: *"" | string
	if p.serviceAccount.name != "" {_saName: p.serviceAccount.name}
	if p.serviceAccount.name == "" {_saName: "\(fullname)-provisioning"}

	let sslProtocol = strings.Contains(strings.ToUpper(k.listeners.client.protocol), "SSL")
	let sslType = strings.ToUpper(p.auth.tls.type)
	let saslProtocol = strings.Contains(strings.ToUpper(k.listeners.client.protocol), "SASL")
	let saslMechanisms = strings.ToUpper(k.saslEnabledMechanisms)

	_pemConfigCA:   """
		file_to_multiline_property() {
		    awk 'NR > 1{print line" \\\\"}{line=$0;}END{print $0" "}' <"${1:?missing file}"
		}
		kafka_common_conf_set "$CLIENT_CONF" ssl.keystore.key "$(file_to_multiline_property "/certs/\(p.auth.tls.key)")"
		kafka_common_conf_set "$CLIENT_CONF" ssl.keystore.certificate.chain "$(file_to_multiline_property "/certs/\(p.auth.tls.cert)")"
		kafka_common_conf_set "$CLIENT_CONF" ssl.truststore.certificates "$(file_to_multiline_property "/certs/\(p.auth.tls.caCert)")"
		"""
	_pemConfigNoCA: """
		kafka_common_conf_set "$CLIENT_CONF" ssl.keystore.location "/certs/\(p.auth.tls.keystore)"
		kafka_common_conf_set "$CLIENT_CONF" ssl.truststore.location "/certs/\(p.auth.tls.truststore)"
		"""
	_jksConfig:     """
		kafka_common_conf_set "$CLIENT_CONF" ssl.keystore.location "/certs/\(p.auth.tls.keystore)"
		kafka_common_conf_set "$CLIENT_CONF" ssl.truststore.location "/certs/\(p.auth.tls.truststore)"
		! is_empty_value "$KAFKA_CLIENT_KEYSTORE_PASSWORD" && kafka_common_conf_set "$CLIENT_CONF" ssl.keystore.password "$KAFKA_CLIENT_KEYSTORE_PASSWORD"
		! is_empty_value "$KAFKA_CLIENT_TRUSTSTORE_PASSWORD" && kafka_common_conf_set "$CLIENT_CONF" ssl.truststore.password "$KAFKA_CLIENT_TRUSTSTORE_PASSWORD"
		"""

	_sslConfigInternal: *"" | string
	if sslType == "PEM" {
		if p.auth.tls.caCert != "" {_sslConfigInternal: _pemConfigCA}
		if p.auth.tls.caCert == "" {_sslConfigInternal: _pemConfigNoCA}
	}
	if sslType == "JKS" {_sslConfigInternal: _jksConfig}

	_sslConfig: *"" | string
	if sslProtocol {
		_sslConfig: """
			kafka_common_conf_set "$CLIENT_CONF" ssl.keystore.type "\(sslType)"
			kafka_common_conf_set "$CLIENT_CONF" ssl.truststore.type "\(sslType)"
			! is_empty_value "$KAFKA_CLIENT_KEY_PASSWORD" && kafka_common_conf_set "$CLIENT_CONF" ssl.key.password "$KAFKA_CLIENT_KEY_PASSWORD"
			\(_sslConfigInternal)
			"""
	}

	_saslPlain: """
		kafka_common_conf_set "$CLIENT_CONF" sasl.mechanism PLAIN
		kafka_common_conf_set "$CLIENT_CONF" sasl.jaas.config "org.apache.kafka.common.security.plain.PlainLoginModule required username=\\"$SASL_USERNAME\\" password=\\"$SASL_USER_PASSWORD\\";"
		"""
	_saslScram: """
		kafka_common_conf_set "$CLIENT_CONF" sasl.mechanism SCRAM-SHA-256
		kafka_common_conf_set "$CLIENT_CONF" sasl.jaas.config "org.apache.kafka.common.security.scram.ScramLoginModule required username=\\"$SASL_USERNAME\\" password=\\"$SASL_USER_PASSWORD\\";"
		"""

	_saslConfig: *"" | string
	if saslProtocol {
		if strings.Contains(saslMechanisms, "PLAIN") {_saslConfig: _saslPlain}
		if strings.Contains(saslMechanisms, "SCRAM-SHA-256") {_saslConfig: _saslScram}
	}

	_topicsList: [
		for topic in p.topics {
			let rf = (topic.replicationFactor & int) | p.replicationFactor
			let pt = (topic.partitions & int) | p.numPartitions
			let cargsList = [
				for name, val in topic.config {"--config \(name)=\(val)"},
			]
			let cargs = strings.Join(cargsList, " ")
			"""
			"/opt/bitnami/kafka/bin/kafka-topics.sh \\
			    --create \\
			    --if-not-exists \\
			    --bootstrap-server ${KAFKA_SERVICE} \\
			    --replication-factor \(rf) \\
			    --partitions \(pt) \\
			    \(cargs) \\
			    --command-config ${CLIENT_CONF} \\
			    --topic \(topic.name)"
			"""
		},
	]
	_topicsScript: strings.Join(_topicsList, "\n")

	_extraCmdsList: [
		for cmd in p.extraProvisioningCommands {"\"\(cmd)\""},
	]
	_extraCmdsScript: strings.Join(_extraCmdsList, "\n")

	_provisioningScript: """
		echo "Configuring environment"
		. /opt/bitnami/scripts/libkafka.sh
		export CLIENT_CONF="${CLIENT_CONF:-/tmp/client.properties}"
		if [ ! -f "$CLIENT_CONF" ]; then
		  touch $CLIENT_CONF

		  kafka_common_conf_set "$CLIENT_CONF" security.protocol "\(k.listeners.client.protocol)"
		  \(_sslConfig)
		  \(_saslConfig)
		fi

		echo "Running pre-provisioning script if any given"
		\(p.preScript)

		kafka_provisioning_commands=(
		\(_topicsScript)
		\(_extraCmdsScript)
		)

		echo "Starting provisioning"
		for ((index=0; index < ${#kafka_provisioning_commands[@]}; index+=\(p.parallel)))
		do
		  for j in $(seq ${index} $((${index}+\(p.parallel)-1)))
		  do
		      ${kafka_provisioning_commands[j]} & # Async command
		  done
		  wait  # Wait the end of the jobs
		done

		echo "Running post-provisioning script if any given"
		\(p.postScript)

		echo "Provisioning succeeded"
		"""

	serviceAccount: corev1.#ServiceAccount & {
		apiVersion: "v1"
		kind:       "ServiceAccount"
		metadata: {
			name:      _saName
			namespace: #config.metadata.namespace
			labels: #config.metadata.labels & {
				"app.kubernetes.io/component": "kafka-provisioning"
				if k.commonLabels != _|_ {
					for key, val in k.commonLabels {"\(key)": val}
				}
			}
			if p.serviceAccount.annotations != _|_ {
				annotations: p.serviceAccount.annotations
			}
		}
		automountServiceAccountToken: p.serviceAccount.automountServiceAccountToken
	}

	tlsSecret: corev1.#Secret & {
		apiVersion: "v1"
		kind:       "Secret"
		metadata: {
			name:      "\(fullname)-client-passwords"
			namespace: #config.metadata.namespace
			labels: #config.metadata.labels & {
				"app.kubernetes.io/component": "kafka-provisioning"
				if k.commonLabels != _|_ {
					for key, val in k.commonLabels {"\(key)": val}
				}
			}
		}
		type: "Opaque"
		stringData: {
			"truststore-password": p.auth.tls.truststorePassword
			"keystore-password":   p.auth.tls.keystorePassword
			"key-password":        p.auth.tls.keyPassword
		}
	}

	job: batchv1.#Job & {
		apiVersion: "batch/v1"
		kind:       "Job"
		metadata: {
			name:      "\(fullname)-provisioning"
			namespace: #config.metadata.namespace
			labels: #config.metadata.labels & {
				"app.kubernetes.io/component": "kafka-provisioning"
				if k.commonLabels != _|_ {
					for key, val in k.commonLabels {"\(key)": val}
				}
			}
			annotations: {
				if p.useHelmHooks {
					"timoni.sh/hook": "post-install,post-upgrade"
				}
				if k.commonAnnotations != _|_ {
					for key, val in k.commonAnnotations {"\(key)": val}
				}
			}
		}
		spec: {
			template: {
				metadata: {
					labels: #config.metadata.labels & {
						"app.kubernetes.io/component": "kafka-provisioning"
						for key, val in p.podLabels {"\(key)": val}
						if k.commonLabels != _|_ {
							for key, val in k.commonLabels {"\(key)": val}
						}
					}
					if p.podAnnotations != _|_ {
						annotations: p.podAnnotations
					}
				}
				spec: {
					serviceAccountName:           _saName
					automountServiceAccountToken: p.automountServiceAccountToken
					enableServiceLinks:           p.enableServiceLinks
					if p.schedulerName != "" {
						schedulerName: p.schedulerName
					}
					if p.podSecurityContext.enabled {
						securityContext: {
							for sk, sv in p.podSecurityContext if sk != "enabled" {"\(sk)": sv}
						}
					}
					restartPolicy: "OnFailure"
					if p.nodeSelector != _|_ {
						nodeSelector: p.nodeSelector
					}
					if p.tolerations != _|_ {
						tolerations: p.tolerations
					}
					initContainers: [
						if p.waitForKafka {
							{
								name:            "wait-for-available-kafka"
								image:           "\(k.image.registry)/\(k.image.repository):\(k.image.tag)"
								imagePullPolicy: k.image.pullPolicy
								if p.containerSecurityContext.enabled {
									securityContext: {
										for sk, sv in p.containerSecurityContext if sk != "enabled" {"\(sk)": sv}
									}
								}
								command: ["/bin/bash"]
								args: [
									"-ec",
									"""
									wait-for-port \\
									  --host=\(fullname) \\
									  --state=inuse \\
									  --timeout=120 \\
									  \(k.service.ports.client);
									echo "Kafka is available";
									""",
								]
								if p.resources != _|_ {
									resources: p.resources
								}
							}
						},
						for ic in p.initContainers {ic},
					]
					containers: [
						{
							name:            "kafka-provisioning"
							image:           "\(k.image.registry)/\(k.image.repository):\(k.image.tag)"
							imagePullPolicy: k.image.pullPolicy
							if p.containerSecurityContext.enabled {
								securityContext: {
									for sk, sv in p.containerSecurityContext if sk != "enabled" {"\(sk)": sv}
								}
							}
							if len(p.command) > 0 {
								command: p.command
							}
							if len(p.command) == 0 {
								command: ["/bin/bash"]
							}
							if len(p.args) > 0 {
								args: p.args
							}
							if len(p.args) == 0 {
								args: [
									"-efc",
									_provisioningScript,
								]
							}
							env: [
								{name: "BITNAMI_DEBUG", value: "false"},
								if sslProtocol && p.auth.tls.passwordsSecret != "" {
									{
										name: "KAFKA_CLIENT_KEY_PASSWORD"
										valueFrom: secretKeyRef: {
											name: "\(fullname)-client-passwords"
											key:  p.auth.tls.keyPasswordSecretKey
										}
									}
								},
								if sslProtocol && p.auth.tls.passwordsSecret != "" {
									{
										name: "KAFKA_CLIENT_KEYSTORE_PASSWORD"
										valueFrom: secretKeyRef: {
											name: "\(fullname)-client-passwords"
											key:  p.auth.tls.keystorePasswordSecretKey
										}
									}
								},
								if sslProtocol && p.auth.tls.passwordsSecret != "" {
									{
										name: "KAFKA_CLIENT_TRUSTSTORE_PASSWORD"
										valueFrom: secretKeyRef: {
											name: "\(fullname)-client-passwords"
											key:  p.auth.tls.truststorePasswordSecretKey
										}
									}
								},
								{name: "KAFKA_SERVICE", value: "\(fullname):\(k.service.ports.client)"},
								if saslProtocol {
									{
										name:  "SASL_USERNAME"
										value: k.sasl.client.users[0]
									}
								},
								if saslProtocol {
									{
										name: "SASL_USER_PASSWORD"
										valueFrom: secretKeyRef: {
											name: "\(fullname)-user-passwords"
											key:  "system-user-password"
										}
									}
								},
								for e in p.extraEnvVars {e},
							]
							if p.extraEnvVarsCM != "" || p.extraEnvVarsSecret != "" {
								envFrom: [
									if p.extraEnvVarsCM != "" {
										{configMapRef: {name: p.extraEnvVarsCM}}
									},
									if p.extraEnvVarsSecret != "" {
										{secretRef: {name: p.extraEnvVarsSecret}}
									},
								]
							}
							if p.resources != _|_ {
								resources: p.resources
							}
							volumeMounts: [
								{name: "tmp", mountPath: "/tmp"},
								if sslProtocol && p.auth.tls.certificatesSecret != "" {
									{
										name:      "kafka-client-certs"
										mountPath: "/certs"
										readOnly:  true
									}
								},
								for vm in p.extraVolumeMounts {vm},
							]
						},
						for s in p.sidecars {s},
					]
					volumes: [
						{name: "tmp", emptyDir: {}},
						if sslProtocol && p.auth.tls.certificatesSecret != "" {
							{
								name: "kafka-client-certs"
								secret: {
									secretName:  p.auth.tls.certificatesSecret
									defaultMode: 256
								}
							}
						},
						for v in p.extraVolumes {v},
					]
				}
			}
		}
	}
}
