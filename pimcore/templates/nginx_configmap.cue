package templates

import (
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
	data: {
		"nginx.conf": """
			user  nginx;
			worker_processes  auto;
			
			error_log  /var/log/nginx/error.log notice;
			pid        /var/run/nginx.pid;
			
			\(#brotliLoad)
			events {
			    worker_connections  1024;
			}
			
			http {
			    types_hash_bucket_size 512;
			    types_hash_max_size 4096;
			    include       /etc/nginx/mime.types;
			    default_type  application/octet-stream;
			
			    log_format  main  'origin: $http_origin $remote_addr - $remote_user [$time_local] "$request" '
			                      '$status $body_bytes_sent "$http_referer" '
			                      '"$http_user_agent" "$http_x_forwarded_for"';
			
			    access_log  /var/log/nginx/access.log  main;
			
			    sendfile        on;
			    #tcp_nopush     on;
			
			    keepalive_timeout  65;
			
			\(#gzipBlock)
			\(#brotliBlock)
			    include /etc/nginx/conf.d/*.conf;
			}
			"""
	}

	#brotliLoad: {
		if #config.nginx.compression.enabled && #config.nginx.compression.brotli.enabled {
			"""
			# Load Brotli modules
			load_module modules/ngx_http_brotli_static_module.so;
			load_module modules/ngx_http_brotli_filter_module.so;
			"""
		}
		if !#config.nginx.compression.enabled || !#config.nginx.compression.brotli.enabled {
			""
		}
	}

	#gzipBlock: {
		if #config.nginx.compression.enabled && #config.nginx.compression.gzip.enabled {
			"""
			    # Enable gzip compression
			    gzip on;
			    gzip_comp_level \(#config.nginx.compression.gzip.comp_level);
			    gzip_min_length \(#config.nginx.compression.gzip.min_length);
			    gzip_types "\(#config.nginx.compression.gzip.types)";
			    gzip_vary on;
			    gzip_proxied any;
			"""
		}
		if !#config.nginx.compression.enabled || !#config.nginx.compression.gzip.enabled {
			""
		}
	}

	#brotliBlock: {
		if #config.nginx.compression.enabled && #config.nginx.compression.brotli.enabled {
			"""
			    # Enable Brotli compression
			    brotli on;
			    brotli_comp_level \(#config.nginx.compression.brotli.comp_level);
			    brotli_types "\(#config.nginx.compression.brotli.types)";
			"""
		}
		if !#config.nginx.compression.enabled || !#config.nginx.compression.brotli.enabled {
			""
		}
	}
}

#ConfigMapNginxServer: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-nginx-server-block"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	data: {
		"default.conf": """
			# mime types are already covered in nginx.conf
			#include mime.types;

			upstream php-pimcore {
			  server \(#config.metadata.name)-php:9000;
			}

			map $args $static_page_root {
			    default                                 /var/tmp/pages;
			    "~*(^|&)pimcore_editmode=true(&|$)"     /var/nonexistent;
			    "~*(^|&)pimcore_preview=true(&|$)"      /var/nonexistent;
			    "~*(^|&)pimcore_version=[^&]+(&|$)"     /var/nonexistent;
			}

			map $uri $static_page_uri {
			    default                                 $uri;
			    "/"                                     /%home;
			}

			server {
			  listen 80 default_server;
			  listen [::]:80 default_server;

			  server_name _;
			  root /var/www/pimcore/public;
			  index index.php;

			  access_log  /var/log/nginx/access.log;
			  error_log   /var/log/nginx/error.log error;

			  client_max_body_size \(#config.nginx.clientMaxBodySize);

			  location = /livez {
			    access_log off;
			    add_header Content-Type text/plain;
			    return 200 "ok\\n";
			  }
			
			  # Protected Assets
			  #
			  ### 1. Option - Restricting access to certain assets completely
			  #
			  # location ~ ^/protected/.* {
			  #   return 403;
			  # }
			  # location ~ ^/var/.*/protected(.*) {
			  #   return 403;
			  # }
			  #
			  # location ~ ^/cache-buster\\-[\\d]+/protected(.*) {
			  #   return 403;
			  # }
			  #
			  ### 2. Option - Checking permissions before delivery
			  #
			  # rewrite ^(/protected/.*) /index.php$is_args$args last;
			  #
			  # location ~ ^/var/.*/protected(.*) {
			  #   return 403;
			  # }
			  #
			  # location ~ ^/cache-buster\\-[\\d]+/protected(.*) {
			  #   return 403;
			  # }

			  # Pimcore Head-Link Cache-Busting
			  rewrite ^/cache-buster-(?:\\d+)/(.*) /$1 last;
			
			  add_header Content-Security-Policy upgrade-insecure-requests;

			  # Stay secure
			  #
			  # a) don't allow PHP in folders allowing file uploads
			
			  location ~* /var/assets/.*\\.php(/|$) {
			    return 404;
			  }
			
			  # b) Prevent clients from accessing hidden files (starting with a dot)
			  # Access to `/.well-known/` is allowed.
			  # https://www.mnot.net/blog/2010/04/07/well-known
			  # https://tools.ietf.org/html/rfc5785

			  location ~* /\\.(?!well-known/) {
			    deny all;
			    log_not_found off;
			    access_log off;
			  }
			
			  # c) Prevent clients from accessing to backup/config/source files

			  location ~* (?:\\.(?:bak|conf(ig)?|dist|fla|in[ci]|log|psd|sh|sql|sw[op])|~)$ {
			    deny all;
			  }

			  # Proxy Mercure hub through nginx (same-origin, no CORS needed)
			  location /hub {
			    proxy_pass http://\(#config.metadata.name)-rabbitmq/.well-known/mercure;
			  }

			  # Some Admin Modules need this:
			  # Server Info, Opcache
			  location ~* ^/admin/external {
			    rewrite .* /index.php$is_args$args last;
			  }

			  # Thumbnails
			  location ~* .*/(image|video)-thumb__\\d+__.* {
			    try_files /var/tmp/thumbnails$uri /index.php;
			    expires 2w;
			    access_log off;
			    add_header Cache-Control "public";
			  }

			  # Assets
			  # Still use a whitelist approach to prevent each and every missing asset to go through the PHP Engine.
			  location ~* ^(?!/admin|/asset/webdav|/studio/api)(.+?)\\.((?:css|js)(?:\\.map)?|jpe?g|gif|png|svgz?|eps|exe|gz|json|zip|mp\\d|m4a|ogg|ogv|webp|webm|pdf|csv|docx?|xlsx?|pptx?)$ {
			    try_files /var/assets$uri $uri =404;
			    expires 2w;
			    access_log off;
			    log_not_found off;
			    add_header Cache-Control "public";
			  }

			  location / {
			    error_page 404 /meta/404;
			    try_files $static_page_root$static_page_uri.html $uri /index.php$is_args$args;
			  }

			  # Use this after initial install is done:
			  location ~ ^/index\\.php(/|$) {
			    send_timeout 1800;
			    fastcgi_read_timeout 1800;
			    fastcgi_split_path_info ^(.+\\.php)(/.+)$;
			    include fastcgi_params;
			    set $path_info $fastcgi_path_info;
			    fastcgi_param PATH_INFO $path_info;

			    fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
			    fastcgi_param DOCUMENT_ROOT $realpath_root;
			    fastcgi_param HTTP_PROXY "";

			    fastcgi_pass php-pimcore;
			    internal;
			  }

			  # PHP-FPM Status and Ping
			  location /fpm- {
			    access_log off;
			    include fastcgi_params;
			    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
			    location /fpm-status {
			      allow 127.0.0.1;
			      deny all;
			      fastcgi_pass php-pimcore;
			    }
			    location /fpm-ping {
			      fastcgi_pass php-pimcore;
			    }
			  }

			  # nginx Status
			  location /nginx-status {
			    allow 127.0.0.1;
			    deny all;
			    access_log off;
			    stub_status;
			  }
			}
			"""
	}
}
