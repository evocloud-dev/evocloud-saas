package templates

import (
	timoniv1 "timoni.sh/core/v1alpha1"
)

#NginxConfigMap: timoniv1.#ImmutableConfig & {
	#config: #Config
	#Kind:   timoniv1.#ConfigMapKind
	#Meta: {
		name:      "\(#config.metadata.name)-nginx"
		namespace: #config.metadata.namespace
		labels: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-nginx"
			"app.kubernetes.io/instance": #config.metadata.name
			"app.kubernetes.io/version":  #config.moduleVersion
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	#Data: {
		"nginx.conf": """
			error_log /proc/self/fd/2;
			pid /tmp/nginx.pid;
			worker_processes auto;
			worker_rlimit_nofile 500000;

			events {
			  multi_accept on;
			  use epoll;
			  worker_connections 8192;
			}

			http {
			  access_log /proc/self/fd/1;
			  client_max_body_size \(#config.nginx.client_max_body_size);
			  default_type application/octet-stream;
			  \(#config.nginx.gzip)
			  include /etc/nginx/mime.types;
			  index index.html index.htm;
			  keepalive_timeout 240;
			  proxy_cache_path /tmp/cache_temp levels=1:2 keys_zone=one:8m max_size=3000m inactive=600m;
			  proxy_temp_path /tmp/proxy_temp;
			  sendfile on;
			  server_tokens off;
			  tcp_nopush on;
			  types_hash_max_size 2048;
			  proxy_http_version 1.1;

			  server {
			      listen 8080;
			      listen [::]:8080;
			      root /var/www/html;
			      index index.php index.html index.htm;
			      server_name _;
			      set_real_ip_from 0.0.0.0/0;
			      real_ip_header \(#config.nginx.real_ip_header);

			      location /_healthz {
			          access_log off;
			          return 200 "OK";
			      }

			      location / {
			          try_files $uri $uri/ /index.html /index.php?$query_string;
			      }

			      location ~ \\.php$ {
			        proxy_intercept_errors on;
			        include fastcgi_params;
			        fastcgi_read_timeout 120;
			        fastcgi_param SCRIPT_FILENAME $request_filename;
			        fastcgi_intercept_errors on;
			        fastcgi_pass \(#config.metadata.name):9000;
			        fastcgi_buffers 16 32k;
			        fastcgi_buffer_size 64k;
			        fastcgi_busy_buffers_size 64k;
			        try_files $uri =404;
			      }
			  }
			}
			"""
	}
}
