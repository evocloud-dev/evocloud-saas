package templates

import (
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
)

#PrestartHook: batchv1.#Job & {
	#config:    #Config
	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		name:      "\(#config.metadata.name)-prestart-hook"
		namespace: #config.metadata.namespace
		annotations: {
			"helm.sh/hook":               "pre-install,pre-upgrade"
			"helm.sh/hook-weight":        "5"
			"helm.sh/hook-delete-policy": "hook-succeeded,hook-failed,before-hook-creation"
		}
	}
	spec: batchv1.#JobSpec & {
		template: corev1.#PodTemplateSpec & {
			metadata: labels: {
				"sidecar.istio.io/inject": "false"
			}
			spec: corev1.#PodSpec & {
				restartPolicy: "Never"
				containers: [
					corev1.#Container & {
						name:  "prestart-hook"
						image: "docker.io/curlimages/curl-base:latest"
						command: ["/bin/sh", "-c"]
						args: [
							"""
							# Install dependencies
							apk add --no-cache bash && \\
							/bin/bash -c '
							  set -euo pipefail
							  INSTALLATION_METHOD="helm-install"
							  WEBHOOK_URL="https://hyperswitch.gateway.scarf.sh/helm-chart"
							  VERSION="0.2.21"
							  STATUS="initiated"

							  # Send the GET request
							  curl --get "${WEBHOOK_URL}" --data-urlencode "method=${INSTALLATION_METHOD}" --data-urlencode "version=${VERSION}" --data-urlencode "status=${STATUS}"

							  # Print confirmation
							  echo "Request sent to ${WEBHOOK_URL} with method=${INSTALLATION_METHOD}, version=${VERSION} and status=${STATUS}"

							  exit 0
							'
							""",
						]
					},
				]
			}
		}
	}
}

#PoststartHook: batchv1.#Job & {
	#config:    #Config
	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		name:      "\(#config.metadata.name)-poststart-hook"
		namespace: #config.metadata.namespace
		annotations: {
			"helm.sh/hook":               "post-install,post-upgrade"
			"helm.sh/hook-weight":        "5"
			"helm.sh/hook-delete-policy": "hook-succeeded,hook-failed,before-hook-creation"
		}
	}
	spec: batchv1.#JobSpec & {
		template: corev1.#PodTemplateSpec & {
			metadata: labels: {
				"sidecar.istio.io/inject": "false"
			}
			spec: corev1.#PodSpec & {
				restartPolicy: "Never"
				containers: [
					corev1.#Container & {
						name:  "poststart-hook"
						image: "docker.io/curlimages/curl-base:latest"
						command: ["/bin/sh", "-c"]
						args: [
							"""
							# Install dependencies
							apk add --no-cache bash jq && \\
							/bin/bash -c '
							  # URLs
							  INSTALLATION_METHOD="helm-install"
							  VERSION="0.2.21"
							  STATUS=""
							  SERVER_BASE_URL="http://\(#config.metadata.name)-server:80"
							  HYPERSWITCH_HEALTH_URL="${SERVER_BASE_URL}/health"
							  HYPERSWITCH_DEEP_HEALTH_URL="${SERVER_BASE_URL}/health/ready"
							  WEBHOOK_URL="https://hyperswitch.gateway.scarf.sh/helm-chart"

							  MAX_RETRIES=30  # Maximum attempts before exiting
							  ATTEMPT=0

							  until curl --silent --show-error --fail ${HYPERSWITCH_HEALTH_URL} > /dev/null; do
							      ATTEMPT=$((ATTEMPT + 1))
							      if [ "${ATTEMPT}" -ge "${MAX_RETRIES}" ]; then
							          echo "Max retries reached."
							          STATUS="error"
							          ERROR_MESSAGE="404 response"
							          curl --get "${WEBHOOK_URL}" --data-urlencode "method=${INSTALLATION_METHOD}" --data-urlencode "version=${VERSION}" --data-urlencode "status=${STATUS}" --data-urlencode "error_message=${ERROR_MESSAGE}"
							          echo "Webhook notification sent."
							          exit 0
							      fi
							      sleep 2
							  done

							  # Fetch health status
							  echo "Fetching Hyperswitch health status..."
							  HEALTH_RESPONSE=$(curl --silent "${HYPERSWITCH_DEEP_HEALTH_URL}")

							  echo "Raw response: ${HEALTH_RESPONSE}"

							  # Prepare curl command
							  CURL_COMMAND=("curl" "--get" "${WEBHOOK_URL}" "--data-urlencode" "method=${INSTALLATION_METHOD}" "--data-urlencode" "version=${VERSION}")

							  # Check if the response contains an error
							  if [[ "$(echo "${HEALTH_RESPONSE}" | jq --raw-output '.error')" != 'null' ]]; then
							      STATUS="error"
							      ERROR_TYPE=$(echo "${HEALTH_RESPONSE}" | jq --raw-output '.error.type')
							      ERROR_MESSAGE=$(echo "${HEALTH_RESPONSE}" | jq --raw-output '.error.message')
							      ERROR_CODE=$(echo "${HEALTH_RESPONSE}" | jq --raw-output '.error.code')

							      CURL_COMMAND+=(
							          "--data-urlencode" "status=${STATUS}"
							          "--data-urlencode" "error_type=${ERROR_TYPE}"
							          "--data-urlencode" "error_message=${ERROR_MESSAGE}"
							          "--data-urlencode" "error_code=${ERROR_CODE}"
							      )
							  else
							      STATUS="success"
							      CURL_COMMAND+=("--data-urlencode" "status=${STATUS}")

							      for key in $(echo "${HEALTH_RESPONSE}" | jq --raw-output 'keys_unsorted[]'); do
							          value=$(echo "${HEALTH_RESPONSE}" | jq --raw-output --arg key "${key}" '.[$key]')
							          CURL_COMMAND+=("--data-urlencode" "'${key}=${value}'")
							      done
							  fi

							  # Send the webhook request
							  bash -c "${CURL_COMMAND[*]}"

							  echo "Webhook notification sent."

							  exit 0
							'
							""",
						]
					},
				]
			}
		}
	}
}
