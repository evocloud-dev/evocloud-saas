package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#OpenSearchSecret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-opensearch-secrets"
	}
	type: "Opaque"
	stringData: {
		if #config.services.opensearch.local_setup {
			OPENSEARCH_ENABLED: "1"
			OPENSEARCH_URL:     "http://\(#config.metadata.name)-opensearch.\(#config.#namespace).svc.cluster.local:9200"
			OPENSEARCH_USERNAME: #config.services.opensearch.username
			OPENSEARCH_PASSWORD: #config.services.opensearch.password
			OPENSEARCH_INITIAL_ADMIN_PASSWORD: #config.services.opensearch.password
			OPENSEARCH_INDEX_PREFIX:           #config.env.opensearch_index_prefix
			OPENSEARCH_EMBEDDING_DIMENSION:    "1536"
		}
		if !#config.services.opensearch.local_setup {
			OPENSEARCH_ENABLED: "1"
			OPENSEARCH_URL:     #config.services.opensearch.remote_url
			OPENSEARCH_USERNAME: #config.services.opensearch.remote_user
			OPENSEARCH_PASSWORD: #config.services.opensearch.remote_password
			OPENSEARCH_INDEX_PREFIX: #config.env.opensearch_index_prefix
			OPENSEARCH_EMBEDDING_DIMENSION: "1536"
		}
	}
}

#OpenSearchConfigMap: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-opensearch-init"
	}
	data: {
		"create-user.sh": """
			#!/bin/bash
			
			echo \"=== OpenSearch Initialization Script ===\"
			
			echo \"Modifying internal_users.yml before starting OpenSearch...\"
			
			# Hardcoded values
			export OPENSEARCH_USER=${OPENSEARCH_USER:-\"\(#config.services.opensearch.username)\"}
			export OPENSEARCH_PASSWORD=${OPENSEARCH_PASSWORD:-\"\(#config.services.opensearch.password)\"}
			
			echo \"=== Configuration ===\"
			echo \"USER: ${OPENSEARCH_USER}\"
			echo \"PASSWORD: **********\"
			echo \"\"
			
			# Run the user creation script before OpenSearch starts
			export HASHED_PASSWORD=$(bash /usr/share/opensearch/plugins/opensearch-security/tools/hash.sh -p \"${OPENSEARCH_PASSWORD}\")
			
			# Path to internal users file
			INTERNAL_USERS_FILE=\"/usr/share/opensearch/config/opensearch-security/internal_users.yml\"
			
			# Ensure the directory exists
			mkdir -p \"$(dirname \"$INTERNAL_USERS_FILE\")\"
			
			# Check if user already exists
			if grep -q \"^${OPENSEARCH_USER}:\" \"$INTERNAL_USERS_FILE\"; then
			    echo \"User ${OPENSEARCH_USER} already exists in internal_users.yml\"
			else
			    echo \"Adding user ${OPENSEARCH_USER} to internal_users.yml\"
			    cat << EOF >> \"$INTERNAL_USERS_FILE\"
			
			${OPENSEARCH_USER}:
			  hash: \"${HASHED_PASSWORD}\"
			  reserved: false
			  backend_roles:
			  - \"admin\"
			  description: \"User for Plane\"
			EOF
			    echo \"User ${OPENSEARCH_USER} added successfully to configuration\"
			fi
			
			echo \"Starting OpenSearch...\"
			# Start OpenSearch with the original entrypoint
			exec /usr/share/opensearch/opensearch-docker-entrypoint.sh
			
			"""
	}
}
