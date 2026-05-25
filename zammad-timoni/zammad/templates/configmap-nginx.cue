package templates

import (
	"strings"
	corev1 "k8s.io/api/core/v1"
)

#ConfigMapNginx: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-nginx"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}

	_listenIpv4: string
	if #config.zammadConfig.nginx.listenIpv4 {
		_listenIpv4: "listen 8080;"
	}
	if !#config.zammadConfig.nginx.listenIpv4 {
		_listenIpv4: ""
	}

	_listenIpv6: string
	if #config.zammadConfig.nginx.listenIpv6 {
		_listenIpv6: "listen [::]:8080;"
	}
	if !#config.zammadConfig.nginx.listenIpv6 {
		_listenIpv6: ""
	}

	_trustedProxies: string
	if len(#config.zammadConfig.nginx.trustedProxies) > 0 {
		_proxyList: [ for p in #config.zammadConfig.nginx.trustedProxies { "set_real_ip_from \(p);" } ]
		_trustedProxies: """
		\(strings.Join(_proxyList, "\n        "))
		        real_ip_header X-Forwarded-For;
		        real_ip_recursive on;
		"""
	}
	if len(#config.zammadConfig.nginx.trustedProxies) == 0 {
		_trustedProxies: ""
	}

	_wsHeadersList: [ for h in #config.zammadConfig.nginx.websocketExtraHeaders { "proxy_set_header \(h);" } ]
	_wsHeaders: strings.Join(_wsHeadersList, "\n            ")

	_extraHeadersList: [ for h in #config.zammadConfig.nginx.extraHeaders { "proxy_set_header \(h);" } ]
	_extraHeaders: strings.Join(_extraHeadersList, "\n            ")

	_kbUrlLogic: string
	if #config.zammadConfig.nginx.knowledgeBaseUrl != "" {
		if strings.HasPrefix(#config.zammadConfig.nginx.knowledgeBaseUrl, "/") {
			_kbUrlLogic: "rewrite ^\(#config.zammadConfig.nginx.knowledgeBaseUrl)(.*)$ /help$1 last;"
		}
		if !strings.HasPrefix(#config.zammadConfig.nginx.knowledgeBaseUrl, "/") {
			// Note: Simplified logic since Timoni handles config differently than Helm's urlParse
			_kbUrlLogic: "rewrite ^/\(#config.zammadConfig.nginx.knowledgeBaseUrl)(.*)$ /help$1 last;"
		}
	}
	if #config.zammadConfig.nginx.knowledgeBaseUrl == "" {
		_kbUrlLogic: ""
	}

	_kbProxyHeader: string
	if #config.zammadConfig.nginx.knowledgeBaseUrl != "" {
		_kbProxyHeader: "proxy_set_header X-ORIGINAL-URL $request_uri;"
	}
	if #config.zammadConfig.nginx.knowledgeBaseUrl == "" {
		_kbProxyHeader: ""
	}

	data: {
		"default": """
			#
			# kubernetes nginx config for zammad
			#

			server_tokens off;

			upstream zammad-railsserver {
			    server \(#config.metadata.name)-railsserver:3000;
			}

			upstream zammad-websocket {
			    server \(#config.metadata.name)-websocket:6042;
			}

			server {
			    \(_listenIpv4)
			    \(_listenIpv6)

			    server_name _;

			    root /opt/zammad/public;

			    client_body_temp_path /tmp 1 2;
			    fastcgi_temp_path /tmp 1 2;
			    proxy_temp_path /tmp 1 2;
			    scgi_temp_path /tmp 1 2;
			    uwsgi_temp_path /tmp 1 2;

			    access_log /dev/stdout;
			    error_log  /dev/stderr;

			    client_max_body_size \(#config.zammadConfig.nginx.clientMaxBodySize);

			    \(_trustedProxies)

			    \(_kbUrlLogic)

			    location ~ ^/(assets/|robots.txt|humans.txt|favicon.ico) {
			        expires max;
			    }

			    location /ws {
			        proxy_http_version 1.1;
			        proxy_set_header Upgrade $http_upgrade;
			        proxy_set_header Connection "Upgrade";
			        proxy_set_header Host $http_host;
			        proxy_set_header CLIENT_IP $remote_addr;
			        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
			        \(_wsHeaders)
			        proxy_read_timeout 86400;
			        proxy_pass http://zammad-websocket;
			    }

			    location /cable {
			        proxy_http_version 1.1;
			        proxy_set_header Upgrade $http_upgrade;
			        proxy_set_header Connection "Upgrade";
			        proxy_set_header Host $http_host;
			        proxy_set_header CLIENT_IP $remote_addr;
			        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
			        proxy_read_timeout 86400;
			        proxy_pass http://zammad-railsserver;
			    }

			    location / {
			        proxy_http_version 1.1;
			        \(_kbProxyHeader)
			        proxy_set_header Host $http_host;
			        proxy_set_header CLIENT_IP $remote_addr;
			        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
			        \(_extraHeaders)
			        proxy_read_timeout 180;
			        proxy_pass http://zammad-railsserver;

			        gzip on;
			        gzip_types text/plain text/xml text/css image/svg+xml application/javascript application/x-javascript application/json application/xml;
			        gzip_proxied any;
			    }
			}
			"""

		"nginx.conf": """
			worker_processes auto;

			pid /tmp/nginx.pid;

			include /etc/nginx/modules-enabled/*.conf;

			events {
			    worker_connections 768;
			}

			http {
			    sendfile on;
			    tcp_nopush on;
			    types_hash_max_size 2048;

			    include /etc/nginx/mime.types;
			    default_type application/octet-stream;

			    ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
			    ssl_prefer_server_ciphers on;

			    access_log /dev/stdout;
			    error_log /dev/stdout;

			    gzip on;

			    include /etc/nginx/conf.d/*.conf;
			    include /etc/nginx/sites-enabled/*;
			}
			"""
	}
}
