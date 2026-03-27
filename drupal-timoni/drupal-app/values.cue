package main

values: {
	ingress: {
		enabled:   false
		className: ""
		path:      "/"
		annotations: {}
		hosts: [
			"chart-example.local",
		]
		tls: []
	}

	extraEnvVars: []

	netpol: {
		enabled: false
		openshift: enabled: false
	}

	drupal: {
		image:                "drupalwxt/site-wxt"
		tag:                  "6.1.0"
		initContainerImage:   "alpine:3.10"
		imagePullPolicy:      "IfNotPresent"
		replicas:             1
		username:             "admin"
		password:             "admin"
		profile:              "wxt"
		siteEmail:            "admin@example.com"
		siteName:             "Drupal Install Profile (WxT)"
		siteRoot:             "/"
		version:              "d11"
		services:      ""
		// parameters:
		//   cors.config:
		//     enabled: false
		//     allowedHeaders: []
		//     allowedMethods: []
		//     allowedOrigins: ['*']
		//     exposedHeaders: false
		//     maxAge: false
		//     supportsCredentials: false

		extraSettings: ""
		// $settings['trusted_host_patterns'] = ['^example\.com$'];
		php: {
			ini: {}
			fpm: """
				pm.max_children = 50
				pm.start_servers = 5
				pm.min_spare_servers = 5
				pm.max_spare_servers = 35
				"""
		}
		preInstallScripts:    ""
		// drush config-set system.performance js.preprocess 0 -y;
		// drush config-set system.performance css.preprocess 0 -y;

		postInstallScripts:   ""
		// drush config-set system.performance js.preprocess 0 -y;
		// drush config-set system.performance css.preprocess 0 -y;

		preUpgradeScripts:     ""
		// drush config-set system.performance js.preprocess 0 -y;
		// drush config-set system.performance css.preprocess 0 -y;

		postUpgradeScripts:    ""
		// drush config-set system.performance js.preprocess 0 -y;
		// drush config-set system.performance css.preprocess 0 -y;
		dbAvailabilityScript: """
			until drush sql:query "SELECT 1;" > /dev/null 2>&1; do echo Waiting for DB; sleep 3; done
			echo DB available
			"""
		install: true
		restore: {
			enabled:           false
			name:              "latest"
			db:                true
			files:             false
			suppressTarErrors: false
			convert:           false
			volume: {}
		}
		migrate:                             true
		reconfigure: {
			enabled: true
			resources: {
				limits: {
					cpu:    "250m"
					memory: "512Mi"
				}
				requests: {
					cpu:    "50m"
					memory: "256Mi"
				}
			}
		}
		cacheRebuildBeforeDatabaseMigration: true
		updateDBBeforeDatabaseMigration:      true
		cron: {
			enabled:                    true
			schedule:                   "0 * * * *"
			preInstallScripts:          ""
			successfulJobsHistoryLimit: 3
			failedJobsHistoryLimit:     1
		}
		additionalCrons: {}
		backup: {
			enabled: true
			cleanup: enabled: false
			persistence: {
				enabled:      false
				annotations:  {}
				accessMode:   "ReadWriteOnce"
				size:         "8Gi"
				storageClass: "standard"
			}
			schedule:    "0 0 * * *"
			volume:      {}
			sqlDumpArgs: ""
			filesArgs:   ""
			privateArgs: ""
		}
		healthcheck: {
			enabled: true
			probes: {
				livenessProbe: {
					exec: command: [
						"php-fpm-healthcheck",
					]
					initialDelaySeconds: 1
					periodSeconds:       5
					timeoutSeconds:      5
					successThreshold:    1
					failureThreshold:     3
				}
				readinessProbe: {
					exec: command: [
						"php-fpm-healthcheck",
					]
					initialDelaySeconds: 1
					periodSeconds:       5
					timeoutSeconds:      5
					successThreshold:    1
					failureThreshold:     3
				}
			}
		}
		extensions: enabled: true
		serviceType: "ClusterIP"
		persistence: {
			enabled:      true
			annotations:  {}
			accessMode:   "ReadWriteOnce"
			size:         "8Gi"
			storageClass: "standard"
		}
		disableDefaultFilesMount: false
		volumes:                  []
		volumeMounts:             []
		securityContext:          {}
		smtp: {
			host:     "mail"
			tls:      true
			starttls: true
			auth: {
				enabled:  false
				user:     ""
				password: ""
				method:   "LOGIN"
			}
		}
		configSync: directory: "/private/config/sync"
		configSplit: enabled:  false
		podAnnotations:        {}
		resources:             {}
		volumePermissions:     enabled: false
		serviceAccount: {
			create:                       true
			name:                         ""
			annotations:                  {}
			automountServiceAccountToken: true
		}
		tolerations:  []
		nodeSelector: {}
		autoscaling: {
			enabled:                           true
			minReplicas:                       1
			maxReplicas:                       11
			targetCPUUtilizationPercentage:    50
			targetMemoryUtilizationPercentage: 50
		}
		command: []
		args:    []
		strategy: "Recreate"
	}

	nginx: {
		image:           "drupalwxt/site-wxt"
		tag:             "6.1.0-nginx"
		imagePullPolicy: "IfNotPresent"
		replicas:        1
		resolver:        "kube-dns.kube-system.svc.cluster.local"
		serviceType:     "ClusterIP"
		healthcheck: {
			enabled: true
			livenessProbe: {
				httpGet: {
					path: "/_healthz"
					port: 8080
				}
				initialDelaySeconds: 1
				periodSeconds:       5
				timeoutSeconds:      5
				successThreshold:    1
				failureThreshold:     3
			}
			readinessProbe: {
				httpGet: {
					path: "/_healthz"
					port: 8080
				}
				initialDelaySeconds: 1
				periodSeconds:       5
				timeoutSeconds:      5
				successThreshold:    1
				failureThreshold:     3
			}
		}
		customLocations:      ""
		volumes:              []
		volumeMounts:         []
		securityContext:      {}
		gzip:                 "gzip on;\n  gzip_proxied any;\n  gzip_static on;\n  gzip_vary on;\n  gzip_disable \"msie6\";\n  gzip_types application/ecmascript application/javascript application/json application/pdf application/postscript application/x-javascript image/svg+xml text/css text/csv text/javascript text/plain text/xml;",
		client_max_body_size: "20m"
		real_ip_header:       "X-Forwarded-For"
		resources:            {}
		tolerations:         []
		nodeSelector:        {}
		autoscaling: {
			enabled:                           true
			minReplicas:                       1
			maxReplicas:                       11
			targetCPUUtilizationPercentage:    50
			targetMemoryUtilizationPercentage: 50
		}
		strategy: "Recreate"
	}

	external: {
		enabled:  false
		driver:   "mysql"
		port:     3306
		host:     "mysql.example.org"
		database: "wxt"
		user:     "wxt"
		password: "password"
	}

	azure: {
		storageClass: create: false
		azureFile: {
			enabled: false
			folders: [
				"backup",
				"private",
				"public",
				"tmp",
			]
			initMediaIconsFolder: true
			annotations:          {}
			accessMode:           "ReadWriteMany"
			size:                 "256Gi"
			skuName:              "Standard_LRS"
			protocol:             "smb"
			public: spec:         {}
			private: spec:        {}
			backup: spec:         {}
			tmp: spec:            {}
		}
		sharedDisk: {
			enabled: false
			folders: [
				"private",
				"public",
			]
			initMediaIconsFolder: true
			annotations:          {}
			accessMode:           "ReadWriteMany"
			size:                 "256Gi"
			maxShares:            2
			public: spec:         {}
			private: spec:        {}
		}
	}

	mysql: {
		enabled: false
		image: {
			registry:   "docker.io"
			repository: "bitnamilegacy/mysql"
			tag:        "8.0"
			pullPolicy: "IfNotPresent"
		}
		auth: {
			rootPassword: "secret-root-password"
			database:     "wxt"
			username:     "wxt"
			password:     "secret-mysql-password"
		}
		primary: {
			persistence: {
				storageClass: "standard"
				size:    "128Gi"
			}
			resources: {
				requests: {
					memory: "4Gi"
					cpu:    "2000m"
				}
				limits: {
					memory: "8Gi"
					cpu:    "4000m"
				}
			}
			extraFlags: "--default-authentication-plugin=mysql_native_password --skip-name-resolve --max_allowed_packet=256M --innodb_buffer_pool_size=4096M --innodb_buffer_pool_instances=4 --table_definition_cache=4096 --table_open_cache=8192 --innodb_flush_log_at_trx_commit=2 --skip_ssl --require_secure_transport=OFF"
			strategy:   "Recreate"
		}
		volumePermissions: {
			enabled: true
			image: {
				registry:   "docker.io"
				repository: "bitnamilegacy/os-shell"
				tag:        "12-debian-12"
			}
		}
	}

	postgresql: {
		enabled: true
		image: {
			registry:   "docker.io"
			repository: "bitnamilegacy/postgresql"
			tag:        "16"
			pullPolicy: "IfNotPresent"
		}
		auth: {
			enablePostgresUser: true
			postgresPassword:   "example"
			username:           "wxt"
			password:           "example"
			database:           "wxt"
		}
		primary: {
			persistence: {
				storageClass: "standard"
				size:    "128Gi"
			}
			resources: {
				requests: {
					memory: "512Mi"
					cpu:    "50m"
				}
				limits: {
					memory: "1Gi"
					cpu:    "250m"
				}
			}
			extendedConfiguration: """
				listen_addresses='*'
				max_connections=200
				shared_buffers='512MB'
				work_mem='2048MB'
				effective_cache_size='512MB'
				maintenance_work_mem='32MB'
				min_wal_size='512MB'
				max_wal_size='512MB'
				bytea_output='escape'
				"""
			strategy: "Recreate"
		}
		volumePermissions: {
			enabled: true
			image: {
				registry:   "docker.io"
				repository: "bitnamilegacy/os-shell"
				tag:        "12-debian-12"
			}
		}
	}

	pgbouncer: {
		enabled:              false
		host:                 "mypgserver.postgres.database.azure.com"
		user:                 "username@hostname"
		password:             "password"
		poolSize:             50
		maxClientConnections: 400
	}

	proxysql: {
		enabled: false
		admin: {
			user:     "username@hostname"
			password: "password"
		}
		monitor: {
			user:     "username@hostname"
			password: "password"
		}
		configuration: {
			maxConnections: 2048
			serverVersion:  "5.7.28"
			stackSize:      1048576
		}
	}

	redis: {
		enabled:      true
		image: {
			registry:   "docker.io"
			repository: "bitnamilegacy/redis"
			tag:        "7.0"
			pullPolicy: "IfNotPresent"
		}
		architecture: "standalone"
		auth: {
			enabled: true
			aclUsers: default: {
				permissions: "~* &* +@all"
				password:    "secretpass"
			}
		}
		configuration: """
			dir /bitnami/redis/data
			appendonly no
			save ""
			protected-mode no
			requirepass secretpass
			"""
		// primary: {
		//   service: type: "ClusterIP"
		//   persistence: enabled: false
		// }
		// replica: replicaCount: 0
		// queue: enabled: true
	}

	solr: {
		enabled: true
		image: {
			registry:   "docker.io"
			repository: "bitnamilegacy/solr"
			tag:        "9.2.1-debian-11-r73"
			pullPolicy: "IfNotPresent"
		}
		cloudEnabled:   false
		cloudBootstrap: false
		zookeeper:      enabled: false
		replicaCount:       1
		collectionReplicas: 1
		service: {
			type: "ClusterIP"
			port: 8983
		}
		persistence: {
			enabled:      true
			size:         "8Gi"
			storageClass: "standard"
		}
		}

	varnish: {
		enabled:      true
		replicaCount: 1
		varnishd: {
			image:           "varnish"
			tag:             "6.6.2"
			imagePullPolicy: "IfNotPresent"
		}
		service: {
			type: "ClusterIP"
			port: 8080
		}
		memorySize: "100M"
		admin: {
			enabled: false
			port:    6082
			secret:  ""
		}
		destinationRule: {
			enabled: false
			mode:    "DISABLE"
		}
		clusterDomain: "cluster.local"
		resources:     {}
		tolerations:   []
		nodeSelector:  {}
		affinity:      {}
		volumes:       []
		volumeMounts:  []
		varnishConfigContent: #"""
			vcl 4.1;

			import std;
			import directors;

			backend nginx {
			  .host = "BACKEND_HOST";
			  .host_header = "BACKEND_HOST";
			  .port = "8080";
			}

			sub vcl_init {
			  new backends = directors.round_robin();
			  backends.add_backend(nginx);
			}

			sub vcl_recv {
			  set req.http.X-Forwarded-Host = req.http.Host;
			  if (!req.http.X-Forwarded-Proto) {
			    set req.http.X-Forwarded-Proto = "http";
			  }

			  # Answer healthcheck
			  if (req.url == "/_healthcheck" || req.url == "/healthcheck.txt") {
			    return (synth(700, "HEALTHCHECK"));
			  }

			  # Answer splashpage
			  # if (req.url == "/") {
			  #   return (synth(701, "SPLASH"));
			  # }

			  set req.backend_hint = backends.backend();

			  # Always cache certain file types
			  # Remove cookies that Drupal doesn't care about
			  if (req.url ~ "(?i)\.(asc|dat|tgz|png|gif|jpeg|jpg|ico|swf|css|js)(\?.*)?$") {
			    unset req.http.Cookie;
			  } else if (req.http.Cookie) {
			    set req.http.Cookie = ";" + req.http.Cookie;
			    set req.http.Cookie = regsuball(req.http.Cookie, "; +", ";");
			    set req.http.Cookie = regsuball(req.http.Cookie, ";(SESS[a-z0-9]+|SSESS[a-z0-9]+|NO_CACHE)=", "; \1=");
			    set req.http.Cookie = regsuball(req.http.Cookie, ";[^ ][^;]*", "");
			    set req.http.Cookie = regsuball(req.http.Cookie, "^[; ]+|[; ]+$", "");
			    if (req.http.Cookie == "") {
			        unset req.http.Cookie;
			    } else {
			        return (pass);
			    }
			  }
			  # If POST, PUT or DELETE, then don't cache
			  if (req.method == "POST" || req.method == "PUT" || req.method == "DELETE") {
			    return (pass);
			  }
			  # Happens before we check if we have this in cache already.
			  #
			  # Typically you clean up the request here, removing cookies you don't need,
			  # rewriting the request, etc.
			  return (hash);
			  #return (pass);
			}

			sub vcl_backend_fetch {
			  # NEW
			  set bereq.http.Host = "BACKEND_HOST";

			  # Don't add 127.0.0.1 to X-Forwarded-For
			  set bereq.http.X-Forwarded-For = regsub(bereq.http.X-Forwarded-For, "(, )?127\.0\.0\.\d$", "");
			}

			sub vcl_backend_response {
			  if (beresp.http.Location && beresp.http.Location !~ "^https://api.twitter.com/") {
			    set beresp.http.Location = regsub(
			      beresp.http.Location,
			      "^https?://[^/]+/",
			      bereq.http.X-Forwarded-Proto + "://" + bereq.http.X-Forwarded-Host + "/"
			    );
			  }
			  # Only cache select response codes
			  if (beresp.status == 200 || beresp.status == 203 || beresp.status == 204 || beresp.status == 206 || beresp.status == 300 || beresp.status == 301 || beresp.status == 404 || beresp.status == 405 || beresp.status == 410 || beresp.status == 414 || beresp.status == 501) {
			    # Cache for 5 minutes
			    set beresp.ttl = 5m;
			    set beresp.grace = 12h;
			    set beresp.keep = 24h;
			  } else {
			    set beresp.ttl = 0s;
			  }
			}

			sub vcl_deliver {
			  # Remove identifying information
			  unset resp.http.Server;
			  unset resp.http.X-Powered-By;
			  unset resp.http.X-Varnish;
			  unset resp.http.Via;

			  # Comment these for easier Drupal cache tag debugging in development.
			  unset resp.http.Cache-Tags;
			  unset resp.http.X-Drupal-Cache-Contexts;

			  # Add Content-Security-Policy
			  # set resp.http.Content-Security-Policy = "default-src 'self' *.example.ca *.example.ca; style-src 'self' 'unsafe-inline' *.example.ca https://fonts.googleapis.com; script-src 'self' 'unsafe-inline' 'unsafe-eval' *.example.ca  *.adobedtm.com use.fontawesome.com blob:; connect-src 'self' *.example.ca *.omtrdc.net *.demdex.net *.everesttech.net; img-src 'self' *.example.ca *.omtrdc.net *.demdex.net *.everesttech.net data:; font-src 'self' *.example.ca https://fonts.gstatic.com";

			  # Add CORS Headers
			  # if (req.http.Origin ~ "(?i)\.example\.ca$") {
			  #   if (req.url ~ "\.(ttd|woff|woff2)(\?.*)?$") {
			  #     set resp.http.Access-Control-Allow-Origin = "*";
			  #     set resp.http.Access-Control-Allow-Methods = "GET";
			  #   }
			  # }

			  # Add X-Frame-Options
			  # if (req.url ~ "^/(en/|fr/)?media/") {
			  #   set resp.http.X-Frame-Options = "SAMEORIGIN";
			  # } else {
			  #   set resp.http.X-Frame-Options = "DENY";
			  # }

			  set resp.http.X-Content-Type-Options = "nosniff";
			  set resp.http.X-XSS-Protection = "1; mode=block";
			  set resp.http.Strict-Transport-Security = "max-age=2629800";

			  if (req.http.host ~ "site.example.ca") {
			    set resp.http.X-Robots-Tag = "noindex, nofollow";
			  }

			  if (req.url ~ "^/(en/|fr/)?(search/|recherche/)site/") {
			    set resp.http.X-Robots-Tag = "noindex, nofollow";
			  }

			  # Happens when we have all the pieces we need, and are about to send the
			  # response to the client.
			  #
			  # You can do accounting or modifying the final object here.
			  if (obj.hits > 0) {
			    set resp.http.X-Cache = "HIT";
			  } else {
			    set resp.http.X-Cache = "MISS";
			  }
			  # Handle errors
			  if ( (resp.status >= 500 && resp.status <= 599)
			    || resp.status == 400
			    || resp.status == 401
			    || resp.status == 403
			    || resp.status == 404) {
			    return (synth(resp.status));
			  }
			}

			sub vcl_synth {
			  # Remove identifying information
			  unset resp.http.Server;
			  unset resp.http.X-Powered-By;
			  unset resp.http.X-Varnish;
			  unset resp.http.Via;

			  # Add Content-Security-Policy
			  # set resp.http.Content-Security-Policy = "default-src 'self' *.example.ca; style-src 'self' 'unsafe-inline' *.example.ca; script-src 'self' 'unsafe-inline' 'unsafe-eval' *.example.ca *.adobedtm.com use.fontawesome.com blob:; connect-src 'self' *.example.ca *.omtrdc.net *.demdex.net *.everesttech.net; img-src 'self' *.example.ca data:;";
			  # set resp.http.X-Content-Type-Options = "nosniff";
			  # set resp.http.X-Frame-Options = "DENY";
			  # set resp.http.X-XSS-Protection = "1; mode=block";

			  set resp.http.Strict-Transport-Security = "max-age=2629800";

			  # if (resp.status >= 500 && resp.status <= 599) {
			  #   set resp.http.Content-Type = "text/html; charset=utf-8";
			  #   synthetic(std.fileread("/data/configuration/varnish/errors/503.html"));
			  #   return (deliver);
			  # } elseif (resp.status == 400) { # 400 - Bad Request
			  #   set resp.http.Content-Type = "text/html; charset=utf-8";
			  #   synthetic(std.fileread("/data/configuration/varnish/errors/400.html"));
			  #   return (deliver);
			  # } elseif (resp.status == 401) { # 401 - Unauthorized
			  #   set resp.http.Content-Type = "text/html; charset=utf-8";
			  #   synthetic(std.fileread("/data/configuration/varnish/errors/401.html"));
			  #   return (deliver);
			  # } elseif (resp.status == 403) { # 403 - Forbidden
			  #   set resp.http.Content-Type = "text/html; charset=utf-8";
			  #   synthetic(std.fileread("/data/configuration/varnish/errors/403.html"));
			  #   return (deliver);
			  # } elseif (resp.status == 404) { # 404 - Not Found
			  #   set resp.http.Content-Type = "text/html; charset=utf-8";
			  #   synthetic(std.fileread("/data/configuration/varnish/errors/404.html"));
			  #   return (deliver);
			  # } else
			  if (resp.status == 700) { # Respond to healthcheck
			    set resp.status = 200;
			    set resp.http.Content-Type = "text/plain";
			    synthetic ( {"OK"} );
			    return (deliver);
			  }
			  # elseif (resp.status == 701) { # Respond to splash
			  #   set resp.status = 200;
			  #   set resp.http.Content-Type = "text/html";
			  #   synthetic(std.fileread("/splash/index.html"));
			  #   return (deliver);
			  # }
			}
			"""#
}
}
