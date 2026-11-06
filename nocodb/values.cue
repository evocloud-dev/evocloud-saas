// Reference: https://github.com/trueforge-org/truecharts/blob/master/charts/stable/nocodb/values.yaml
package main

// Values mirroring values.yaml
values: {
	image: {
		repository: "docker.io/nocodb/nocodb"
		tag:        "0.301.5"
		digest:     "sha256:d9516f0bf546fd6c78a382ab0657626c683fca7aaafdbbe53c66baf15df7fc0d"
		pullPolicy: "IfNotPresent"
	}
	securityContext: {
		container: {
			readOnlyRootFilesystem: false
			runAsNonRoot:           false
			runAsUser:              0
			runAsGroup:             0
		}
	}
	workload: {
		main: {
			podSpec: {
				containers: {
					main: {
						probes: {
							liveness: {
								path: "/dashboard"
							}
							readiness: {
								path: "/dashboard"
							}
							startup: {
								path: "/dashboard"
							}
						}
						// https://nocodb.com/docs/self-hosting/environment-variables
						env: {
							PORT:                  values.service.main.ports.main.port
							NC_PUBLIC_URL:         "http://localhost:10226"
							NC_DISABLE_TELE:       true
							DISABLE_SPLASH_SCREEN: false
							NC_JWT_EXPIRES_IN:     "10h"
							NC_INVITE_ONLY_SIGNUP: false
							NC_DISABLE_CACHE:      false
							NC_DISABLE_ERR_REPORT: true
							NC_REQUEST_BODY_SIZE:  "1MB"
							NC_EXPORT_MAX_TIMEOUT: 5000
							NC_SENTRY_DSN:         ""
							NC_AUTH_JWT_SECRET:    "cDmjQ89jBhdccMGjDqMegQvl4BbsZ7v9"
							AWS_ACCESS_KEY_ID:     ""
							AWS_SECRET_ACCESS_KEY: ""
							AWS_BUCKET:            ""
							AWS_BUCKET_PATH:       ""
						}
					}
				}
			}
		}
	}
	service: {
		main: {
			ports: {
				main: {
					port: 10226
				}
			}
		}
	}
	persistence: {
		data: {
			enabled:   true
			mountPath: "/usr/app/data"
		}
	}
	cnpg: {
		main: {
			enabled:  true
			user:     "nocodb"
			database: "nocodb"
			image: {
				repository: "ghcr.io/cloudnative-pg/postgresql"
				tag:        "18.6-202610120828-minimal-trixie"
				digest:     "sha256:c9be7f221a05b18fe65259d9136affbabe3b39ad91c3b68f8f2f990a45f35f38"
			}
			securityContext: {
				container: {
					runAsUser:  26
					runAsGroup: 26
				}
			}
		}
	}
	redis: {
		enabled:       true
		redisUsername: "default"
		image: {
			repository: "docker.io/valkey/valkey"
			tag:        "9.2"
			digest:     "sha256:247b5e730bdc9dc29fddb8274d1731b203a1a1a46af63eae3a9d55b4bf74853f"
			pullPolicy: "IfNotPresent"
		}
		securityContext: {
			container: {
				readOnlyRootFilesystem: false
				runAsNonRoot:           false
				runAsUser:              568
				runAsGroup:             0
			}
		}
	}
	// -- Gateway API HTTPRoute exposure to an existing Gateway.
	gatewayAPI: {
		// -- Enable this capability.
		enabled: true
		// -- GatewayClass name.
		gatewayClassName: ""
		// -- Route definitions with parentRefs, hostnames, rules, labels and annotations.
		httpRoutes: [
			{
				name: ""
				// -- Route labels.
				labels: {}
				// -- Route annotations.
				annotations: {}
				// -- References to parent Gateways.
				parentRefs: [
					{
						// -- Gateway name.
						name: "shared-gtw"
						// -- Gateway namespace (optional, defaults to route namespace).
						namespace: "kube-system"
						// -- Gateway API group.
						group: "gateway.networking.k8s.io"
						// -- Gateway API kind.
						kind: "Gateway"
						// -- Gateway section name.
						sectionName: ""
						// -- Gateway listener port.
						port: 80
					},
				]
				// -- Hostnames matching the route.
				hostnames: []
				// -- Routing rules, match conditions, filters and backend references.
				rules: [
					{
						matches: [
							{
								path: {
									type:  "PathPrefix"
									value: "/"
								}
							},
						]
					},
				]
			},
		]
	}
}
