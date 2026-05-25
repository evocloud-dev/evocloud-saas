package templates

monitoringLokiScenarios: {
	// 1. default-single-binary-values.yaml
	defaultSingleBinaryValues: {
		loki: {
			schemaConfig: {
				configs: [
					{
						from:         "2024-04-01"
						store:        "tsdb"
						object_store: "s3"
						schema:       "v13"
						index: {
							prefix: "loki_index_"
							period: "24h"
						}
					},
				]
			}
			ingester: {
				chunk_encoding: "snappy"
			}
			tracing: {
				enabled: true
			}
			querier: {
				// Default is 4, if you have enough memory and CPU you can increase, reduce if OOMing
				max_concurrent: 4
			}
		}

		// gateway:
		//   ingress:
		//     enabled: true
		//     hosts:
		//       - host: FIXME
		//         paths:
		//           - path: /
		//             pathType: Prefix

		deploymentMode: "Distributed"

		ingester: {
			replicas: 3
		}
		querier: {
			replicas:       3
			maxUnavailable: 2
		}
		queryFrontend: {
			replicas:       2
			maxUnavailable: 1
		}
		queryScheduler: {
			replicas: 2
		}
		distributor: {
			replicas:       3
			maxUnavailable: 2
		}
		compactor: {
			replicas: 1
		}
		indexGateway: {
			replicas:       2
			maxUnavailable: 1
		}

		// optional experimental components
		bloomPlanner: {
			replicas: 0
		}
		bloomBuilder: {
			replicas: 0
		}
		bloomGateway: {
			replicas: 0
		}

		// Enable minio for storage
		minio: {
			enabled: true
		}

		// Zero out replica counts of other deployment modes
		backend: {
			replicas: 0
		}
		read: {
			replicas: 0
		}
		write: {
			replicas: 0
		}

		singleBinary: {
			replicas: 0
		}
	}

	// 2. default-values.yaml
	defaultValues: {
		loki: {
			commonConfig: {
				replication_factor: 1
			}
			useTestSchema: true
			storage: {
				bucketNames: {
					chunks: "chunks"
					ruler:  "ruler"
					admin:  "admin"
				}
			}
		}
		read: {
			replicas: 1
		}
		write: {
			replicas: 1
		}
		backend: {
			replicas: 1
		}
	}

	// 3. ingress-values.yaml
	ingressValues: {
		gateway: {
			ingress: {
				enabled: true
				annotations: {}
				hosts: [
					{
						host: "gateway.loki.example.com"
						paths: [
							{
								path:     "/"
								pathType: "Prefix"
							},
						]
					},
				]
			}
		}
		loki: {
			commonConfig: {
				replication_factor: 1
			}
			useTestSchema: true
			storage: {
				bucketNames: {
					chunks: "chunks"
					ruler:  "ruler"
					admin:  "admin"
				}
			}
		}
		read: {
			replicas: 1
		}
		write: {
			replicas: 1
		}
		backend: {
			replicas: 1
		}
		monitoring: {
			lokiCanary: {
				enabled: false
			}
		}
		test: {
			enabled: false
		}
	}

	// 4. legacy-monitoring-values.yaml
	legacyMonitoringValues: {
		loki: {
			commonConfig: {
				replication_factor: 1
			}
			useTestSchema: true
			storage: {
				bucketNames: {
					chunks: "chunks"
					ruler:  "ruler"
					admin:  "admin"
				}
			}
		}
		read: {
			replicas: 1
		}
		write: {
			replicas: 1
		}
		backend: {
			replicas: 1
		}
		monitoring: {
			enabled: true
			selfMonitoring: {
				enabled: true
				grafanaAgent: {
					installOperator: true
				}
			}
			serviceMonitor: {
				labels: {
					release: "prometheus"
				}
			}
		}
		test: {
			prometheusAddress: "http://prometheus-kube-prometheus-prometheus.prometheus.svc.cluster.local.:9090"
		}
	}

	// 5. simple-scalable-aws-kube-irsa-values.yaml
	simpleScalableAwsKubeIrsaValues: {
		loki: {
			// -- Storage config. Providing this will automatically populate all necessary storage configs in the templated config.
			storage: {
				// Loki requires a bucket for chunks and the ruler. GEL requires a third bucket for the admin API.
				// Please provide these values if you are using object storage.
				bucketNames: {
					chunks: "aws-s3-chunks-bucket"
					ruler:  "aws-s3-ruler-bucket"
					admin:  "aws-s3-admin-bucket"
				}
				type: "s3"
				s3: {
					region: "eu-central-1"
				}
			}
			// -- Check https://grafana.com/docs/loki/latest/configuration/#schema_config for more info on how to configure schemas
			schemaConfig: {
				configs: [
					{
						from: "2023-09-19"
						index: {
							period: "1d"
							prefix: "tsdb_index_"
						}
						object_store: "s3"
						schema:       "v13"
						store:        "tsdb"
					},
				]
			}
		}
		//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		//
		// Enterprise Loki Configs
		//
		//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

		// -- Configuration for running Enterprise Loki
		enterprise: {
			// Enable enterprise features, license must be provided
			enabled: true
			// -- Grafana Enterprise Logs license
			license: {
				contents: "content of licence"
			}
			tokengen: {
				annotations: {
					"eks.amazonaws.com/role-arn": "arn:aws:iam::2222222:role/test-role"
				}
			}
			// -- Configuration for `provisioner` target
			provisioner: {
				// -- Additional annotations for the `provisioner` Job
				annotations: {
					"eks.amazonaws.com/role-arn": "arn:aws:iam::2222222:role/test-role"
				}
			}
		}
		//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		//
		// Service Accounts and Kubernetes RBAC
		//
		//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		serviceAccount: {
			// -- Annotations for the service account
			annotations: {
				"eks.amazonaws.com/role-arn": "arn:aws:iam::2222222:role/test-role"
			}
		}

		// Configuration for the write pod(s)
		write: {
			persistence: {
				storageClass: "gp2"
			}
		}
		// --  Configuration for the read pod(s)
		read: {
			persistence: {
				storageClass: "gp2"
			}
		}
		// --  Configuration for the backend pod(s)
		backend: {
			persistence: {
				storageClass: "gp2"
			}
		}
	}
}
