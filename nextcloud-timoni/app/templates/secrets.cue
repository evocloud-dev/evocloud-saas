package templates

import (
	corev1 "k8s.io/api/core/v1"
)

// #NextcloudSecret is the literal conversion of secrets.yaml.
//
// The Secret is only emitted when nextcloud.existingSecret.enabled == false.
// When existingSecret is enabled, the user provides their own pre-created Secret
// and this template is skipped — mirroring Helm's {{- if not .Values.nextcloud.existingSecret.enabled }}.
//
// NOTE: Helm uses randAlphaNum to auto-generate passwords when not set.
// In Timoni, all credentials are explicit — operators must provide them
// in values.cue or via a Secret Manager (e.g. External Secrets Operator).
#NextcloudSecret: corev1.#Secret & {
	#in: #Config

	apiVersion: "v1"
	kind:       "Secret"

	metadata: #in.metadata

	type: "Opaque"

	// stringData accepts plain-text values — Kubernetes handles base64 encoding.
	// This is equivalent to Helm's | b64enc and avoids bytes/string type conflicts.
	stringData: {
		// Always present: admin username and password
		"nextcloud-username": #in.nextcloud.username
		"nextcloud-password": #in.nextcloud.password

		// Optional: metrics token — only added when metrics are enabled
		if #in.metrics.enabled {
			"nextcloud-token": #in.metrics.token
		}

		// Optional: SMTP credentials — only added when mail is enabled
		// Mirrors: {{- if .Values.nextcloud.mail.enabled }}
		if #in.nextcloud.mail.enabled {
			"smtp-username": #in.nextcloud.mail.smtp.name
			"smtp-password": #in.nextcloud.mail.smtp.password
			"smtp-host":     #in.nextcloud.mail.smtp.host
		}
	}
}
