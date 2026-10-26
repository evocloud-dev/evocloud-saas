@if(debug)

package main

// Values used by debug_tool.cue.
// Debug example 'cue cmd -t debug -t name=test -t namespace=test -t mv=1.0.0 -t kv=1.28.0 build'.
values: {
	podAnnotations: "cluster-autoscaler.kubernetes.io/safe-to-evict": "true"
	image: {
		repository: "docker.io/chrisvel/tududi"
		tag:        "latest"
		digest:     ""
	}
	postgres: {
		enabled: true
		image: {
			repository: "docker.io/postgres"
			tag:        "16-alpine"
			digest:     ""
		}
	}
	test: {
		enabled: true
		image: {
			repository: "docker.io/curlimages/curl"
			tag:        "latest"
			digest:     ""
		}
	}
	affinity: nodeAffinity: requiredDuringSchedulingIgnoredDuringExecution: nodeSelectorTerms: [{
		matchExpressions: [{
			key:      "kubernetes.io/os"
			operator: "In"
			values: ["linux"]
		}]
	}]
	env: {
		TUDUDI_USER_EMAIL:      "admin@example.com"
		TUDUDI_USER_PASSWORD:   "change-me-to-a-secure-password"
		TUDUDI_SESSION_SECRET:  "change-me-please-use-openssl-rand-hex-64"
		TUDUDI_ALLOWED_ORIGINS: "http://localhost:3002"
		TUDUDI_TRUST_PROXY:     "false"
		TUDUDI_UPLOAD_PATH:     "/app/uploads"
		TUDUDI_BACKUP_PATH:     "/app/backups"
		PUID:                   "1001"
		PGID:                   "1001"
		DB_SSL:                 "false"
		DB_POOL_MAX:            "10"
	}
}
