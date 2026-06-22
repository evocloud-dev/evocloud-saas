package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#CoolifyAppDeployment: appsv1.#Deployment & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-app"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "core"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: #config.coolifyApp.replicaCount
		selector: matchLabels: (timoniv1.#Selector & {#Name: #config.metadata.name}).labels & {
			"app.kubernetes.io/component": "core"
		}
		template: {
			metadata: {
				labels: (timoniv1.#Selector & {#Name: #config.metadata.name}).labels & {
					"app.kubernetes.io/component": "core"
				}
				annotations: {
					"seccomp.security.alpha.kubernetes.io/pod": "runtime/default"
					"container.seccomp.security.alpha.kubernetes.io/pod": "runtime/default"
				}
			}
			spec: corev1.#PodSpec & {
				terminationGracePeriodSeconds: #config.coolifyApp.migration.timeout
				automountServiceAccountToken:  false
				securityContext: {
					runAsUser:    #config.securityContext.runAsUser
					runAsGroup:   #config.securityContext.runAsGroup
					fsGroup:      #config.securityContext.fsGroup
					runAsNonRoot: #config.securityContext.runAsNonRoot
					seccompProfile: type: "RuntimeDefault"
				}
				initContainers: [
					{
						name:            "populate-config"
						image:           "\(#config.coolifyApp.image.repository):\(#config.coolifyApp.image.tag)"
						imagePullPolicy: #config.coolifyApp.image.pullPolicy
						command: ["/bin/sh"]
						args: ["-c", #populateConfigScript]
						volumeMounts: [
							{
								name:      "nginx-config"
								mountPath: "/mnt/nginx"
							},
							{
								name:      "php-fpm-config"
								mountPath: "/mnt/php-fpm"
							},
						]
						securityContext: {
							runAsUser:                #config.securityContext.runAsUser
							runAsGroup:               #config.securityContext.runAsGroup
							allowPrivilegeEscalation: #config.securityContext.allowPrivilegeEscalation
							readOnlyRootFilesystem:   #config.securityContext.readOnlyRootFilesystem
							if #config.securityContext.capabilities != _|_ {
								capabilities: #config.securityContext.capabilities
							}
						}
					},
					{
						name:            "setup-storage"
						image:           "\(#config.coolifyApp.image.repository):\(#config.coolifyApp.image.tag)"
						imagePullPolicy: #config.coolifyApp.image.pullPolicy
						command: ["/bin/sh"]
						args: ["-c", #setupStorageScript]
						volumeMounts: [
							{
								name:      "shared-data"
								mountPath: "/var/www/html/storage/app"
								subPath:   "coolify/storage"
							},
							{
								name:      "shared-data"
								mountPath: "/var/www/html/storage/logs"
								subPath:   "coolify/logs"
							},
							{
								name:      "shared-data"
								mountPath: "/var/www/html/bootstrap/cache"
								subPath:   "coolify/bootstrap-cache"
							},
							{
								name:      "storage-framework"
								mountPath: "/var/www/html/storage/framework"
							},
						]
						securityContext: {
							runAsUser:                #config.securityContext.runAsUser
							runAsGroup:               #config.securityContext.runAsGroup
							allowPrivilegeEscalation: #config.securityContext.allowPrivilegeEscalation
							readOnlyRootFilesystem:   #config.securityContext.readOnlyRootFilesystem
							if #config.securityContext.capabilities != _|_ {
								capabilities: #config.securityContext.capabilities
							}
						}
						resources: #config.coolifyApp.initContainers.setupStorage.resources
					},
					if #config.coolifyApp.migration.enabled {
						{
							name:            "migrate-database"
							image:           "\(#config.coolifyApp.image.repository):\(#config.coolifyApp.image.tag)"
							imagePullPolicy: #config.coolifyApp.image.pullPolicy
							command: ["/bin/sh"]
							args: ["-c", #migrationScript]
							envFrom: [
								{configMapRef: name: "\(#config.metadata.name)-app-config"},
								{secretRef: name:    "\(#config.metadata.name)-app-secrets"},
							]
							volumeMounts: [
								{
									name:      "shared-data"
									mountPath: "/var/www/html/storage/app"
									subPath:   "coolify/storage"
								},
								{
									name:      "shared-data"
									mountPath: "/var/www/html/storage/logs"
									subPath:   "coolify/logs"
								},
								{
									name:      "shared-data"
									mountPath: "/var/www/html/bootstrap/cache"
									subPath:   "coolify/bootstrap-cache"
								},
								{
									name:      "storage-framework"
									mountPath: "/var/www/html/storage/framework"
								},
								{
									name:      "tmp-dir"
									mountPath: "/tmp"
								},
							]
							workingDir: "/var/www/html"
							securityContext: {
								runAsUser:                #config.securityContext.runAsUser
								runAsGroup:               #config.securityContext.runAsGroup
								allowPrivilegeEscalation: #config.securityContext.allowPrivilegeEscalation
								readOnlyRootFilesystem:   #config.securityContext.readOnlyRootFilesystem
								if #config.securityContext.capabilities != _|_ {
									capabilities: #config.securityContext.capabilities
								}
							}
							resources: #config.coolifyApp.initContainers.migration.resources
						}
					},
				]
				containers: [
					{
						name:            "coolify"
						image:           "\(#config.coolifyApp.image.repository):\(#config.coolifyApp.image.tag)"
						imagePullPolicy: #config.coolifyApp.image.pullPolicy
						command: ["/bin/sh"]
						args: ["-c", #startupScript]
						ports: [
							{
								name:          "http"
								containerPort: #config.coolifyApp.service.targetPort
								protocol:      "TCP"
							},
						]
						envFrom: [
							{configMapRef: name: "\(#config.metadata.name)-app-config"},
							{secretRef: name:    "\(#config.metadata.name)-app-secrets"},
						]
						volumeMounts: [
							{
								name:      "shared-data"
								mountPath: "/var/www/html/storage/app"
								subPath:   "coolify/storage"
							},
							{
								name:      "shared-data"
								mountPath: "/var/www/html/storage/logs"
								subPath:   "coolify/logs"
							},
							{
								name:      "shared-data"
								mountPath: "/var/www/html/bootstrap/cache"
								subPath:   "coolify/bootstrap-cache"
							},
							{
								name:      "nginx-config"
								mountPath: "/etc/nginx"
							},
							{
								name:      "php-fpm-config"
								mountPath: "/usr/local/etc"
							},
							{
								name:      "var-log"
								mountPath: "/var/log"
							},
							{
								name:      "var-run"
								mountPath: "/var/run"
							},
							{
								name:      "var-lib-nginx"
								mountPath: "/var/lib/nginx"
							},
							{
								name:      "tmp-dir"
								mountPath: "/tmp"
							},
							{
								name:      "storage-framework"
								mountPath: "/var/www/html/storage/framework"
							},
						]
						workingDir: #config.coolifyApp.workingDir
						securityContext: {
							runAsUser:                #config.securityContext.runAsUser
							runAsGroup:               #config.securityContext.runAsGroup
							allowPrivilegeEscalation: #config.securityContext.allowPrivilegeEscalation
							readOnlyRootFilesystem:   #config.securityContext.readOnlyRootFilesystem
							if #config.securityContext.capabilities != _|_ {
								capabilities: #config.securityContext.capabilities
							}
						}
						readinessProbe: {
							httpGet: {
								path: #config.coolifyApp.healthCheck.path
								port: #config.coolifyApp.service.targetPort
							}
							initialDelaySeconds: #config.coolifyApp.healthCheck.initialDelaySeconds
							periodSeconds:       #config.coolifyApp.healthCheck.periodSeconds
							timeoutSeconds:      #config.coolifyApp.healthCheck.timeoutSeconds
							failureThreshold:    #config.coolifyApp.healthCheck.failureThreshold
							successThreshold:    #config.coolifyApp.healthCheck.successThreshold
						}
						livenessProbe: {
							httpGet: {
								path: #config.coolifyApp.healthCheck.path
								port: #config.coolifyApp.service.targetPort
							}
							initialDelaySeconds: #config.coolifyApp.healthCheck.initialDelaySeconds + 60
							periodSeconds:       #config.coolifyApp.healthCheck.periodSeconds
							timeoutSeconds:      #config.coolifyApp.healthCheck.timeoutSeconds
							failureThreshold:    3
						}
						resources: #config.coolifyApp.resources
					},
				]
				volumes: [
					{
						name: "shared-data"
						persistentVolumeClaim: claimName: "\(#config.metadata.name)-shared-data-pvc"
					},
					{
						name: "nginx-config"
						emptyDir: {}
					},
					{
						name: "php-fpm-config"
						emptyDir: {}
					},
					{
						name: "var-log"
						emptyDir: {}
					},
					{
						name: "var-run"
						emptyDir: {}
					},
					{
						name: "var-lib-nginx"
						emptyDir: {}
					},
					{
						name: "tmp-dir"
						emptyDir: {}
					},
					{
						name: "storage-framework"
						emptyDir: {}
					},
				]
			}
		}
	}

	#populateConfigScript: """
		echo "Initializing default configurations..."
		if [ -d "/etc/nginx" ]; then
		  echo "Copying /etc/nginx to /mnt/nginx..."
		  cp -a /etc/nginx/. /mnt/nginx/
		fi
		if [ -d "/usr/local/etc" ]; then
		  echo "Copying /usr/local/etc to /mnt/php-fpm..."
		  cp -a /usr/local/etc/. /mnt/php-fpm/
		fi
		echo "Configuration initialization complete."
		"""

	#setupStorageScript: """
		echo "Setting up storage directories and permissions..."
		mkdir -p /var/www/html/storage/app/ssh/keys
		mkdir -p /var/www/html/storage/app/applications
		mkdir -p /var/www/html/storage/app/databases  
		mkdir -p /var/www/html/storage/app/services
		mkdir -p /var/www/html/storage/app/backups
		mkdir -p /var/www/html/storage/app/webhooks-during-maintenance
		mkdir -p /var/www/html/storage/logs
		mkdir -p /var/www/html/storage/framework/cache
		mkdir -p /var/www/html/storage/framework/sessions
		mkdir -p /var/www/html/storage/framework/views
		mkdir -p /var/www/html/bootstrap/cache
		chmod -R 775 /var/www/html/storage/app /var/www/html/storage/framework /var/www/html/storage/logs /var/www/html/bootstrap/cache 2>/dev/null || true
		if [ "$(id -u)" = "0" ]; then
		  chown -R www-data:www-data /var/www/html/storage
		  chown -R www-data:www-data /var/www/html/bootstrap/cache
		fi
		echo "Storage setup completed successfully"
		"""

	#migrationScript: """
		echo "Starting database migration..."
		
		# Define run_cmd helper to handle privilege switching if running as root
		run_cmd() {
		  if [ "$(id -u)" = "0" ]; then
		    su -s /bin/sh www-data -c "$1"
		  else
		    sh -c "$1"
		  fi
		}
		
		# Set maximum wait time (5 minutes)
		MAX_WAIT_TIME=300
		WAIT_INTERVAL=5
		ELAPSED_TIME=0
		
		# Wait for database to be ready
		echo "Waiting for database to be ready..."
		
		# Debug environment variables
		echo "Debug: DB_HOST=${DB_HOST}"
		echo "Debug: DB_PORT=${DB_PORT}" 
		echo "Debug: DB_DATABASE=${DB_DATABASE}"
		echo "Debug: DB_USERNAME=${DB_USERNAME}"
		echo "Debug: Connection string will be: pgsql:host=${DB_HOST};port=${DB_PORT};dbname=${DB_DATABASE}"
		
		# Test database connection with better error handling
		while ! php -r "
			\\$host = getenv('DB_HOST');
			\\$port = getenv('DB_PORT') ?: '5432';
			\\$dbname = getenv('DB_DATABASE');
			\\$username = getenv('DB_USERNAME');
			\\$password = getenv('DB_PASSWORD');
			
			echo 'Environment check:' . PHP_EOL;
			echo '  DB_HOST: ' . (\\$host ?: '(empty)') . PHP_EOL;
			echo '  DB_PORT: ' . \\$port . PHP_EOL;
			echo '  DB_DATABASE: ' . (\\$dbname ?: '(empty)') . PHP_EOL;
			echo '  DB_USERNAME: ' . (\\$username ?: '(empty)') . PHP_EOL;
			echo '  DB_PASSWORD: ' . (empty(\\$password) ? '(empty)' : '(set)') . PHP_EOL;
			
			if (empty(\\$host)) {
				echo 'ERROR: DB_HOST is empty' . PHP_EOL;
				exit(1);
			}
			if (empty(\\$dbname)) {
				echo 'ERROR: DB_DATABASE is empty' . PHP_EOL;
				exit(1);
			}
			if (empty(\\$username)) {
				echo 'ERROR: DB_USERNAME is empty' . PHP_EOL;
				exit(1);
			}
			
			\\$dsn = 'pgsql:host=' . \\$host . ';port=' . \\$port . ';dbname=' . \\$dbname;
			echo 'Attempting connection with DSN: ' . \\$dsn . PHP_EOL;
			
			try {
				\\$pdo = new PDO(\\$dsn, \\$username, \\$password, [
					PDO::ATTR_TIMEOUT => 5,
					PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION
				]);
				echo 'Database connection successful!' . PHP_EOL;
				exit(0);
			} catch (PDOException \\$e) {
				echo 'Database connection failed: ' . \\$e->getMessage() . PHP_EOL;
				exit(1);
			}
		"; do
			ELAPSED_TIME=$((ELAPSED_TIME + WAIT_INTERVAL))
			if [ $ELAPSED_TIME -ge $MAX_WAIT_TIME ]; then
				echo "Timeout: Database did not become ready after ${MAX_WAIT_TIME} seconds"
				exit 1
			fi
			echo "Database not ready, waiting ${WAIT_INTERVAL} seconds... (${ELAPSED_TIME}/${MAX_WAIT_TIME}s elapsed)"
			sleep $WAIT_INTERVAL
		done
		
		echo "Database is ready, running migrations..."
		
		# Ensure proper permissions for Laravel
		if [ "$(id -u)" = "0" ]; then
		  chown -R www-data:www-data /var/www/html/storage
		  chown -R www-data:www-data /var/www/html/bootstrap/cache
		fi
		
		# Run Laravel cache clear and config cache
		run_cmd "php artisan config:clear" || echo "Config clear failed, continuing..."
		run_cmd "php artisan cache:clear" || echo "Cache clear failed, continuing..."
		run_cmd "php artisan route:clear" || echo "Route clear failed, continuing..."
		run_cmd "php artisan view:clear" || echo "View clear failed, continuing..."
		
		# Run database migrations
		run_cmd "php artisan migrate --force --no-interaction"
		
		# Optimize Laravel application for production
		echo "Optimizing Laravel application..."
		run_cmd "php artisan config:cache" || echo "Config cache failed, continuing..."
		run_cmd "php artisan route:cache" || echo "Route cache failed, continuing..."
		run_cmd "php artisan view:cache" || echo "View cache failed, continuing..."
		
		# Create storage link
		run_cmd "php artisan storage:link" || echo "Storage link failed, continuing..."
		
		if [ "\(#config.coolifyApp.migration.runSeeders)" = "true" ]; then
			# Run database seeders
			echo "Running database seeders..."
			run_cmd "php artisan db:seed --force --no-interaction"
		fi
		
		echo "Database migration completed successfully"
		"""

	#startupScript: """
		echo "Starting Coolify with PHP-FPM configuration..."

		# Define run_cmd helper to handle privilege switching if running as root
		run_cmd() {
		  if [ "$(id -u)" = "0" ]; then
		    su -s /bin/sh www-data -c "$1"
		  else
		    sh -c "$1"
		  fi
		}

		# Ensure www-data user exists (only if running as root)
		if [ "$(id -u)" = "0" ]; then
		  id www-data >/dev/null 2>&1 || {
		    echo "Creating www-data user..."
		    addgroup -g 82 -S www-data 2>/dev/null || true
		    adduser -u 82 -D -S -s /sbin/nologin -G www-data www-data 2>/dev/null || true
		  }
		  echo "www-data user info:"
		  id www-data 2>/dev/null || echo "www-data user not found"
		fi

		# Configure PHP-FPM
		\(#phpFpmConfigScript)

		# Configure PHP-FPM before starting any services
		configure_phpfpm

		# Laravel application optimization for production
		echo "Optimizing Laravel application for production..."
		cd /var/www/html

		# Ensure proper ownership and permissions
		if [ "$(id -u)" = "0" ]; then
		  if [ "$(stat -c %U:%G /var/www/html/storage)" != "www-data:www-data" ]; then
		    echo "Fixing storage ownership..."
		    chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
		  fi
		fi
		chmod -R 775 /var/www/html/storage/app /var/www/html/storage/framework /var/www/html/storage/logs /var/www/html/bootstrap/cache 2>/dev/null || true

		# Run Laravel optimizations (only if not already cached)
		if [ ! -f "/var/www/html/bootstrap/cache/config.php" ]; then
		  run_cmd "php artisan config:cache" || echo "Config cache failed, continuing..."
		fi

		if [ ! -f "/var/www/html/bootstrap/cache/routes-v7.php" ]; then
		  run_cmd "php artisan route:cache" || echo "Route cache failed, continuing..."
		fi

		if [ ! -f "/var/www/html/storage/framework/views" ] || [ -z "$(ls -A /var/www/html/storage/framework/views 2>/dev/null)" ]; then
		  run_cmd "php artisan view:cache" || echo "View cache failed, continuing..."
		fi

		# Signal handling for graceful shutdown
		cleanup() {
		  echo "Received shutdown signal, stopping services gracefully..."
		  
		  # Stop nginx gracefully
		  if command -v nginx >/dev/null 2>&1; then
		    echo "Stopping nginx..."
		    nginx -s quit 2>/dev/null || nginx -s stop 2>/dev/null || true
		  fi
		  
		  # Stop PHP-FPM gracefully
		  if command -v php-fpm >/dev/null 2>&1; then
		    echo "Stopping PHP-FPM..."
		    pkill -QUIT php-fpm 2>/dev/null || pkill -TERM php-fpm 2>/dev/null || true
		  fi
		  
		  # Stop any PHP artisan serve processes
		  pkill -f "artisan serve" 2>/dev/null || true
		  
		  echo "Services stopped gracefully"
		  exit 0
		}

		# Set up signal handlers
		trap cleanup SIGTERM SIGINT SIGQUIT

		# Start services
		echo "Starting PHP-FPM..."
		php-fpm --daemonize --fpm-config /usr/local/etc/php-fpm.conf 2>/dev/null || php-fpm -D || php-fpm -D || {
		  echo "ERROR: PHP-FPM failed to start. Check configuration and logs."
		  exit 1
		}

		# Configure and start Nginx
		\(#nginxConfigScript)

		echo "Starting Nginx in background..."
		nginx 2>/dev/null && {
		  echo "Nginx started successfully"
		  # Keep the script running and handle signals
		  while true; do
		    sleep 10 &
		    wait $!
		  done
		} || {
		  echo "Nginx failed to start, trying to start PHP built-in server as fallback..."
		  cd /var/www/html
		  echo "Starting PHP built-in server..."
		  php artisan serve --host=0.0.0.0 --port=\(#config.coolifyApp.service.targetPort) &
		  ARTISAN_PID=$!
		  echo "PHP artisan serve started with PID $ARTISAN_PID"
		  
		  # Wait for the artisan serve process
		  wait $ARTISAN_PID
		}
		"""

	#phpFpmConfigScript: """
		# Function to configure PHP-FPM before starting
		configure_phpfpm() {
		  echo "Configuring PHP-FPM in main container..."
		  
		  # Search for all PHP-FPM configuration files
		  echo "Searching for PHP-FPM configuration files..."
		  
		  # Main PHP-FPM config files - ensure they include pool directory
		  for php_fpm_conf in \\
		    "/usr/local/etc/php-fpm.conf" \\
		    "/etc/php-fpm.conf" \\
		    "/etc/php/8.2/fpm/php-fpm.conf" \\
		    "/etc/php/8.1/fpm/php-fpm.conf" \\
		    "/etc/php/8.0/fpm/php-fpm.conf" \\
		    "/etc/php/7.4/fpm/php-fpm.conf"; do
		    
		    if [ -f "$php_fpm_conf" ]; then
		      echo "Found PHP-FPM config: $php_fpm_conf"
		      
		      # Check if include directive exists
		      if grep -q "include=" "$php_fpm_conf"; then
		        echo "Include directive already exists in $php_fpm_conf"
		      else
		        echo "Adding include directive to $php_fpm_conf"
		        if [ -d "/usr/local/etc/php-fpm.d" ]; then
		          echo "include=/usr/local/etc/php-fpm.d/*.conf" >> "$php_fpm_conf"
		        else
		          echo "include=/usr/local/etc/php-fpm.d/*.conf" >> "$php_fpm_conf"
		        fi
		      fi
		    fi
		  done
		  
		  # Pool configuration files
		  POOL_CONFIGURED=false
		  for pool_dir in \\
		    "/usr/local/etc/php-fpm.d" \\
		    "/etc/php-fpm.d" \\
		    "/etc/php/8.2/fpm/pool.d" \\
		    "/etc/php/8.1/fpm/pool.d" \\
		    "/etc/php/8.0/fpm/pool.d" \\
		    "/etc/php/7.4/fpm/pool.d"; do
		    
		    echo "Checking pool directory: $pool_dir"
		    
		    if [ -d "$pool_dir" ]; then
		      echo "Found pool directory: $pool_dir"
		      pool_conf="$pool_dir/www.conf"
		      
		      # Create or update pool configuration
		      echo "Configuring pool: $pool_conf"
		      echo '[www]' > "$pool_conf"
		      if [ "$(id -u)" = "0" ]; then
		        echo 'user = www-data' >> "$pool_conf"
		        echo 'group = www-data' >> "$pool_conf"
		        echo 'listen.owner = www-data' >> "$pool_conf"
		        echo 'listen.group = www-data' >> "$pool_conf"
		      fi
		      echo 'listen = 127.0.0.1:9000' >> "$pool_conf"
		      echo 'listen.mode = 0660' >> "$pool_conf"
		      echo 'pm = \(#config.coolifyApp.php.fpmPmControl)' >> "$pool_conf"
		      echo 'pm.max_children = \(#config.coolifyApp.php.fpmPmMaxChildren)' >> "$pool_conf"
		      echo 'pm.start_servers = \(#config.coolifyApp.php.fpmPmStartServers)' >> "$pool_conf"
		      echo 'pm.min_spare_servers = \(#config.coolifyApp.php.fpmPmMinSpareServers)' >> "$pool_conf"
		      echo 'pm.max_spare_servers = \(#config.coolifyApp.php.fpmPmMaxSpareServers)' >> "$pool_conf"
		      echo 'pm.max_requests = \(#config.coolifyApp.php.fpmPmMaxRequests)' >> "$pool_conf"
		      echo 'php_admin_value[memory_limit] = \(#config.coolifyApp.php.memoryLimit)' >> "$pool_conf"
		      echo 'php_admin_value[error_log] = /var/log/php-fpm/www-error.log' >> "$pool_conf"
		      echo 'php_admin_flag[log_errors] = on' >> "$pool_conf"
		      POOL_CONFIGURED=true
		      break
		    elif mkdir -p "$pool_dir" 2>/dev/null; then
		      POOL_CONFIGURED=true
		      break
		    fi
		  done
		  
		  if [ "$POOL_CONFIGURED" = "false" ]; then
		    echo "Warning: Could not configure PHP-FPM pool"
		    find /usr/local/etc /etc -name "*php*" -type d 2>/dev/null || true
		  fi
		  
		  # Ensure logs directory exists and is writable
		  mkdir -p /var/log/php-fpm /var/run/php
		  if [ "$(id -u)" = "0" ]; then
		    chown -R www-data:www-data /var/log/php-fpm /var/run/php 2>/dev/null || {
		      echo "Warning: Could not set ownership for PHP-FPM directories. This may cause logging issues."
		    }
		  fi
		  
		  echo "=== PHP-FPM Configuration Summary ==="
		  echo "PHP-FPM configuration files found:"
		  find /usr/local/etc /etc -name "*php-fpm*" -type f 2>/dev/null | head -10 || true
		}
		"""

	#nginxConfigScript: """
		# Configure Nginx if available
		if command -v nginx >/dev/null 2>&1; then
		  echo "Configuring Nginx..."
		  
		  # Create necessary Nginx directories in the writable emptyDir volumes
		  mkdir -p /var/log/nginx \\
		           /var/lib/nginx/logs \\
		           /var/lib/nginx/tmp \\
		           /var/lib/nginx/tmp/client_body \\
		           /var/lib/nginx/tmp/proxy \\
		           /var/lib/nginx/tmp/fastcgi \\
		           /var/lib/nginx/tmp/uwsgi \\
		           /var/lib/nginx/tmp/scgi
		  
		  # Create nginx config
		  cat > /etc/nginx/nginx.conf << 'EOF'
		worker_processes auto;
		pid /var/run/nginx.pid;

		events {
		    worker_connections 1024;
		}

		http {
		    include /etc/nginx/mime.types;
		    default_type application/octet-stream;
		    
		    access_log /var/log/nginx/access.log;
		    error_log /var/log/nginx/error.log warn;
		    
		    sendfile on;
		    tcp_nopush on;
		    tcp_nodelay on;
		    keepalive_timeout 65;
		    
		    server {
		        listen \(#config.coolifyApp.service.targetPort);
		        root /var/www/html/public;
		        index index.php;
		        
		    location / {
		        try_files $uri $uri/ /index.php?$query_string;
		    }
		    
		    location ~ \\.php$ {
		        fastcgi_pass 127.0.0.1:9000;
		        fastcgi_index index.php;
		        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
		        # FastCGI parameters
		        fastcgi_param  QUERY_STRING       $query_string;
		        fastcgi_param  REQUEST_METHOD     $request_method;
		        fastcgi_param  CONTENT_TYPE       $content_type;
		        fastcgi_param  CONTENT_LENGTH     $content_length;
		        fastcgi_param  SCRIPT_NAME        $fastcgi_script_name;
		        fastcgi_param  REQUEST_URI        $request_uri;
		        fastcgi_param  DOCUMENT_URI       $document_uri;
		        fastcgi_param  DOCUMENT_ROOT      $document_root;
		        fastcgi_param  SERVER_PROTOCOL    $server_protocol;
		        fastcgi_param  REQUEST_SCHEME     $scheme;
		        fastcgi_param  HTTPS              $https if_not_empty;
		        fastcgi_param  GATEWAY_INTERFACE  CGI/1.1;
		        fastcgi_param  SERVER_SOFTWARE    nginx/$nginx_version;
		        fastcgi_param  REMOTE_ADDR        $remote_addr;
		        fastcgi_param  REMOTE_PORT        $remote_port;
		        fastcgi_param  SERVER_ADDR        $server_addr;
		        fastcgi_param  SERVER_PORT        $server_port;
		        fastcgi_param  SERVER_NAME        $server_NAME;
		        fastcgi_param  REDIRECT_STATUS    200;
		    }
		        
		        location ~ /\\.ht {
		            deny all;
		        }
		    }
		}
		EOF
		  
		  # Test nginx configuration
		  if nginx -t 2>/dev/null; then
		    echo "Nginx configuration is valid"
		  else
		    echo "ERROR: nginx configuration test failed"
		    nginx -t
		  fi
		else
		  echo "ERROR: nginx binary not found"
		fi
		"""
}

