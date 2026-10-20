@if(debug)

package main

// Values used by debug_tool.cue.
// Debug example 'cue cmd -t debug -t name=semaphore -t namespace=default -t mv=8.0.2 -t kv=1.28.0 build'.
values: {
	podAnnotations: "cluster-autoscaler.kubernetes.io/safe-to-evict": "true"
	image: {
		repository: "docker.io/semaphoreui/semaphore"
		tag:        "v2.19.17"
		digest:     "sha256:008dacd9f1adbd92e8a048f1786ae1dd9bed2a352aca2eb30b9837de5706e7f7"
		pullPolicy: "IfNotPresent"
	}

	securityContext: {
		container: {
			readOnlyRootFilesystem:   false
			runAsNonRoot:             false
			runAsUser:                0
			runAsGroup:               0
			allowPrivilegeEscalation: false
			privileged:               false
			seccompProfile: {
				type: "RuntimeDefault"
			}
			capabilities: {
				add: [
					"CHOWN",
					"SETUID",
					"SETGID",
					"FOWNER",
					"DAC_OVERRIDE",
				]
				drop: [
					"ALL",
				]
			}
		}
		initContainer: {
			runAsNonRoot:             true
			runAsUser:                568
			runAsGroup:               568
			readOnlyRootFilesystem:   true
			allowPrivilegeEscalation: false
			privileged:               false
			seccompProfile: {
				type: "RuntimeDefault"
			}
			capabilities: {
				add: []
				drop: [
					"ALL",
				]
			}
		}
		pod: {
			fsGroup:             568
			fsGroupChangePolicy: "OnRootMismatch"
			supplementalGroups: [568]
			sysctls: []
		}
	}

	service: {
		main: {
			ports: {
				main: {
					port:       3000
					protocol:   "http"
					targetPort: 3000
				}
			}
		}
	}

	resources: {
		requests: {
			cpu:    "75m"
			memory: "200Mi"
		}
		limits: {
			cpu:    "1500m"
			memory: "2400Mi"
		}
	}

	workload: {
		main: {
			podSpec: {
				containers: {
					main: {
						env: {
							// DB
							SEMAPHORE_DB_DIALECT: "postgres"
							SEMAPHORE_DB_USER:    values.cnpg.main.user
							SEMAPHORE_DB:         values.cnpg.main.database
							SEMAPHORE_DB_PORT:    5432
							SEMAPHORE_DB_HOST: {
								secretKeyRef: {
									name: "cnpg-main-urls"
									key:  "host"
								}
							}
							SEMAPHORE_DB_PASS: {
								secretKeyRef: {
									name: "cnpg-main-user"
									key:  "password"
								}
							}
							SEMAPHORE_ACCESS_KEY_ENCRYPTION: {
								secretKeyRef: {
									name: "semaphore-secrets"
									key:  "SEMAPHORE_ACCESS_KEY_ENCRYPTION"
								}
							}
							// set paths to /data
							SEMAPHORE_PLAYBOOK_PATH:  values.persistence.data.mountPath
							SEMAPHORE_ADMIN:          "admin"
							SEMAPHORE_ADMIN_NAME:     "admin"
							SEMAPHORE_ADMIN_PASSWORD: "changeme"
							SEMAPHORE_ADMIN_EMAIL:    "admin@localhost"
							// LDAP
							// no | yes
							SEMAPHORE_LDAP_ACTIVATED: "no"
							// no | yes
							SEMAPHORE_LDAP_NEEDTLS: "no"
						}
					}
				}
			}
		}
	}

	persistence: {
		config: {
			enabled:   true
			mountPath: "/etc/semaphore"
			storage:   "100Gi"
		}
		data: {
			enabled:   true
			mountPath: "/data"
			storage:   "100Gi"
		}
	}

	cnpg: {
		main: {
			enabled:   true
			user:      "semaphore"
			password:  "PLACEHOLDERPASSWORD"
			database:  "semaphore"
			port:      5432
			instances: 2
			image: {
				repository: "ghcr.io/cloudnative-pg/postgresql"
				tag:        "16.15"
				digest:     "sha256:34cd4159d07b3410a1b29da35072e2e927a0905e717a61afa3814624a2e8859a"
			}
			waitImage: {
				repository: "oci.trueforge.org/containerforge/postgresql-client"
				tag:        "9.6.24"
				digest:     "sha256:d40ff61568601b7032a7e6892ca08e55f772d24b32a053d1c0c6b45a2c01ae93"
			}
			storage: {
				size: "100Gi"
			}
			walStorage: {
				size: "100Gi"
			}
		}
	}

	// -- Gateway API HTTPRoute exposure to an existing Gateway.
	gatewayAPI: {
		// -- Enable this capability.
		enabled: false
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
