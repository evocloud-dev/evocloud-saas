@extern(embed)

package templates

import (
	corev1 "k8s.io/api/core/v1"
)

_admissionMjs: string @embed(file="admission.mjs", type=text)
_helperMjs:    string @embed(file="helper.mjs", type=text)
_launcherMjs:  string @embed(file="launcher.mjs", type=text)

#Runtime: corev1.#ConfigMap & {
	#config: #Config

	_mailBlock: [
		if !#config.smtp.enabled {
			"    location ~* ^/api/auth/(request-password-reset|forget-password|send-verification-email|change-email)([/.]|$) { return 403; }\n"
		},
		"",
	][0]

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-runtime"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	data: {
		"admission.mjs": _admissionMjs
		"helper.mjs":    _helperMjs
		"launcher.mjs":  _launcherMjs
		"nginx.conf": """
			pid /tmp/nginx.pid;
			worker_processes auto;
			error_log /dev/stderr warn;
			events { worker_connections 1024; }
			http {
			  access_log off;
			  client_body_temp_path /tmp/client_body;
			  proxy_temp_path /tmp/proxy;
			  fastcgi_temp_path /tmp/fastcgi;
			  uwsgi_temp_path /tmp/uwsgi;
			  scgi_temp_path /tmp/scgi;
			  map $http_upgrade $connection_upgrade { default upgrade; '' close; }
			  map $http_x_forwarded_proto $forwarded_scheme { default $scheme; https https; http http; }
			  server {
			    listen 3000;
			    listen [::]:3000;
			    server_name _;
			    client_max_body_size \(#config.proxy.bodySize);
			    location = /_proxyhealth { return 200 'ok'; }
			    location ~* ^/api/auth/sign-up([/.]|$) { return 403; }
			\(_mailBlock)    location / {
			      proxy_pass http://127.0.0.1:3010;
			      proxy_http_version 1.1;
			      proxy_set_header Host $http_host;
			      proxy_set_header X-Forwarded-Host $http_host;
			      proxy_set_header X-Forwarded-Proto $forwarded_scheme;
			      proxy_set_header X-Forwarded-For $remote_addr;
			      proxy_set_header Upgrade $http_upgrade;
			      proxy_set_header Connection $connection_upgrade;
			      proxy_read_timeout 300s;
			      proxy_buffering off;
			      proxy_request_buffering off;
			    }
			  }
			}
			"""
	}
}

