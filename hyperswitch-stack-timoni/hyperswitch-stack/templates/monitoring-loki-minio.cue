package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
	batchv1 "k8s.io/api/batch/v1"
	networkingv1 "k8s.io/api/networking/v1"
	policyv1 "k8s.io/api/policy/v1"
	"strings"
	"strconv"
	"list"
	"math"
)

monitoringLokiMinio: {
	#config: #Config
	let minio = #config."hyperswitch-monitoring".minio

	// 1. configmap.yaml
	"configmap": corev1.#ConfigMap & {
		apiVersion: "v1"
		kind:       "ConfigMap"
		metadata: {
			name:      "minio"
			namespace: #config.metadata.namespace
			labels:    _labels
		}
		data: {
			initialize:   """
				#!/bin/sh
				set -e ;
				MC_CONFIG_DIR="\(minio.configPathmc)"
				MC="/usr/bin/mc --insecure --config-dir ${MC_CONFIG_DIR}"
				connectToMinio() {
				  SCHEME=$1
				  ATTEMPTS=0 ; LIMIT=29 ;
				  set -e ;
				  ACCESS=$(cat /config/rootUser) ; SECRET=$(cat /config/rootPassword) ;
				  set +e ;
				  echo "Connecting to MinIO server: $SCHEME://minio-svc:\(minio.service.port)" ;
				  MC_COMMAND="${MC} alias set myminio $SCHEME://minio-svc:\(minio.service.port) $ACCESS $SECRET" ;
				  $MC_COMMAND ;
				  STATUS=$? ;
				  until [ $STATUS = 0 ]
				  do
				    ATTEMPTS=`expr $ATTEMPTS + 1` ;
				    echo "Failed attempts: $ATTEMPTS" ;
				    if [ $ATTEMPTS -gt $LIMIT ]; then
				      exit 1 ;
				    fi ;
				    sleep 2 ;
				    $MC_COMMAND ;
				    STATUS=$? ;
				  done ;
				  set -e ;
				  return 0
				}
				checkBucketExists() {
				  BUCKET=$1
				  CMD=$(${MC} ls myminio/$BUCKET > /dev/null 2>&1)
				  return $?
				}
				createBucket() {
				  BUCKET=$1
				  POLICY=$2
				  PURGE=$3
				  VERSIONING=$4
				  OBJECTLOCKING=$5
				  if [ $PURGE = true ]; then
				    if checkBucketExists $BUCKET ; then
				      echo "Purging bucket '$BUCKET'."
				      set +e ;
				      ${MC} rm -r --force myminio/$BUCKET
				      set -e ;
				    else
				      echo "Bucket '$BUCKET' does not exist, skipping purge."
				    fi
				  fi
				if ! checkBucketExists $BUCKET ; then
				    if [ ! -z $OBJECTLOCKING ] ; then
				      if [ $OBJECTLOCKING = true ] ; then
				          echo "Creating bucket with OBJECTLOCKING '$BUCKET'"
				          ${MC} mb --with-lock myminio/$BUCKET
				      elif [ $OBJECTLOCKING = false ] ; then
				            echo "Creating bucket '$BUCKET'"
				            ${MC} mb myminio/$BUCKET
				      fi
				  elif [ -z $OBJECTLOCKING ] ; then
				        echo "Creating bucket '$BUCKET'"
				        ${MC} mb myminio/$BUCKET
				  else
				    echo "Bucket '$BUCKET' already exists."  
				  fi
				  fi
				  if [ -z $OBJECTLOCKING ] ; then
				  if [ ! -z $VERSIONING ] ; then
				    if [ $VERSIONING = true ] ; then
				        echo "Enabling versioning for '$BUCKET'"
				        ${MC} version enable myminio/$BUCKET
				    elif [ $VERSIONING = false ] ; then
				        echo "Suspending versioning for '$BUCKET'"
				        ${MC} version suspend myminio/$BUCKET
				    fi
				    fi
				  else
				      echo "Bucket '$BUCKET' versioning unchanged."
				  fi
				  echo "Setting policy of bucket '$BUCKET' to '$POLICY'."
				  ${MC} policy set $POLICY myminio/$BUCKET
				}
				scheme=[if minio.tls.enabled {"https"}, "http"][0]
				connectToMinio $scheme
				\(strings.Join([for b in minio.buckets {"createBucket \(b.name) \(b.policy) \(b.purge) \(b.versioning) \(b.objectlocking)"}], "\n"))
				"""
			"add-user":   """
				#!/bin/sh
				set -e ;
				MC_CONFIG_DIR="\(minio.configPathmc)"
				MC="/usr/bin/mc --insecure --config-dir ${MC_CONFIG_DIR}"
				\(strings.Join([for u in minio.users {"${MC} admin user add myminio \(u.accessKey) \(u.secretKey); ${MC} admin policy set myminio \(u.policy) user=\(u.accessKey)"}], "\n"))
				"""
			"add-policy": """
				#!/bin/sh
				set -e ;
				MC_CONFIG_DIR="\(minio.configPathmc)"
				MC="/usr/bin/mc --insecure --config-dir ${MC_CONFIG_DIR}"
				\(strings.Join([for p in minio.policies {"${MC} admin policy add myminio \(p.name) /config/policy_\(p.name).json"}], "\n"))
				"""
			for idx, p in minio.policies {
				"policy_\(idx).json": p.statements
			}
			"custom-command": """
				#!/bin/sh
				set -e ;
				MC_CONFIG_DIR="\(minio.configPathmc)"
				MC="/usr/bin/mc --insecure --config-dir ${MC_CONFIG_DIR}"
				\(strings.Join([for c in minio.customCommands {"\(c.command)"}], "\n"))
				"""
		}
	}

	// 2. console-ingress.yaml
	if minio.consoleIngress.enabled {
		"console-ingress": networkingv1.#Ingress & {
			apiVersion: "networking.k8s.io/v1"
			kind:       "Ingress"
			metadata: {
				name:      "minio-console"
				namespace: #config.metadata.namespace
				labels:    _labels & minio.consoleIngress.labels
				if len(minio.consoleIngress.annotations) > 0 {
					annotations: minio.consoleIngress.annotations
				}
			}
			spec: {
				if minio.consoleIngress.ingressClassName != "" {
					ingressClassName: minio.consoleIngress.ingressClassName
				}
				if len(minio.consoleIngress.tls) > 0 {
					tls: [
						for t in minio.consoleIngress.tls {
							hosts: [for h in t.hosts {h}]
							secretName: t.secretName
						},
					]
				}
				rules: [
					for h in minio.consoleIngress.hosts {
						if h != "" {
							host: h
						}
						http: paths: [
							{
								path:     minio.consoleIngress.path
								pathType: "Prefix"
								backend: service: {
									name: "minio-console"
									port: number: strconv.Atoi(minio.consoleService.port)
								}
							},
						]
					},
				]
			}
		}
	}

	// 3. console-service.yaml
	"console-service": corev1.#Service & {
		apiVersion: "v1"
		kind:       "Service"
		metadata: {
			name:      "minio-console"
			namespace: #config.metadata.namespace
			labels:    _labels
			if len(minio.consoleService.annotations) > 0 {
				annotations: minio.consoleService.annotations
			}
		}
		spec: {
			if minio.consoleService.type == "ClusterIP" || minio.consoleService.type == "" {
				type: "ClusterIP"
				if minio.consoleService.clusterIP != "" {
					clusterIP: minio.consoleService.clusterIP
				}
			}
			if minio.consoleService.type == "LoadBalancer" {
				type:           "LoadBalancer"
				loadBalancerIP: minio.consoleService.loadBalancerIP
			}
			if minio.consoleService.type != "ClusterIP" && minio.consoleService.type != "LoadBalancer" && minio.consoleService.type != "" {
				type: minio.consoleService.type
			}
			ports: [
				{
					name: [if minio.tls.enabled {"https"}, "http"][0]
					port:     strconv.Atoi(minio.consoleService.port)
					protocol: "TCP"
					if minio.consoleService.type == "NodePort" && minio.consoleService.nodePort != 0 {
						nodePort: minio.consoleService.nodePort
					}
					if minio.consoleService.type != "NodePort" || minio.consoleService.nodePort == 0 {
						targetPort: strconv.Atoi(minio.minioConsolePort)
					}
				},
			]
			if len(minio.consoleService.externalIPs) > 0 {
				externalIPs: minio.consoleService.externalIPs
			}
			selector: _selectorLabels
		}
	}

	// 4. deployment.yaml
	if minio.mode == "standalone" {
		"deployment": appsv1.#Deployment & {
			let _scheme = [if minio.tls.enabled {"https"}, "http"][0]
			let _bucketRoot = [if minio.bucketRoot != "" {minio.bucketRoot}, minio.mountPath][0]
			apiVersion: "apps/v1"
			kind:       "Deployment"
			metadata: {
				name:      "minio"
				namespace: #config.metadata.namespace
				labels:    _labels & minio.additionalLabels
				if len(minio.additionalAnnotations) > 0 {
					annotations: minio.additionalAnnotations
				}
			}
			spec: {
				strategy: {
					type: minio.DeploymentUpdate.type
					if minio.DeploymentUpdate.type == "RollingUpdate" {
						rollingUpdate: {
							maxSurge:       minio.DeploymentUpdate.maxSurge
							maxUnavailable: minio.DeploymentUpdate.maxUnavailable
						}
					}
				}
				replicas: 1
				selector: matchLabels: _selectorLabels
				template: {
					metadata: {
						name:   "minio"
						labels: _selectorLabels & minio.podLabels
						annotations: {
							if !minio.ignoreChartChecksums {
								"checksum/secrets": "static-checksum-placeholder"
								"checksum/config":  "static-checksum-placeholder"
							}
						} & minio.podAnnotations
					}
					spec: {
						if minio.priorityClassName != "" {
							priorityClassName: minio.priorityClassName
						}
						if minio.runtimeClassName != "" {
							runtimeClassName: minio.runtimeClassName
						}
						if minio.securityContext.enabled && minio.persistence.enabled {
							securityContext: {
								runAsUser:           minio.securityContext.runAsUser
								runAsGroup:          minio.securityContext.runAsGroup
								fsGroup:             minio.securityContext.fsGroup
								fsGroupChangePolicy: minio.securityContext.fsGroupChangePolicy
							}
						}
						if minio.serviceAccount.create {
							serviceAccountName: minio.serviceAccount.name
						}
						containers: [
							{
								name:            "minio"
								image:           "\(minio.image.repository):\(minio.image.tag)"
								imagePullPolicy: minio.image.pullPolicy
								command: [
									"/bin/sh",
									"-ce",
									"/usr/bin/docker-entrypoint.sh minio server \(_bucketRoot) -S \(minio.certsPath) --address :\(minio.minioAPIPort) --console-address :\(minio.minioConsolePort) \(strings.Join(minio.extraArgs, " "))",
								]
								volumeMounts: list.Concat([
									[
										{
											name:      "minio-user"
											mountPath: "/tmp/credentials"
											readOnly:  true
										},
										{
											name:      "export"
											mountPath: minio.mountPath
											if minio.persistence.enabled && minio.persistence.subPath != "" {
												subPath: minio.persistence.subPath
											}
										},
										if minio.extraSecret != "" {
											{
												name:      "extra-secret"
												mountPath: "/tmp/minio-config-env"
											}
										},
									],
									minio.extraVolumeMounts,
								])
								ports: [
									{
										name:          _scheme
										containerPort: strconv.Atoi(minio.minioAPIPort)
									},
									{
										name:          "\(_scheme)-console"
										containerPort: strconv.Atoi(minio.minioConsolePort)
									},
								]
								env: list.Concat([
									[
										{
											name: "MINIO_ROOT_USER"
											valueFrom: secretKeyRef: {
												name: minio.existingSecret | *"minio"
												key:  "rootUser"
											}
										},
										{
											name: "MINIO_ROOT_PASSWORD"
											valueFrom: secretKeyRef: {
												name: minio.existingSecret | *"minio"
												key:  "rootPassword"
											}
										},
										if minio.extraSecret != "" {
											{
												name:  "MINIO_CONFIG_ENV_FILE"
												value: "/tmp/minio-config-env/config.env"
											}
										},
										if minio.metrics.serviceMonitor.public {
											{
												name:  "MINIO_PROMETHEUS_AUTH_TYPE"
												value: "public"
											}
										},
										if minio.oidc.enabled {
											{name: "MINIO_IDENTITY_OPENID_CONFIG_URL", value: minio.oidc.configUrl}
										},
									],
									// (More OIDC/ETCD envs would go here as per YAML literal range)
									[
										for k, v in minio.environment {
											name:  k
											value: v
										},
									],
								])
								resources: minio.resources
							},
						]
						if len(minio.nodeSelector) > 0 {
							nodeSelector: minio.nodeSelector
						}
						if len(minio.affinity) > 0 {
							affinity: minio.affinity
						}
						if len(minio.tolerations) > 0 {
							tolerations: minio.tolerations
						}
						volumes: list.Concat([
							[
								{
									name: "export"
									if minio.persistence.enabled {
										persistentVolumeClaim: claimName: minio.persistence.existingClaim | *"minio"
									}
									if !minio.persistence.enabled {
										emptyDir: {}
									}
								},
								if minio.extraSecret != "" {
									{
										name: "extra-secret"
										secret: secretName: minio.extraSecret
									}
								},
								{
									name: "minio-user"
									secret: secretName: minio.existingSecret | *"minio"
								},
							],
							minio.extraVolumes,
						])
					}
				}
			}
		}
	}

	// 5. gateway-deployment.yaml
	if minio.mode == "gateway" {
		"gateway-deployment": appsv1.#Deployment & {
			let _scheme = [if minio.tls.enabled {"https"}, "http"][0]
			apiVersion: "apps/v1"
			kind:       "Deployment"
			metadata: {
				name:      "minio"
				namespace: #config.metadata.namespace
				labels:    _labels & minio.additionalLabels
			}
			spec: {
				strategy: {
					type: minio.DeploymentUpdate.type
					if minio.DeploymentUpdate.type == "RollingUpdate" {
						rollingUpdate: {
							maxSurge:       minio.DeploymentUpdate.maxSurge
							maxUnavailable: minio.DeploymentUpdate.maxUnavailable
						}
					}
				}
				replicas: minio.gateway.replicas
				selector: matchLabels: _selectorLabels
				template: {
					metadata: {
						name:   "minio"
						labels: _selectorLabels & minio.podLabels
						annotations: {
							if !minio.ignoreChartChecksums {
								"checksum/secrets": "static-checksum-placeholder"
								"checksum/config":  "static-checksum-placeholder"
							}
						} & minio.podAnnotations
					}
					spec: {
						if minio.priorityClassName != "" {
							priorityClassName: minio.priorityClassName
						}
						if minio.runtimeClassName != "" {
							runtimeClassName: minio.runtimeClassName
						}
						if minio.serviceAccount.create {
							serviceAccountName: minio.serviceAccount.name
						}
						containers: [
							{
								name:            "minio"
								image:           "\(minio.image.repository):\(minio.image.tag)"
								imagePullPolicy: minio.image.pullPolicy
								command: [
									"/bin/sh",
									"-ce",
									"/usr/bin/docker-entrypoint.sh minio gateway \(minio.gateway.type) \(strings.Join(minio.extraArgs, " "))",
								]
								volumeMounts: list.Concat([
									[
										{
											name:      "export"
											mountPath: minio.mountPath
										},
									],
									minio.extraVolumeMounts,
								])
								ports: [
									{
										name:          _scheme
										containerPort: strconv.Atoi(minio.minioAPIPort)
									},
									{
										name:          "\(_scheme)-console"
										containerPort: strconv.Atoi(minio.minioConsolePort)
									},
								]
								env: list.Concat([
									[
										{
											name: "MINIO_ROOT_USER"
											valueFrom: secretKeyRef: {
												name: minio.existingSecret | *"minio"
												key:  "rootUser"
											}
										},
										{
											name: "MINIO_ROOT_PASSWORD"
											valueFrom: secretKeyRef: {
												name: minio.existingSecret | *"minio"
												key:  "rootPassword"
											}
										},
									],
									[
										for k, v in minio.environment {
											name:  k
											value: v
										},
									],
								])
								resources: minio.resources
							},
						]
						if len(minio.nodeSelector) > 0 {
							nodeSelector: minio.nodeSelector
						}
						if len(minio.affinity) > 0 {
							affinity: minio.affinity
						}
						if len(minio.tolerations) > 0 {
							tolerations: minio.tolerations
						}
						volumes: list.Concat([
							[
								{
									name: "export"
									if minio.persistence.enabled {
										persistentVolumeClaim: claimName: minio.persistence.existingClaim | *"minio"
									}
									if !minio.persistence.enabled {
										emptyDir: {}
									}
								},
							],
							minio.extraVolumes,
						])
					}
				}
			}
		}
	}

	// 6. ingress.yaml
	if minio.ingress.enabled {
		"ingress": networkingv1.#Ingress & {
			apiVersion: "networking.k8s.io/v1"
			kind:       "Ingress"
			metadata: {
				name:      "minio"
				namespace: #config.metadata.namespace
				labels:    _labels & minio.ingress.labels
				if len(minio.ingress.annotations) > 0 {
					annotations: minio.ingress.annotations
				}
			}
			spec: {
				if minio.ingress.ingressClassName != "" {
					ingressClassName: minio.ingress.ingressClassName
				}
				if len(minio.ingress.tls) > 0 {
					tls: [
						for t in minio.ingress.tls {
							hosts: [for h in t.hosts {h}]
							secretName: t.secretName
						},
					]
				}
				rules: [
					for h in minio.ingress.hosts {
						if h != "" {
							host: h
						}
						http: paths: [
							{
								path:     minio.ingress.path
								pathType: "Prefix"
								backend: service: {
									name: "minio"
									port: number: strconv.Atoi(minio.service.port)
								}
							},
						]
					},
				]
			}
		}
	}

	// 7. networkpolicy.yaml
	if minio.networkPolicy.enabled {
		"networkpolicy": networkingv1.#NetworkPolicy & {
			kind:       "NetworkPolicy"
			apiVersion: "networking.k8s.io/v1"
			metadata: {
				name:      "minio"
				namespace: #config.metadata.namespace
				labels:    _labels
			}
			spec: {
				podSelector: matchLabels: _selectorLabels
				ingress: [
					{
						ports: [
							{port: strconv.Atoi(minio.minioAPIPort)},
							{port: strconv.Atoi(minio.minioConsolePort)},
						]
						if !minio.networkPolicy.allowExternal {
							from: [
								{
									podSelector: matchLabels: {
										"minio-client": "true"
									}
								},
							]
						}
					},
				]
			}
		}
	}

	// 8. poddisruptionbudget.yaml
	if minio.podDisruptionBudget.enabled {
		"poddisruptionbudget": policyv1.#PodDisruptionBudget & {
			apiVersion: "policy/v1beta1"
			kind:       "PodDisruptionBudget"
			metadata: {
				name:      "minio"
				namespace: #config.metadata.namespace
				labels: {
					app: _selectorLabels.app
				}
			}
			spec: {
				maxUnavailable: minio.podDisruptionBudget.maxUnavailable
				selector: matchLabels: {
					app: _selectorLabels.app
				}
			}
		}
	}

	// 9. post-install-create-bucket-job.yaml
	if len(minio.buckets) > 0 {
		"post-install-create-bucket-job": batchv1.#Job & {
			apiVersion: "batch/v1"
			kind:       "Job"
			metadata: {
				name:      "minio-make-bucket-job"
				namespace: #config.metadata.namespace
				labels:    _labels
				annotations: {
					"helm.sh/hook":               "post-install,post-upgrade"
					"helm.sh/hook-delete-policy": "hook-succeeded,before-hook-creation"
				} & minio.makeBucketJob.annotations
			}
			spec: template: {
				metadata: {
					labels: {
						app:     "minio-job"
						release: #config.metadata.name
					} & minio.podLabels
					if len(minio.makeBucketJob.podAnnotations) > 0 {
						annotations: minio.makeBucketJob.podAnnotations
					}
				}
				spec: {
					restartPolicy: "OnFailure"
					if len(minio.nodeSelector) > 0 {
						nodeSelector: minio.makeBucketJob.nodeSelector
					}
					if len(minio.makeBucketJob.affinity) > 0 {
						affinity: minio.makeBucketJob.affinity
					}
					if len(minio.makeBucketJob.tolerations) > 0 {
						tolerations: minio.makeBucketJob.tolerations
					}
					if minio.makeBucketJob.securityContext.enabled {
						securityContext: {
							runAsUser:  minio.makeBucketJob.securityContext.runAsUser
							runAsGroup: minio.makeBucketJob.securityContext.runAsGroup
							fsGroup:    minio.makeBucketJob.securityContext.fsGroup
						}
					}
					volumes: [
						{
							name: "minio-configuration"
							projected: sources: [
								{configMap: {name: "minio"}},
								{secret: {name: "minio"}},
							]
						},
					]
					if minio.serviceAccount.create {
						serviceAccountName: minio.serviceAccount.name
					}
					containers: [
						{
							name:            "minio-mc"
							image:           "\(minio.mcImage.repository):\(minio.mcImage.tag)"
							imagePullPolicy: minio.mcImage.pullPolicy
							command: ["/bin/sh", "/config/initialize"]
							env: [
								{name: "MINIO_ENDPOINT", value: "minio"},
								{name: "MINIO_PORT", value: minio.service.port},
							]
							volumeMounts: [
								{
									name:      "minio-configuration"
									mountPath: "/config"
								},
							]
							resources: minio.makeBucketJob.resources
						},
					]
				}
			}
		}
	}

	// 10. post-install-create-policy-job.yaml
	if len(minio.policies) > 0 {
		"post-install-create-policy-job": batchv1.#Job & {
			apiVersion: "batch/v1"
			kind:       "Job"
			metadata: {
				name:      "minio-make-policies-job"
				namespace: #config.metadata.namespace
				labels:    _labels
				annotations: {
					"helm.sh/hook":               "post-install,post-upgrade"
					"helm.sh/hook-delete-policy": "hook-succeeded,before-hook-creation"
				} & minio.makePolicyJob.annotations
			}
			spec: template: {
				metadata: {
					labels: {
						app:     "minio-job"
						release: #config.metadata.name
					} & minio.podLabels
					if len(minio.makePolicyJob.podAnnotations) > 0 {
						annotations: minio.makePolicyJob.podAnnotations
					}
				}
				spec: {
					restartPolicy: "OnFailure"
					if len(minio.nodeSelector) > 0 {
						nodeSelector: minio.makePolicyJob.nodeSelector
					}
					if len(minio.makePolicyJob.affinity) > 0 {
						affinity: minio.makePolicyJob.affinity
					}
					if len(minio.makePolicyJob.tolerations) > 0 {
						tolerations: minio.makePolicyJob.tolerations
					}
					if minio.makePolicyJob.securityContext.enabled {
						securityContext: {
							runAsUser:  minio.makePolicyJob.securityContext.runAsUser
							runAsGroup: minio.makePolicyJob.securityContext.runAsGroup
							fsGroup:    minio.makePolicyJob.securityContext.fsGroup
						}
					}
					volumes: [
						{
							name: "minio-configuration"
							projected: sources: [
								{configMap: {name: "minio"}},
								{secret: {name: "minio"}},
							]
						},
					]
					if minio.serviceAccount.create {
						serviceAccountName: minio.serviceAccount.name
					}
					containers: [
						{
							name:            "minio-mc"
							image:           "\(minio.mcImage.repository):\(minio.mcImage.tag)"
							imagePullPolicy: minio.mcImage.pullPolicy
							command: ["/bin/sh", "/config/add-policy"]
							env: [
								{name: "MINIO_ENDPOINT", value: "minio"},
								{name: "MINIO_PORT", value: minio.service.port},
							]
							volumeMounts: [
								{
									name:      "minio-configuration"
									mountPath: "/config"
								},
							]
							resources: minio.makePolicyJob.resources
						},
					]
				}
			}
		}
	}

	// 11. post-install-create-user-job.yaml
	if len(minio.users) > 0 {
		"post-install-create-user-job": batchv1.#Job & {
			apiVersion: "batch/v1"
			kind:       "Job"
			metadata: {
				name:      "minio-make-user-job"
				namespace: #config.metadata.namespace
				labels:    _labels
				annotations: {
					"helm.sh/hook":               "post-install,post-upgrade"
					"helm.sh/hook-delete-policy": "hook-succeeded,before-hook-creation"
				} & minio.makeUserJob.annotations
			}
			spec: template: {
				metadata: {
					labels: {
						app:     "minio-job"
						release: #config.metadata.name
					} & minio.podLabels
					if len(minio.makeUserJob.podAnnotations) > 0 {
						annotations: minio.makeUserJob.podAnnotations
					}
				}
				spec: {
					restartPolicy: "OnFailure"
					if len(minio.nodeSelector) > 0 {
						nodeSelector: minio.makeUserJob.nodeSelector
					}
					if len(minio.makeUserJob.affinity) > 0 {
						affinity: minio.makeUserJob.affinity
					}
					if len(minio.makeUserJob.tolerations) > 0 {
						tolerations: minio.makeUserJob.tolerations
					}
					if minio.makeUserJob.securityContext.enabled {
						securityContext: {
							runAsUser:  minio.makeUserJob.securityContext.runAsUser
							runAsGroup: minio.makeUserJob.securityContext.runAsGroup
							fsGroup:    minio.makeUserJob.securityContext.fsGroup
						}
					}
					volumes: [
						{
							name: "minio-configuration"
							projected: sources: list.Concat([
								[
									{configMap: {name: "minio"}},
									{secret: {name: "minio"}},
								],
								[
									for u in minio.users if u.existingSecret != _|_ {
										secret: {
											name: u.existingSecret
											items: [
												{
													key:  u.existingSecretKey
													path: "secrets/\(u.existingSecretKey)"
												},
											]
										}
									},
								],
							])
						},
					]
					if minio.serviceAccount.create {
						serviceAccountName: minio.serviceAccount.name
					}
					containers: [
						{
							name:            "minio-mc"
							image:           "\(minio.mcImage.repository):\(minio.mcImage.tag)"
							imagePullPolicy: minio.mcImage.pullPolicy
							command: ["/bin/sh", "/config/add-user"]
							env: [
								{name: "MINIO_ENDPOINT", value: "minio"},
								{name: "MINIO_PORT", value: minio.service.port},
							]
							volumeMounts: [
								{
									name:      "minio-configuration"
									mountPath: "/config"
								},
							]
							resources: minio.makeUserJob.resources
						},
					]
				}
			}
		}
	}

	// 12. post-install-custom-command.yaml
	if len(minio.customCommands) > 0 {
		"post-install-custom-command": batchv1.#Job & {
			apiVersion: "batch/v1"
			kind:       "Job"
			metadata: {
				name:      "minio-custom-command-job"
				namespace: #config.metadata.namespace
				labels:    _labels
				annotations: {
					"helm.sh/hook":               "post-install,post-upgrade"
					"helm.sh/hook-delete-policy": "hook-succeeded,before-hook-creation"
				} & minio.customCommandJob.annotations
			}
			spec: template: {
				metadata: {
					labels: {
						app:     "minio-job"
						release: #config.metadata.name
					} & minio.podLabels
					if len(minio.customCommandJob.podAnnotations) > 0 {
						annotations: minio.customCommandJob.podAnnotations
					}
				}
				spec: {
					restartPolicy: "OnFailure"
					if len(minio.nodeSelector) > 0 {
						nodeSelector: minio.customCommandJob.nodeSelector
					}
					if len(minio.customCommandJob.affinity) > 0 {
						affinity: minio.customCommandJob.affinity
					}
					if len(minio.customCommandJob.tolerations) > 0 {
						tolerations: minio.customCommandJob.tolerations
					}
					if minio.customCommandJob.securityContext.enabled {
						securityContext: {
							runAsUser:  minio.customCommandJob.securityContext.runAsUser
							runAsGroup: minio.customCommandJob.securityContext.runAsGroup
							fsGroup:    minio.customCommandJob.securityContext.fsGroup
						}
					}
					volumes: [
						{
							name: "minio-configuration"
							projected: sources: [
								{configMap: {name: "minio"}},
								{secret: {name: "minio"}},
							]
						},
					]
					containers: [
						{
							name:            "minio-mc"
							image:           "\(minio.mcImage.repository):\(minio.mcImage.tag)"
							imagePullPolicy: minio.mcImage.pullPolicy
							command: ["/bin/sh", "/config/custom-command"]
							env: [
								{name: "MINIO_ENDPOINT", value: "minio"},
								{name: "MINIO_PORT", value: minio.service.port},
							]
							volumeMounts: [
								{
									name:      "minio-configuration"
									mountPath: "/config"
								},
							]
							resources: minio.customCommandJob.resources
						},
					]
				}
			}
		}
	}

	// 13. pvc.yaml
	if minio.mode == "standalone" {
		if minio.persistence.enabled && minio.persistence.existingClaim == "" {
			"pvc": corev1.#PersistentVolumeClaim & {
				apiVersion: "v1"
				kind:       "PersistentVolumeClaim"
				metadata: {
					name:      "minio"
					namespace: #config.metadata.namespace
					labels:    _labels
					if len(minio.persistence.annotations) > 0 {
						annotations: minio.persistence.annotations
					}
				}
				spec: {
					accessModes: [minio.persistence.accessMode]
					resources: requests: storage: minio.persistence.size
					if minio.persistence.storageClass != "" {
						if minio.persistence.storageClass == "-" {
							storageClassName: ""
						}
						if minio.persistence.storageClass != "-" {
							storageClassName: minio.persistence.storageClass
						}
					}
					if minio.persistence.VolumeName != "" {
						volumeName: minio.persistence.VolumeName
					}
				}
			}
		}
	}

	// 14. secrets.yaml
	if minio.existingSecret == "" {
		"secrets": corev1.#Secret & {
			apiVersion: "v1"
			kind:       "Secret"
			metadata: {
				name:      "minio"
				namespace: #config.metadata.namespace
				labels:    _labels
			}
			type: "Opaque"
			stringData: {
				rootUser:     minio.rootUser
				rootPassword: minio.rootPassword
			}
		}
	}

	// 15. securitycontextconstraints.yaml
	if minio.securityContext.enabled && minio.persistence.enabled && minio.securityContext.sccEnabled {
		"securitycontextconstraints": {
			apiVersion: "security.openshift.io/v1"
			kind:       "SecurityContextConstraints"
			metadata: {
				name:   "minio"
				labels: _labels
			}
			allowHostDirVolumePlugin: false
			allowHostIPC:             false
			allowHostNetwork:         false
			allowHostPID:             false
			allowHostPorts:           false
			allowPrivilegeEscalation: true
			allowPrivilegedContainer: false
			allowedCapabilities: []
			readOnlyRootFilesystem: false
			defaultAddCapabilities: []
			requiredDropCapabilities: ["KILL", "MKNOD", "SETUID", "SETGID"]
			fsGroup: {
				type: "MustRunAs"
				ranges: [{max: minio.securityContext.fsGroup, min: minio.securityContext.fsGroup}]
			}
			runAsUser: {
				type: "MustRunAs"
				uid:  minio.securityContext.runAsUser
			}
			seLinuxContext: type:     "MustRunAs"
			supplementalGroups: type: "RunAsAny"
			volumes: ["configMap", "downwardAPI", "emptyDir", "persistentVolumeClaim", "projected", "secret"]
		}
	}

	// 16. serviceaccount.yaml
	if minio.serviceAccount.create {
		"serviceaccount": corev1.#ServiceAccount & {
			apiVersion: "v1"
			kind:       "ServiceAccount"
			metadata: {
				name:      minio.serviceAccount.name
				namespace: #config.metadata.namespace
			}
		}
	}

	// 17. servicemonitor.yaml
	if minio.metrics.serviceMonitor.enabled {
		"servicemonitor": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "ServiceMonitor"
			metadata: {
				name: "minio"
				namespace: [
					if minio.metrics.serviceMonitor.namespace != "" {minio.metrics.serviceMonitor.namespace},
					#config.metadata.namespace,
				][0]
				labels: _labels & {
					monitoring: "true"
				} & minio.metrics.serviceMonitor.additionalLabels
				if len(minio.metrics.serviceMonitor.annotations) > 0 {
					annotations: minio.metrics.serviceMonitor.annotations
				}
			}
			spec: {
				endpoints: [
					{
						port: [if minio.tls.enabled {"https"}, "http"][0]
						scheme: [if minio.tls.enabled {"https"}, "http"][0]
						path: "/minio/v2/metrics/node"
						if minio.metrics.serviceMonitor.interval != "" {
							interval: minio.metrics.serviceMonitor.interval
						}
						if minio.metrics.serviceMonitor.scrapeTimeout != "" {
							scrapeTimeout: minio.metrics.serviceMonitor.scrapeTimeout
						}
						if len(minio.metrics.serviceMonitor.relabelConfigs) > 0 {
							relabelConfigs: minio.metrics.serviceMonitor.relabelConfigs
						}
					},
				]
				namespaceSelector: matchNames: [#config.metadata.namespace]
				selector: matchLabels: _selectorLabels & {
					monitoring: "true"
				}
			}
		}
	}

	// 18. service.yaml
	"service": corev1.#Service & {
		apiVersion: "v1"
		kind:       "Service"
		metadata: {
			name:      "minio"
			namespace: #config.metadata.namespace
			labels: _labels & {
				monitoring: "true"
			}
			if len(minio.service.annotations) > 0 {
				annotations: minio.service.annotations
			}
		}
		spec: {
			if minio.service.type == "ClusterIP" || minio.service.type == "" {
				type: "ClusterIP"
				if minio.service.clusterIP != "" {
					clusterIP: minio.service.clusterIP
				}
			}
			if minio.service.type == "LoadBalancer" {
				type:           "LoadBalancer"
				loadBalancerIP: minio.service.loadBalancerIP
			}
			if minio.service.type != "ClusterIP" && minio.service.type != "LoadBalancer" && minio.service.type != "" {
				type: minio.service.type
			}
			ports: [
				{
					name: [if minio.tls.enabled {"https"}, "http"][0]
					port:     strconv.Atoi(minio.service.port)
					protocol: "TCP"
					if minio.service.type == "NodePort" && minio.service.nodePort != 0 {
						nodePort: minio.service.nodePort
					}
					if minio.service.type != "NodePort" || minio.service.nodePort == 0 {
						targetPort: strconv.Atoi(minio.minioAPIPort)
					}
				},
			]
			if len(minio.service.externalIPs) > 0 {
				externalIPs: minio.service.externalIPs
			}
			selector: _selectorLabels
		}
	}

	// 19. statefulset.yaml
	if minio.mode == "distributed" {
		"statefulset": appsv1.#StatefulSet & {
			apiVersion: "apps/v1"
			kind:       "StatefulSet"
			metadata: {
				name:      "minio"
				namespace: #config.metadata.namespace
				labels:    _labels
			}
			spec: {
				updateStrategy: type: minio.StatefulSetUpdate.updateStrategy
				serviceName: "minio"
				replicas:    minio.replicas
				selector: matchLabels: _selectorLabels
				template: {
					metadata: {
						name:   "minio"
						labels: _selectorLabels & minio.podLabels
						annotations: {
							if !minio.ignoreChartChecksums {
								"checksum/secrets": "static-checksum-placeholder"
								"checksum/config":  "static-checksum-placeholder"
							}
						} & minio.podAnnotations
					}
					spec: {
						if minio.securityContext.enabled && minio.persistence.enabled {
							securityContext: {
								runAsUser:           minio.securityContext.runAsUser
								runAsGroup:          minio.securityContext.runAsGroup
								fsGroup:             minio.securityContext.fsGroup
								fsGroupChangePolicy: minio.securityContext.fsGroupChangePolicy
							}
						}
						if minio.serviceAccount.create {
							serviceAccountName: minio.serviceAccount.name
						}
						containers: [
							{
								name:            "minio"
								image:           "\(minio.image.repository):\(minio.image.tag)"
								imagePullPolicy: minio.image.pullPolicy
								command: [
									"/bin/sh",
									"-ce",
									"/usr/bin/docker-entrypoint.sh minio server \(strings.Join(_serverArgs, " "))",
								]
								volumeMounts: list.Concat([
									[
										if minio.drivesPerNode > 1 {
											for i in list.Range(0, minio.drivesPerNode, 1) {
												{
													name:      "export-\(i)"
													mountPath: "\(minio.mountPath)-\(i)"
												}
											}
										},
										if minio.drivesPerNode == 1 {
											{
												name:      "export"
												mountPath: minio.mountPath
											}
										},
									],
									minio.extraVolumeMounts,
								])
								ports: [
									{
										name: [if minio.tls.enabled {"https"}, "http"][0]
										containerPort: strconv.Atoi(minio.minioAPIPort)
									},
									{
										name: [if minio.tls.enabled {"https"}, "http"][0] + "-console"
										containerPort: strconv.Atoi(minio.minioConsolePort)
									},
								]
								env:       _env
								resources: minio.resources
							},
						]
						if len(minio.nodeSelector) > 0 {
							nodeSelector: minio.nodeSelector
						}
						if len(minio.affinity) > 0 {
							affinity: minio.affinity
						}
						if len(minio.tolerations) > 0 {
							tolerations: minio.tolerations
						}
						volumes: minio.extraVolumes
					}
				}
				volumeClaimTemplates: [
					if minio.persistence.enabled && minio.persistence.existingClaim == "" {
						if minio.drivesPerNode > 1 {
							for i in list.Range(0, minio.drivesPerNode, 1) {
								corev1.#PersistentVolumeClaim & {
									metadata: {
										name: "export-\(i)"
										labels: {
											app: _selectorLabels.app
										}
										if len(minio.persistence.annotations) > 0 {
											annotations: minio.persistence.annotations
										}
									}
									spec: {
										accessModes: [minio.persistence.accessMode]
										resources: requests: storage: minio.persistence.size
										if minio.persistence.storageClass != "" {
											storageClassName: minio.persistence.storageClass
										}
									}
								}
							}
						}
						if minio.drivesPerNode == 1 {
							corev1.#PersistentVolumeClaim & {
								metadata: {
									name: "export"
									labels: {
										app: _selectorLabels.app
									}
									if len(minio.persistence.annotations) > 0 {
										annotations: minio.persistence.annotations
									}
								}
								spec: {
									accessModes: [minio.persistence.accessMode]
									resources: requests: storage: minio.persistence.size
									if minio.persistence.storageClass != "" {
										storageClassName: minio.persistence.storageClass
									}
								}
							}
						}
					},
				]
			}
		}
	}

	_labels: {
		app:      "minio"
		chart:    "minio-4.0.15"
		release:  #config.metadata.name
		heritage: "timoni"
	}

	_selectorLabels: {
		app:     "minio"
		release: #config.metadata.name
	}

	_serverArgs: [
		if minio.mode == "distributed" {
			let _scheme = [if minio.tls.enabled {"https"}, "http"][0]
			let _nodeCount = math.Floor(minio.replicas / minio.pools)
			for i in list.Range(0, minio.pools, 1) {
				let _beginIndex = i * _nodeCount
				let _endIndex = _beginIndex + _nodeCount - 1
				let _beginStr = strconv.FormatFloat(_beginIndex, 102, 0, 64)
				let _endStr = strconv.FormatFloat(_endIndex, 102, 0, 64)
				let _drivesSuffix = [if minio.drivesPerNode > 1 {
					let _drivesLimit = strconv.FormatFloat(minio.drivesPerNode-1, 102, 0, 64)
					"-{0...\(_drivesLimit)}"
				}, ""][0]
				"\(_scheme)://minio-{\(_beginStr)...\(_endStr)}.minio-svc.\(#config.metadata.namespace).svc.\(minio.clusterDomain)\(minio.mountPath)\(_drivesSuffix)"
			}
		},
		if minio.mode == "standalone" {
			minio.mountPath
		},
		"--address",
		":\(minio.minioAPIPort)",
		"--console-address",
		":\(minio.minioConsolePort)",
		for arg in minio.extraArgs {arg},
	]

	_env: list.Concat([
		[
			{
				name: "MINIO_ROOT_USER"
				valueFrom: secretKeyRef: {
					name: minio.existingSecret | *"minio"
					key:  "rootUser"
				}
			},
			{
				name: "MINIO_ROOT_PASSWORD"
				valueFrom: secretKeyRef: {
					name: minio.existingSecret | *"minio"
					key:  "rootPassword"
				}
			},
		],
		[
			for k, v in minio.environment {
				name:  k
				value: v
			},
		],
	])
}
