package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ConfigMapNginx: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      #config._nginxConfigName
		namespace: #config.metadata.namespace
		labels:    #config._baseLabels & {
			"app.kubernetes.io/component": "nginx"
		}
	}
	data: {
		"default.conf": """
			log_format hievents_proxy '$remote_addr - $host "$request" $status $body_bytes_sent '
			                          '"$http_referer" "$http_user_agent" '
			                          'upstream=$upstream_addr upstream_status=$upstream_status '
			                          'request_time=$request_time upstream_time=$upstream_response_time '
			                          'auth_cookie=$hievents_has_token';

			map $cookie_token $hievents_cookie_authorization {
			  default "Bearer $cookie_token";
			  "" "";
			}

			map $cookie_token $hievents_has_token {
			  default "yes";
			  "" "no";
			}

			map $http_authorization $hievents_authorization {
			  default $http_authorization;
			  "" $hievents_cookie_authorization;
			}

			server {
			  listen \(#config.webProxy.service.targetPort);
			  listen [::]:\(#config.webProxy.service.targetPort);
			  server_name _;

			  client_max_body_size 20M;
			  access_log /dev/stdout hievents_proxy;
			  error_log /dev/stderr warn;

			  location = /api {
			    return 308 /api/;
			  }

			  location ^~ /api/ {
			    rewrite ^/api(/.*)$ $1 break;
			    proxy_pass http://\(#config._backendName):\(#config.backend.service.port);
			    proxy_http_version 1.1;
			    proxy_set_header Host $host;
			    proxy_set_header X-Real-IP $remote_addr;
			    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
			    proxy_set_header X-Forwarded-Proto $scheme;
			    proxy_set_header X-Forwarded-Host $host;
			    proxy_set_header X-Forwarded-Port $server_port;
			    proxy_set_header Authorization $hievents_authorization;
			    proxy_set_header Cookie $http_cookie;
			    proxy_set_header X-Original-URI $request_uri;
			    proxy_redirect off;
			    \(#config._nginxLocalCookieFlags)
			  }

			  location ^~ /storage/ {
			    proxy_pass http://\(#config._backendName):\(#config.backend.service.port);
			    proxy_http_version 1.1;
			    proxy_set_header Host $host;
			    proxy_set_header X-Real-IP $remote_addr;
			    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
			    proxy_set_header X-Forwarded-Proto $scheme;
			    proxy_set_header X-Forwarded-Host $host;
			    proxy_set_header X-Forwarded-Port $server_port;
			    proxy_set_header Cookie $http_cookie;
			    proxy_set_header X-Original-URI $request_uri;
			    proxy_redirect off;
			    \(#config._nginxLocalCookieFlags)
			  }

			  location = /sw.js {
			    return 404;
			  }

			  location / {
			    proxy_pass http://\(#config._frontendName):\(#config.frontend.service.port);
			    proxy_http_version 1.1;
			    proxy_set_header Host $host;
			    proxy_set_header X-Real-IP $remote_addr;
			    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
			    proxy_set_header X-Forwarded-Proto $scheme;
			    proxy_set_header X-Forwarded-Host $host;
			    proxy_set_header X-Forwarded-Port $server_port;
			    proxy_set_header Cookie $http_cookie;
			    proxy_set_header X-Original-URI $request_uri;
			    proxy_redirect off;
			    \(#config._nginxLocalCookieFlags)
			  }
			}
			"""
	}
}
