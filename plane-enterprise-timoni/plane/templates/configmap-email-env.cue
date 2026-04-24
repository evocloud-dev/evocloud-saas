package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#EmailConfigMap: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-email-vars"
	}
	data: {
		SMTP_DOMAIN:         #config.services.email_service.smtp_domain
		MAX_ATTACHMENT_SIZE: *"10485760" | string
		EMAIL_SAVE_ENDPOINT: "http://\(#config.metadata.name)-api.\(#config.#namespace).svc.cluster.local:8000/intake/email/"
		WEBHOOK_URL:         "http://\(#config.metadata.name)-api.\(#config.#namespace).svc.cluster.local:8000/intake/email/"
		"domain-blacklist.txt": """
			10minutemail.com
			10minutemail.net
			10minutemail.org
			
			"""
		"spam.txt": """
			casino
			lottery
			jackpot
			
			"""
	}
}
