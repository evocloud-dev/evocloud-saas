package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ConfigMapInit: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-init"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}

	data: {
		"postgresql-init": """
			#!/bin/bash
			set -e

			if ! (bundle exec rails r 'puts User.any?' 2> /dev/null | grep -q true); then
			    bundle exec rake db:migrate db:seed
			else
			    echo Executing migrations...
			    bundle exec rake db:migrate

			    echo Synchronizing locales and translations...
			    bundle exec rails r "Locale.sync; Translation.sync"
			fi

			echo "postgresql init complete :)"
			"""

		"postgresql-init-post": """
			#!/bin/bash
			set -e

			# Run a rails command to ensure the database is up and running.
			bundle exec rails r "true"

			echo "init sequence complete :)"
			"""

		"zammad-init": """
			#!/bin/bash
			set -e

			\(#config.zammadConfig.initContainers.zammad.customInit)

			echo "zammad init complete :)"
			"""
	}

	if #config.zammadConfig.elasticsearch.initialisation {
		_reindexCommand: string
		if #config.zammadConfig.elasticsearch.reindex {
			_reindexCommand: "bundle exec rake zammad:searchindex:rebuild"
		}
		if !#config.zammadConfig.elasticsearch.reindex {
			_reindexCommand: """
				echo "Checking if an elasticsearch index already exists…"

				# Ensure ES connectivity, as SearchIndexBackend.index_exists? swallows internal errors.
				bundle exec rails r "SearchIndexBackend.version"

				if bundle exec rails r "SearchIndexBackend.index_exists?('Ticket') || exit(1)"
				then
				  echo "Elasticsearch index exists, no automatic reindexing is needed."
				else
				  echo "Elasticsearch index does not exist yet, create it now…"
				  bundle exec rake zammad:searchindex:rebuild
				fi
				"""
		}

		data: "elasticsearch-init": """
			#!/bin/bash
			set -e

			ELASTICSEARCH_URL=\(#config.zammadConfig.elasticsearch.schema)://\(#config._elasticsearchHost):\(#config.zammadConfig.elasticsearch.port)
			bundle exec rails r "Setting.set('es_url', '${ELASTICSEARCH_URL}')"

			ELASTICSEARCH_USER=${ELASTICSEARCH_USER:-\(#config.zammadConfig.elasticsearch.user)}
			if [ -n "${ELASTICSEARCH_USER}" ] && [ -n "${ELASTICSEARCH_PASSWORD}" ]; then
			    bundle exec rails r "Setting.set('es_user', '${ELASTICSEARCH_USER}'); Setting.set('es_password', '${ELASTICSEARCH_PASSWORD}')"
			fi

			\(_reindexCommand)

			echo "elasticsearch init complete :)"
			"""
	}
}
