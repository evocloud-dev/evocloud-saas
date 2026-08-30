package templates

import (
	corev1 "k8s.io/api/core/v1"
	netv1 "k8s.io/api/networking/v1"
)

// 1. /charts/kafka/templates/scripts-configmap.yaml
#KafkaScripts: corev1.#ConfigMap & {
	#config: #Config
	let k = #config."hyperswitch-app".kafka
	let globalAnn = *#config.metadata.annotations | {}
	let fullname = "\(#config.metadata.name)-kafka"
	let releaseNamespace = #config.metadata.namespace
	let clusterDomain = k.clusterDomain

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(fullname)-scripts"
		namespace: releaseNamespace
		labels: {
			for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
			"app.kubernetes.io/name": "kafka"
		}
		annotations: (#MergeAnnotations & {#global: globalAnn, #local: k.commonAnnotations}).#result
	}
	data: {
		"auto-discovery.sh": """
			#!/bin/bash
			SVC_NAME=\"${MY_POD_NAME}-external\"
			AUTODISCOVERY_SERVICE_TYPE=\"${AUTODISCOVERY_SERVICE_TYPE:-}\"
			# Auxiliary functions
			retry_while() {
			    local -r cmd=\"${1:?cmd is missing}\"
			    local -r retries=\"${2:-12}\"
			    local -r sleep_time=\"${3:-5}\"
			    local return_value=1

			    read -r -a command <<< \"$cmd\"
			    for ((i = 1 ; i <= retries ; i+=1 )); do
			        \"${command[@]}\" && return_value=0 && break
			        sleep \"$sleep_time\"
			    done
			    return $return_value
			}
			k8s_svc_lb_ip() {
			    local namespace=${1:?namespace is missing}
			    local service=${2:?service is missing}
			    local service_ip=$(kubectl get svc \"$service\" -n \"$namespace\" -o jsonpath=\"{.status.loadBalancer.ingress[0].ip}\")
			    local service_hostname=$(kubectl get svc \"$service\" -n \"$namespace\" -o jsonpath=\"{.status.loadBalancer.ingress[0].hostname}\")

			    if [[ -n ${service_ip} ]]; then
			        echo \"${service_ip}\"
			    else
			        echo \"${service_hostname}\"
			    fi
			}
			k8s_svc_lb_ip_ready() {
			    local namespace=${1:?namespace is missing}
			    local service=${2:?service is missing}
			    [[ -n \"$(k8s_svc_lb_ip \"$namespace\" \"$service\")\" ]]
			}
			k8s_svc_node_port() {
			    local namespace=${1:?namespace is missing}
			    local service=${2:?service is missing}
			    local index=${3:-0}
			    local node_port=\"$(kubectl get svc \"$service\" -n \"$namespace\" -o jsonpath=\"{.spec.ports[$index].nodePort}\")\"
			    echo \"$node_port\"
			}

			if [[ \"$AUTODISCOVERY_SERVICE_TYPE\" = \"LoadBalancer\" ]]; then
			  # Wait until LoadBalancer IP is ready
			  retry_while \"k8s_svc_lb_ip_ready \(releaseNamespace) $SVC_NAME\" || exit 1
			  # Obtain LoadBalancer external IP
			  k8s_svc_lb_ip \"\(releaseNamespace)\" \"$SVC_NAME\" | tee \"/shared/external-host.txt\"
			elif [[ \"$AUTODISCOVERY_SERVICE_TYPE\" = \"NodePort\" ]]; then
			  k8s_svc_node_port \"\(releaseNamespace)\" \"$SVC_NAME\" | tee \"/shared/external-port.txt\"
			else
			  echo \"Unsupported autodiscovery service type: '$AUTODISCOVERY_SERVICE_TYPE'\"
			  exit 1
			fi
			"""

		"kafka-init.sh": """
			#!/bin/bash

			set -o errexit
			set -o nounset
			set -o pipefail

			error(){
			  local message=\"${1:?missing message}\"
			  echo \"ERROR: ${message}\"
			  exit 1
			}

			retry_while() {
			    local -r cmd=\"${1:?cmd is missing}\"
			    local -r retries=\"${2:-12}\"
			    local -r sleep_time=\"${3:-5}\"
			    local return_value=1

			    read -r -a command <<< \"$cmd\"
			    for ((i = 1 ; i <= retries ; i+=1 )); do
			        \"${command[@]}\" && return_value=0 && break
			        sleep \"$sleep_time\"
			    done
			    return $return_value
			}

			replace_in_file() {
			    local filename=\"${1:?filename is required}\"
			    local match_regex=\"${2:?match regex is required}\"
			    local substitute_regex=\"${3:?substitute regex is required}\"
			    local posix_regex=${4:-true}

			    local result

			    # We should avoid using 'sed in-place' substitutions
			    # 1) They are not compatible with files mounted from ConfigMap(s)
			    # 2) We found incompatibility issues with Debian10 and \"in-place\" substitutions
			    local -r del=$'\\001' # Use a non-printable character as a 'sed' delimiter to avoid issues
			    if [[ $posix_regex = true ]]; then
			        result=\"$(sed -E \"s${del}${match_regex}${del}${substitute_regex}${del}g\" \"$filename\")\"
			    else
			        result=\"$(sed \"s${del}${match_regex}${del}${substitute_regex}${del}g\" \"$filename\")\"
			    fi
			    echo \"$result\" > \"$filename\"
			}

			kafka_conf_set() {
			    local file=\"${1:?missing file}\"
			    local key=\"${2:?missing key}\"
			    local value=\"${3:?missing value}\"

			    # Check if the value was set before
			    if grep -q \"^[#\\\\s]*$key\\s*=.*\" \"$file\"; then
			        # Update the existing key
			        replace_in_file \"$file\" \"^[#\\\\s]*${key}\\s*=.*\" \"${key}=${value}\" false
			    else
			        # Add a new key
			        printf '\\n%s=%s' \"$key\" \"$value\" >>\"$file\"
			    fi
			}

			replace_placeholder() {
			  local placeholder=\"${1:?missing placeholder value}\"
			  local password=\"${2:?missing password value}\"
			  local -r del=$'\\001' # Use a non-printable character as a 'sed' delimiter to avoid issues with delimiter symbols in sed string
			  sed -i \"s${del}$placeholder${del}$password${del}g\" \"$KAFKA_CONFIG_FILE\"
			}

			append_file_to_kafka_conf() {
			    local file=\"${1:?missing source file}\"
			    local conf=\"${2:?missing kafka conf file}\"

			    cat \"$1\" >> \"$2\"
			}

			configure_external_access() {
			  local host=\"\"
			  local port=\"\"
			  [[ -f /shared/external-host.txt ]] && host=$(cat /shared/external-host.txt)
			  [[ -f /shared/external-port.txt ]] && port=$(cat /shared/external-port.txt)

			  # Configure Kafka advertised listeners
			  sed -i -E \"s|^(advertised\\.listeners=\\S+)$|\\1,EXTERNAL://${host}:${port}|\" \"$KAFKA_CONFIG_FILE\"
			}

			configure_kafka_tls() {
			  # Remove previously existing keystores and certificates, if any
			  rm -f /certs/kafka.keystore.jks /certs/kafka.truststore.jks
			  rm -f /certs/tls.crt /certs/tls.key /certs/ca.crt
			  find /certs -name \"xx*\" -exec rm {} \\;
			  
			  # PEM Logic (Simplified for parity)
			  if [[ -f \"/mounted-certs/tls.crt\" && -f \"/mounted-certs/tls.key\" ]]; then
			    cp \"/mounted-certs/tls.crt\" /certs/tls.crt
			    openssl pkcs8 -topk8 -nocrypt -in \"/mounted-certs/tls.key\" > /certs/tls.key
			  fi

			  # Create JKS keystores
			  openssl pkcs12 -export -in \"/certs/tls.crt\" -inkey \"/certs/tls.key\" -out \"/certs/kafka.keystore.p12\" -passout pass:\"${KAFKA_TLS_KEYSTORE_PASSWORD}\"
			  keytool -importkeystore -srckeystore \"/certs/kafka.keystore.p12\" -srcstoretype PKCS12 -srcstorepass \"${KAFKA_TLS_KEYSTORE_PASSWORD}\" -destkeystore \"/certs/kafka.keystore.jks\" -deststorepass \"${KAFKA_TLS_KEYSTORE_PASSWORD}\" -noprompt
			  
			  # Configure TLS settings in server.properties
			  [[ -n \"${KAFKA_TLS_KEYSTORE_PASSWORD:-}\" ]] && kafka_conf_set \"$KAFKA_CONFIG_FILE\" \"ssl.keystore.password\" \"$KAFKA_TLS_KEYSTORE_PASSWORD\"
			  [[ -n \"${KAFKA_TLS_TRUSTSTORE_PASSWORD:-}\" ]] && kafka_conf_set \"$KAFKA_CONFIG_FILE\" \"ssl.truststore.password\" \"$KAFKA_TLS_TRUSTSTORE_PASSWORD\"
			}

			configure_zookeeper_tls() {
			  # Zookeeper TLS logic
			  rm -f /certs/zookeeper.keystore.jks /certs/zookeeper.truststore.jks
			  if [[ -f \"/zookeeper-certs/keystore.jks\" ]]; then
			    cp \"/zookeeper-certs/keystore.jks\" /certs/zookeeper.keystore.jks
			  fi
			  [[ -n \"${KAFKA_ZOOKEEPER_TLS_KEYSTORE_PASSWORD:-}\" ]] && kafka_conf_set \"$KAFKA_CONFIG_FILE\" \"zookeeper.ssl.keystore.password\" \"${KAFKA_ZOOKEEPER_TLS_KEYSTORE_PASSWORD}\"
			}

			configure_kafka_sasl() {
			  # Replace placeholders with passwords
			  replace_placeholder \"interbroker-password-placeholder\" \"$KAFKA_INTER_BROKER_PASSWORD\"
			  replace_placeholder \"interbroker-client-secret-placeholder\" \"$KAFKA_INTER_BROKER_CLIENT_SECRET\"
			  replace_placeholder \"controller-password-placeholder\" \"$KAFKA_CONTROLLER_PASSWORD\"
			  replace_placeholder \"controller-client-secret-placeholder\" \"$KAFKA_CONTROLLER_CLIENT_SECRET\"
			  
			  read -r -a passwords <<<\"$(tr ',;' ' ' <<<\"${KAFKA_CLIENT_PASSWORDS:-}\")\"
			  for ((i = 0; i < ${#passwords[@]}; i++)); do
			      replace_placeholder \"password-placeholder-${i}\\\"\" \"${passwords[i]}\\\"\"
			  done
			}

			# Wait for autodiscovery to finish
			if [[ \"${EXTERNAL_ACCESS_ENABLED:-false}\" =~ ^(yes|true)$ ]]; then
			  retry_while \"test -f /shared/external-host.txt -o -f /shared/external-port.txt\" || error \"Timed out waiting for autodiscovery init-container\"
			fi

			export KAFKA_CONFIG_FILE=/config/server.properties
			cp /configmaps/server.properties $KAFKA_CONFIG_FILE

			# Get pod ID and role
			POD_ID=$(echo \"$MY_POD_NAME\" | rev | cut -d'-' -f 1 | rev)
			POD_ROLE=$(echo \"$MY_POD_NAME\" | rev | cut -d'-' -f 2 | rev)

			# Configure node.id and/or broker.id
			if [[ -f \"/bitnami/kafka/data/meta.properties\" ]]; then
			    if grep -q \"broker.id\" /bitnami/kafka/data/meta.properties; then
			      ID=\"$(grep \"broker.id\" /bitnami/kafka/data/meta.properties | awk -F '=' '{print $2}')\"
			      if [[ \"${KRAFT_ENABLED:-false}\" == \"true\" ]]; then
			        kafka_conf_set \"$KAFKA_CONFIG_FILE\" \"node.id\" \"$ID\"
			      else
			        kafka_conf_set \"$KAFKA_CONFIG_FILE\" \"broker.id\" \"$ID\"
			      fi
			    else
			      ID=\"$(grep \"node.id\" /bitnami/kafka/data/meta.properties | awk -F '=' '{print $2}')\"
			      kafka_conf_set \"$KAFKA_CONFIG_FILE\" \"node.id\" \"$ID\"
			    fi
			else
			    ID=$((POD_ID + KAFKA_MIN_ID))
			    if [[ \"${KRAFT_ENABLED:-false}\" == \"true\" ]]; then
			      kafka_conf_set \"$KAFKA_CONFIG_FILE\" \"node.id\" \"$ID\"
			    fi
			    if [[ \"${ZOOKEEPER_ENABLED:-false}\" == \"true\" ]]; then
			      kafka_conf_set \"$KAFKA_CONFIG_FILE\" \"broker.id\" \"$ID\"
			    fi
			fi

			replace_placeholder \"advertised-address-placeholder\" \"${MY_POD_NAME}.\(fullname)-${POD_ROLE}-headless.\(releaseNamespace).svc.\(clusterDomain)\"
			if [[ \"${EXTERNAL_ACCESS_ENABLED:-false}\" =~ ^(yes|true)$ ]]; then
			  configure_external_access
			fi

			if [[ \"${SASL_ENABLED:-false}\" == \"true\" ]]; then
			  configure_kafka_sasl
			fi

			if [[ \"${TLS_ENABLED:-false}\" == \"true\" ]]; then
			  configure_kafka_tls
			fi

			if [[ \"${ZOOKEEPER_TLS_ENABLED:-false}\" == \"true\" ]]; then
			  configure_zookeeper_tls
			fi

			# AWS Rack Awareness
			if [[ \"${RACK_AWARENESS_TYPE:-}\" == \"aws-az\" ]]; then
			    EC2_METADATA_TOKEN=$(curl -X PUT \"http://169.254.169.254/latest/api/token\" -H \"X-aws-ec2-metadata-token-ttl-seconds: 60\")
			    BROKER_RACK=$(curl -H \"X-aws-ec2-metadata-token: $EC2_METADATA_TOKEN\" \"http://169.254.169.254/latest/meta-data/placement/availability-zone-id\")
			    kafka_conf_set \"$KAFKA_CONFIG_FILE\" \"broker.rack\" \"$BROKER_RACK\"
			fi

			if [ -f /secret-config/server-secret.properties ]; then
			  append_file_to_kafka_conf /secret-config/server-secret.properties $KAFKA_CONFIG_FILE
			fi
			"""
	}
}

// 2. /charts/kafka/templates/secrets.yaml
#KafkaSecrets: {
	#config: #Config
	let k = #config."hyperswitch-app".kafka
	let globalAnn = *#config.metadata.annotations | {}

	// Main user passwords secret
	userPasswords: corev1.#Secret & {
		apiVersion: "v1"
		kind:       "Secret"
		metadata: {
			name:      "\(#config.metadata.name)-kafka-user-passwords"
			namespace: #config.metadata.namespace
			labels: {
				for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
				"app.kubernetes.io/name": "kafka"
			}
			annotations: (#MergeAnnotations & {#global: globalAnn, #local: k.commonAnnotations}).#result
		}
		type: "Opaque"
		stringData: {
			// SASL Client Passwords (Lines 19-38)
			if k.auth.clientProtocol == "sasl_plaintext" || k.auth.clientProtocol == "sasl_ssl" {
				if len(k.sasl.client.passwords) > 0 {
					"client-passwords": [for p in k.sasl.client.passwords {p}][0]
					"system-user-password": k.sasl.client.passwords[0]
				}
			}

			// Zookeeper Password (Lines 39-41)
			if k.sasl.zookeeper.user != "" || k.zookeeper.enabled {
				"zookeeper-password": k.sasl.zookeeper.password
			}

			// Inter-Broker Password (Lines 42-49)
			if k.auth.interBrokerProtocol == "sasl_plaintext" || k.auth.interBrokerProtocol == "sasl_ssl" {
				"inter-broker-password":      k.sasl.interbroker.password
				"inter-broker-client-secret": k.sasl.interbroker.password // Mapping both as per common.secrets.passwords.manage
			}

			// Controller Password (Lines 50-57)
			if k.auth.controllerProtocol == "sasl_plaintext" || k.auth.controllerProtocol == "sasl_ssl" {
				"controller-password":      k.sasl.controller.password
				"controller-client-secret": k.sasl.controller.password
			}
		}
	}

	// Service Bindings (Lines 58-116)
	serviceBindings: [
		for i, user in k.sasl.client.users {
			corev1.#Secret & {
				apiVersion: "v1"
				kind:       "Secret"
				metadata: {
					name:      "\(#config.metadata.name)-kafka-svcbind-user-\(i)"
					namespace: #config.metadata.namespace
					labels: {
						for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
						"app.kubernetes.io/name": "kafka"
					}
					annotations: (#MergeAnnotations & {#global: globalAnn, #local: k.commonAnnotations}).#result
				}
				type: "servicebinding.io/kafka"
				stringData: {
					provider: "bitnami"
					type:     "kafka"
					username: user
					if len(k.sasl.client.passwords) > i {
						password: k.sasl.client.passwords[i]
					}
					host:                "\(#config.metadata.name)-kafka-broker-headless"
					port:                "\(k.listeners.client.containerPort)"
					"bootstrap-servers": "\(#config.metadata.name)-kafka-broker-headless:\(k.listeners.client.containerPort)"
				}
			}
		},
	]

	// KRaft Cluster ID Secret (Lines 118-132)
	kraftClusterId: corev1.#Secret & {
		if k.kraft.enabled {
			apiVersion: "v1"
			kind:       "Secret"
			metadata: {
				name:      "\(#config.metadata.name)-kafka-kraft-cluster-id"
				namespace: #config.metadata.namespace
				labels: {
					for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
					"app.kubernetes.io/name": "kafka"
				}
				annotations: (#MergeAnnotations & {#global: globalAnn, #local: k.commonAnnotations}).#result
			}
			type: "Opaque"
			stringData: {
				"kraft-cluster-id": k.kraft.clusterId
			}
		}
	}
}

// 3. /charts/kafka/templates/log4j-configmap.yaml
#KafkaLog4jConfigMap: corev1.#ConfigMap & {
	#config: #Config
	let k = #config."hyperswitch-app".kafka
	let globalAnn = *#config.metadata.annotations | {}
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-kafka-log4j"
		namespace: #config.metadata.namespace
		labels: {
			for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
			"app.kubernetes.io/name":    "kafka"
			"app.kubernetes.io/part-of": "kafka"
		}
		annotations: (#MergeAnnotations & {#global: globalAnn, #local: k.commonAnnotations}).#result
	}
	data: {
		"log4j.properties": k.log4j
	}
}

// 4. /charts/kafka/templates/svc.yaml
#KafkaService: corev1.#Service & {
	#config: #Config
	let k = #config."hyperswitch-app".kafka
	let globalAnn = *#config.metadata.annotations | {}
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-kafka"
		namespace: #config.metadata.namespace
		labels: {
			for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
			"app.kubernetes.io/name":      "kafka"
			"app.kubernetes.io/component": "kafka"
		}
		annotations: (#MergeAnnotations & {#global: globalAnn, #local: k.service.annotations}).#result
	}
	spec: {
		type: k.service.type
		if k.service.clusterIP != _|_ && k.service.type == "ClusterIP" {
			clusterIP: k.service.clusterIP
		}
		if k.service.type == "LoadBalancer" || k.service.type == "NodePort" {
			if k.service.externalTrafficPolicy != _|_ {
				externalTrafficPolicy: k.service.externalTrafficPolicy
			}
		}
		if k.service.type == "LoadBalancer" {
			if k.service.allocateLoadBalancerNodePorts != _|_ {
				allocateLoadBalancerNodePorts: k.service.allocateLoadBalancerNodePorts
			}
			if k.service.loadBalancerClass != _|_ {
				loadBalancerClass: k.service.loadBalancerClass
			}
			if k.service.loadBalancerSourceRanges != [] {
				loadBalancerSourceRanges: k.service.loadBalancerSourceRanges
			}
			if k.service.loadBalancerIP != _|_ {
				loadBalancerIP: k.service.loadBalancerIP
			}
		}
		sessionAffinity: k.service.sessionAffinity
		if k.service.sessionAffinity != "None" {
			sessionAffinityConfig: k.service.sessionAffinityConfig
		}
		ports: [
			{
				name:       "tcp-client"
				port:       k.service.ports.client
				protocol:   "TCP"
				targetPort: "client"
				if (k.service.type == "NodePort" || k.service.type == "LoadBalancer") && k.service.nodePorts.client != _|_ {
					nodePort: k.service.nodePorts.client
				}
			},
			if k.externalAccess.enabled {
				{
					name:       "tcp-external"
					port:       k.service.ports.external
					protocol:   "TCP"
					targetPort: "external"
					if k.service.nodePorts.external != _|_ {
						nodePort: k.service.nodePorts.external
					}
				}
			},
			for p in k.service.extraPorts {p},
		]
		selector: {
			for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
			"app.kubernetes.io/part-of": "kafka"
			if k.kraft.enabled && k.controller.controllerOnly {
				"app.kubernetes.io/component": "broker"
			}
		}
	}
}

// 5. /charts/kafka/templates/networkpolicy.yaml
#KafkaNetworkPolicy: netv1.#NetworkPolicy & {
	#config: #Config
	let k = #config."hyperswitch-app".kafka
	let globalAnn = *#config.metadata.annotations | {}
	apiVersion: "networking.k8s.io/v1"
	kind:       "NetworkPolicy"
	metadata: {
		name:      "\(#config.metadata.name)-kafka"
		namespace: #config.metadata.namespace
		labels: {
			for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
			"app.kubernetes.io/name": "kafka"
		}
		annotations: (#MergeAnnotations & {#global: globalAnn, #local: k.commonAnnotations}).#result
	}
	spec: {
		podSelector: matchLabels: {
			"app.kubernetes.io/name":     "kafka"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		policyTypes: ["Ingress", "Egress"]

		// Egress Rules
		egress: [
			if k.networkPolicy.allowExternalEgress {
				{}
			},
			if !k.networkPolicy.allowExternalEgress {
				{
					// DNS Resolution
					ports: [
						{port: 53, protocol: "UDP"},
						{port: 53, protocol: "TCP"},
					]
				}
			},
			if !k.networkPolicy.allowExternalEgress {
				{
					// Internal Communications
					ports: [
						{port: k.listeners.client.containerPort},
						{port: k.listeners.interbroker.containerPort},
						{port: k.listeners.controller.containerPort},
						if k.externalAccess.enabled {
							{port: k.listeners.external.containerPort}
						},
					]
					to: [
						{
							podSelector: matchLabels: {
								"app.kubernetes.io/name":     "kafka"
								"app.kubernetes.io/instance": #config.metadata.name
							}
						},
					]
				}
			},
		]

		// Ingress Rules
		ingress: [
			{
				ports: [
					{port: k.listeners.client.containerPort},
					{port: k.listeners.interbroker.containerPort},
					{port: k.listeners.controller.containerPort},
					if k.externalAccess.enabled {
						{port: k.listeners.external.containerPort}
					},
					if k.metrics.jmx.enabled {
						{port: k.metrics.jmx.containerPorts.metrics}
					},
				]
				if !k.networkPolicy.allowExternal {
					from: [
						{
							podSelector: matchLabels: {
								"app.kubernetes.io/name":     "kafka"
								"app.kubernetes.io/instance": #config.metadata.name
							}
						},
						if k.networkPolicy.ingressPodMatchLabels != {} {
							{podSelector: matchLabels: k.networkPolicy.ingressPodMatchLabels}
						},
						if k.networkPolicy.ingressNSMatchLabels != {} {
							{
								namespaceSelector: matchLabels: k.networkPolicy.ingressNSMatchLabels
								if k.networkPolicy.ingressNSPodMatchLabels != {} {
									podSelector: matchLabels: k.networkPolicy.ingressNSPodMatchLabels
								}
							}
						},
					]
				}
			},
		]
	}
}

// 6. /charts/kafka/templates/tls-secret.yaml
#KafkaTLSSecret: corev1.#Secret & {
	#config: #Config
	let k = #config."hyperswitch-app".kafka
	let globalAnn = *#config.metadata.annotations | {}
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-kafka-tls"
		namespace: #config.metadata.namespace
		labels: {
			for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
			"app.kubernetes.io/name": "kafka"
		}
		annotations: (#MergeAnnotations & {#global: globalAnn, #local: k.commonAnnotations}).#result
	}
	type: "Opaque"
	stringData: {
		"kafka.crt":    ""
		"kafka.key":    ""
		"kafka-ca.crt": ""
	}
}

// TLS Passwords Secret
#KafkaTLSPasswordsSecret: corev1.#Secret & {
	#config: #Config
	let k = #config."hyperswitch-app".kafka
	let globalAnn = *#config.metadata.annotations | {}
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-kafka-tls-passwords"
		namespace: #config.metadata.namespace
		labels: {
			for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
			"app.kubernetes.io/name": "kafka"
		}
		annotations: (#MergeAnnotations & {#global: globalAnn, #local: k.commonAnnotations}).#result
	}
	type: "Opaque"
	stringData: {
		if k.tls.keystorePassword != _|_ {
			"\(k.tls.passwordsSecretKeystoreKey)": k.tls.keystorePassword
		}
		if k.tls.truststorePassword != _|_ {
			"\(k.tls.passwordsSecretTruststoreKey)": k.tls.truststorePassword
		}
		if k.tls.keyPassword != _|_ {
			"\(k.tls.passwordsSecretPemPasswordKey)": k.tls.keyPassword
		}
	}
}

// Zookeeper TLS Passwords Secret
#KafkaZookeeperTLSPasswordsSecret: corev1.#Secret & {
	#config: #Config
	let k = #config."hyperswitch-app".kafka
	let globalAnn = *#config.metadata.annotations | {}
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-kafka-zookeeper-tls-passwords"
		namespace: #config.metadata.namespace
		labels: {
			for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
			"app.kubernetes.io/name": "kafka"
		}
		annotations: (#MergeAnnotations & {#global: globalAnn, #local: k.commonAnnotations}).#result
	}
	type: "Opaque"
	stringData: {
		if k.tls.zookeeper.keystorePassword != _|_ {
			"\(k.tls.zookeeper.passwordsSecretKeystoreKey)": k.tls.zookeeper.keystorePassword
		}
		if k.tls.zookeeper.truststorePassword != _|_ {
			"\(k.tls.zookeeper.passwordsSecretTruststoreKey)": k.tls.zookeeper.truststorePassword
		}
	}
}

// 7. /charts/kafka/templates/rbac/
#KafkaRBAC: {
	#config: #Config
	let k = #config."hyperswitch-app".kafka
	let globalAnn = *#config.metadata.annotations | {}
	let fullname = "\(#config.metadata.name)-kafka"
	_saName: *fullname | string
	if k.serviceAccount.name != "" {_saName: k.serviceAccount.name}

	serviceAccount: [
		if k.serviceAccount.create {
			corev1.#ServiceAccount & {
				apiVersion: "v1"
				kind:       "ServiceAccount"
				metadata: {
					name:      _saName
					namespace: #config.metadata.namespace
					labels: #config.metadata.labels & {
						"app.kubernetes.io/component": "kafka"
					}
					annotations: (#MergeAnnotations & {#global: globalAnn, #local: k.serviceAccount.annotations}).#result
				}
				automountServiceAccountToken: k.serviceAccount.automountServiceAccountToken
			}
		},
	]

	role: [
		if k.rbac.create {
			{
				apiVersion: "rbac.authorization.k8s.io/v1"
				kind:       "Role"
				metadata: {
					name:      fullname
					namespace: #config.metadata.namespace
					labels: #config.metadata.labels & {
						"app.kubernetes.io/component": "kafka"
					}
					annotations: (#MergeAnnotations & {#global: globalAnn, #local: k.commonAnnotations}).#result
				}
				rules: k.rbac.rules
			}
		},
	]

	roleBinding: [
		if k.rbac.create {
			{
				apiVersion: "rbac.authorization.k8s.io/v1"
				kind:       "RoleBinding"
				metadata: {
					name:      fullname
					namespace: #config.metadata.namespace
					labels: #config.metadata.labels & {
						"app.kubernetes.io/component": "kafka"
					}
					annotations: (#MergeAnnotations & {#global: globalAnn, #local: k.commonAnnotations}).#result
				}
				roleRef: {
					apiGroup: "rbac.authorization.k8s.io"
					kind:     "Role"
					name:     fullname
				}
				subjects: [
					{
						kind:      "ServiceAccount"
						name:      _saName
						namespace: #config.metadata.namespace
					},
				]
			}
		},
	]
}

// 8. /charts/kafka/templates/metrics/
#KafkaMetrics: {
	#config: #Config
	let k = #config."hyperswitch-app".kafka
	let globalAnn = *#config.metadata.annotations | {}
	let fullname = "\(#config.metadata.name)-kafka"

	jmxConfigMap: [
		if k.metrics.jmx.enabled && k.metrics.jmx.existingConfigmap == "" {
			corev1.#ConfigMap & {
				apiVersion: "v1"
				kind:       "ConfigMap"
				metadata: {
					name:      "\(fullname)-jmx-configuration"
					namespace: #config.metadata.namespace
					labels: #config.metadata.labels & {
						"app.kubernetes.io/component": "metrics"
					}
					annotations: (#MergeAnnotations & {#global: globalAnn, #local: k.commonAnnotations}).#result
				}
				data: {
					"jmx-kafka-prometheus.yml": k.metrics.jmx.config
				}
			}
		},
	]

	jmxService: [
		if k.metrics.jmx.enabled {
			corev1.#Service & {
				apiVersion: "v1"
				kind:       "Service"
				metadata: {
					name:      "\(fullname)-metrics"
					namespace: #config.metadata.namespace
					labels: #config.metadata.labels & {
						"app.kubernetes.io/component": "metrics"
					}
					annotations: (#MergeAnnotations & {#global: globalAnn, #local: k.metrics.jmx.service.annotations}).#result
				}
				spec: {
					type: k.metrics.jmx.service.type
					ports: [
						{
							name:       "http-metrics"
							port:       k.metrics.jmx.service.ports.metrics
							protocol:   "TCP"
							targetPort: "metrics"
						},
					]
					selector: {
						for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
						"app.kubernetes.io/part-of":   "kafka"
						"app.kubernetes.io/component": "broker"
					}
				}
			}
		},
	]

	jmxServiceMonitor: [
		if k.metrics.jmx.enabled && k.metrics.jmx.serviceMonitor.enabled {
			{
				apiVersion: "monitoring.coreos.com/v1"
				kind:       "ServiceMonitor"
				metadata: {
					name:      "\(fullname)-metrics"
					namespace: *#config.metadata.namespace | string
					if k.metrics.jmx.serviceMonitor.namespace != "" {namespace: k.metrics.jmx.serviceMonitor.namespace}
					labels: #config.metadata.labels & {
						"app.kubernetes.io/component": "metrics"
						for key, val in k.metrics.jmx.serviceMonitor.additionalLabels {"\(key)": val}
					}
					annotations: (#MergeAnnotations & {#global: globalAnn, #local: k.commonAnnotations}).#result
				}
				spec: {
					jobLabel: k.metrics.jmx.serviceMonitor.jobLabel
					selector: matchLabels: {
						for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
						"app.kubernetes.io/name":      "kafka"
						"app.kubernetes.io/component": "metrics"
						for key, val in k.metrics.jmx.serviceMonitor.selector {"\(key)": val}
					}
					endpoints: [
						{
							port: "http-metrics"
							path: "/metrics"
							if k.metrics.jmx.serviceMonitor.interval != "" {
								interval: k.metrics.jmx.serviceMonitor.interval
							}
							if k.metrics.jmx.serviceMonitor.scrapeTimeout != "" {
								scrapeTimeout: k.metrics.jmx.serviceMonitor.scrapeTimeout
							}
							honorLabels: k.metrics.jmx.serviceMonitor.honorLabels
							if k.metrics.jmx.serviceMonitor.relabelings != [] {
								relabelings: k.metrics.jmx.serviceMonitor.relabelings
							}
							if k.metrics.jmx.serviceMonitor.metricRelabelings != [] {
								metricRelabelings: k.metrics.jmx.serviceMonitor.metricRelabelings
							}
						},
					]
				}
			}
		},
	]

	prometheusRule: [
		if k.metrics.jmx.enabled && k.metrics.jmx.prometheusRule.enabled {
			{
				apiVersion: "monitoring.coreos.com/v1"
				kind:       "PrometheusRule"
				metadata: {
					name:      "\(fullname)-metrics"
					namespace: *#config.metadata.namespace | string
					if k.metrics.jmx.prometheusRule.namespace != "" {namespace: k.metrics.jmx.prometheusRule.namespace}
					labels: #config.metadata.labels & {
						"app.kubernetes.io/component": "metrics"
						for key, val in k.metrics.jmx.prometheusRule.additionalLabels {"\(key)": val}
					}
					annotations: (#MergeAnnotations & {#global: globalAnn, #local: k.commonAnnotations}).#result
				}
				spec: {
					groups: [
						{
							name:  "\(fullname)-metrics"
							rules: k.metrics.jmx.prometheusRule.rules
						},
					]
				}
			}
		},
	]
}

// 9. /charts/kafka/templates/extra-list.yaml
#KafkaExtra: {
	#config: #Config
	let k = #config."hyperswitch-app".kafka
	objects: [
		for ed in k.extraDeploy {ed},
	]
}
