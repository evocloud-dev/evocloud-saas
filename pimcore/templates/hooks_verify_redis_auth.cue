package templates

import (
	batchv1 "k8s.io/api/batch/v1"
)

#JobRedisAuthCheck: batchv1.#Job & {
	#config: #Config

	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		name:      "\(#config.metadata.name)-verify-redis-auth"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		annotations: {
			if #config.metadata.annotations != _|_ {
				#config.metadata.annotations
			}
		}
	}
	spec: {
		backoffLimit: 0
		template: {
			metadata: {
				name: "\(#config.metadata.name)"
				labels: {
					"app.kubernetes.io/name":     #config.metadata.name
					"app.kubernetes.io/instance": "\(#config.metadata.name)-verify-redis-auth"
				}
			}
			spec: {
				if #config.php.imagePullSecrets != _|_ && len(#config.php.imagePullSecrets) > 0 {
					imagePullSecrets: #config.php.imagePullSecrets
				}
				serviceAccountName: #saName
				restartPolicy:      "Never"
				containers: [
					{
						name:            "pimcore"
						image:           "\(#config.php.image.registry):\(#config.php.image.tag)"
						imagePullPolicy: #config.php.image.pullPolicy
						envFrom: [
							{
								secretRef: name: "\(#config.metadata.name)-dotenv"
							},
						]
						securityContext: {
							runAsUser:  #config.php.phpUser.uid
							runAsGroup: #config.php.phpUser.gid
						}
						resources: {
							requests: {
								cpu:    "100m"
								memory: "128Mi"
							}
							limits: {
								cpu:    "100m"
								memory: "128Mi"
							}
						}
						command: ["php", "-r"]
						args: [
							"""
							$failFastPattern = '/wrongpass|noauth|invalid password|no password is set|client sent auth/i';
							
							$host = getenv('REDIS_SERVER');
							$password = getenv('REDIS_PASSWORD');
							if ($host === false || $host === '') {
							    fwrite(STDERR, "redis-auth-check: REDIS_SERVER env var is not set\\n");
							    exit(1);
							}
							if ($password === false || $password === '') {
							    fwrite(STDERR, "redis-auth-check: REDIS_PASSWORD env var is not set\\n");
							    exit(1);
							}
							$port = 6379;
							$connectTimeout = 2.0;
							$maxAttempts = \((#config.pimcore.redisAuthCheck.maxAttempts));
							$retryDelaySeconds = \((#config.pimcore.redisAuthCheck.retryDelaySeconds));
							
							for ($attempt = 1; $attempt <= $maxAttempts; $attempt++) {
							    $redis = new Redis();
							    try {
							        if (!$redis->connect($host, $port, $connectTimeout)) {
							            throw new RedisException("connect() returned false");
							        }
							        if (!$redis->auth($password)) {
							            throw new RedisException($redis->getLastError() ?: 'auth() returned false');
							        }
							        $pong = $redis->ping();
							        if ($pong === true || $pong === '+PONG' || $pong === 'PONG') {
							            fwrite(STDOUT, "redis-auth-check: PONG from {$host}:{$port} (attempt {$attempt}/{$maxAttempts})\\n");
							            exit(0);
							        }
							        fwrite(STDERR, "redis-auth-check: unexpected PING reply from {$host}:{$port}: " . var_export($pong, true) . "\\n");
							        exit(1);
							    } catch (RedisException $e) {
							        $message = $e->getMessage();
							        if (preg_match($failFastPattern, $message)) {
							            fwrite(STDERR, "redis-auth-check: authentication rejected by {$host}:{$port} — {$message}\\n");
							            exit(1);
							        }
							        if ($attempt >= $maxAttempts) {
							            fwrite(STDERR, "redis-auth-check: exhausted {$maxAttempts} attempts against {$host}:{$port} — {$message}\\n");
							            exit(1);
							        }
							        fwrite(STDERR, "redis-auth-check: attempt {$attempt}/{$maxAttempts} against {$host}:{$port} failed — {$message}\\n");
							        sleep($retryDelaySeconds);
							    }
							}
							
							fwrite(STDERR, "redis-auth-check: exhausted {$maxAttempts} attempts against {$host}:{$port} without a successful PONG\\n");
							exit(1);
							""",
						]
					},
				]
			}
		}
	}

	#saName: {
		if #config.serviceAccount.name != "" {
			#config.serviceAccount.name
		}
		if #config.serviceAccount.name == "" {
			#config.metadata.name
		}
	}
}
