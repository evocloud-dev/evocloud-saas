package templates

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"list"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#Deployment: appsv1.#Deployment & {
	#config:  #Config
	#cmData:  {...}
	#secData?: {...}

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      #config.fullname
		namespace: #config.namespace
		labels:    #config.labels
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: #config.replicaCount
		strategy: {
			type: #config.deployment.strategy.type
			if #config.deployment.strategy.type == "RollingUpdate" && #config.deployment.strategy.rollingUpdate != _|_ {
				rollingUpdate: {
					maxUnavailable: #config.deployment.strategy.rollingUpdate.maxUnavailable
					maxSurge:       #config.deployment.strategy.rollingUpdate.maxSurge
				}
			}
		}
		selector: matchLabels: #config.selectorLabels
		template: {
			metadata: {
				annotations: {
					"checksum/config": hex.Encode(sha256.Sum256(json.Marshal(#cmData)))
					if #secData != _|_ {
						"checksum/secret": hex.Encode(sha256.Sum256(json.Marshal(#secData)))
					}
					for k, v in #config.podAnnotations {
						"\(k)": v
					}
				}
				labels: {
					#config.selectorLabels
					for k, v in #config.podLabels {
						"\(k)": v
					}
				}
			}
			spec: corev1.#PodSpec & {
				if #config.imagePullSecrets != _|_ && len(#config.imagePullSecrets) > 0 {
					imagePullSecrets: #config.imagePullSecrets
				}
				serviceAccountName: #config.serviceAccountName
				automountServiceAccountToken: #config.serviceAccount.automountServiceAccountToken
				securityContext: #config.podSecurityContext
				initContainers: [
					{
						name:            "wait-for-db"
						image:           "docker.io/library/busybox:1.37"
						imagePullPolicy: "IfNotPresent"
						command: [
							"sh",
							"-c",
							"""
							until nc -z -w2 \(#config.databaseHost) \(#config.databasePort) >/dev/null 2>&1; do
							  echo \"waiting for database...\"; sleep 2;
							done
							""",
						]
						securityContext: #config.containerSecurityContext
						resources: {
							requests: {
								cpu:    "10m"
								memory: "16Mi"
							}
							limits: {
								cpu:    "100m"
								memory: "32Mi"
							}
						}
					},
					{
						name:            "migrate"
						image:           "\(#config.image.repository):\(#config.image.tag)"
						imagePullPolicy: #config.image.pullPolicy
						command: ["sh", "-c", "pnpm exec prisma migrate deploy"]
						env:             #config.databaseEnv
						securityContext: #config.containerSecurityContext
						resources:       #config.resources
					},
					{
						name:            "bootstrap-infra-config"
						image:           "\(#config.image.repository):\(#config.image.tag)"
						imagePullPolicy: #config.image.pullPolicy
						command: [
							"sh",
							"-ec",
							"""
							cd /dist/backend
							node <<'NODE'
							const { PrismaService } = require('./dist/src/prisma/prisma.service');
							const {
							  buildDerivedEnv,
							  disconnectSharedPrismaInstance,
							  getDefaultInfraConfigs,
							  getEncryptionRequiredInfraConfigEntries,
							  getMissingInfraConfigEntries,
							} = require('./dist/src/infra-config/helper');
							const { encrypt } = require('./dist/src/utils');

							async function runSettledOrThrow(operations, description) {
							  const results = await Promise.allSettled(operations);
							  const failures = results.filter((result) => result.status === 'rejected');

							  if (failures.length > 0) {
							    const reasons = failures
							      .map((result) => (result.reason instanceof Error ? result.reason.message : String(result.reason)))
							      .join('; ');
							    throw new Error(`${description} failed for ${failures.length} operation(s): ${reasons}`);
							  }
							}

							async function main() {
							  const prisma = new PrismaService();
							  try {
							    await prisma.onModuleInit();

							    const defaultInfraConfigs = await getDefaultInfraConfigs();
							    const propsToInsert = await getMissingInfraConfigEntries(defaultInfraConfigs);
							    if (propsToInsert.length > 0) {
							      await prisma.infraConfig.createMany({ data: propsToInsert });
							    }

							    const encryptionRequiredEntries = await getEncryptionRequiredInfraConfigEntries(defaultInfraConfigs);
							    await runSettledOrThrow(
							      encryptionRequiredEntries.map((dbConfig) =>
							        prisma.infraConfig.update({
							          where: { name: dbConfig.name },
							          data: {
							            value: dbConfig.value === null ? null : encrypt(dbConfig.value),
							            isEncrypted: true,
							          },
							        })
							      ),
							      'Encrypting infra config entries'
							    );

							    const derivedEnv = await buildDerivedEnv();
							    await runSettledOrThrow(
							      Object.entries(derivedEnv).map(([name, value]) =>
							        prisma.infraConfig.update({
							          where: { name },
							          data: { value },
							        })
							      ),
							      'Updating derived infra config entries'
							    );

							    console.log('Hoppscotch infra config bootstrap completed.');
							  } finally {
							    await disconnectSharedPrismaInstance();
							    await prisma.onModuleDestroy();
							  }
							}

							main().catch((error) => {
							  console.error(error);
							  process.exit(1);
							});
							NODE
							""",
						]
						envFrom: [
							{
								configMapRef: name: #config.fullname
							},
						]
						env:             list.Concat([#config.databaseEnv, [
							{
								name: "DATA_ENCRYPTION_KEY"
								valueFrom: secretKeyRef: {
									name: #config.encryptionSecretName
									key:  #config.encryptionSecretKey
								}
							},
							{
								name: "WEBAPP_SERVER_SIGNING_KEY"
								valueFrom: secretKeyRef: {
									name: #config.signingSecretName
									key:  #config.signingSecretKey
								}
							},
						]])
						securityContext: #config.containerSecurityContext
						resources:       #config.resources
					},
					{
						name:            "prepare-runtime-files"
						image:           "\(#config.image.repository):\(#config.image.tag)"
						imagePullPolicy: #config.image.pullPolicy
						command: [
							"sh",
							"-c",
							"cp -R /dist/backend/. /runtime-backend/ && cp -R /site/. /runtime-site/",
						]
						securityContext: {
							allowPrivilegeEscalation: false
							capabilities: drop: ["ALL"]
							readOnlyRootFilesystem: true
							runAsNonRoot:           true
							runAsUser:              1000
						}
						resources: {
							requests: {
								cpu:    "50m"
								memory: "128Mi"
							}
							limits: {
								cpu:    "500m"
								memory: "512Mi"
							}
						}
						volumeMounts: [
							{
								name:      "backend-runtime"
								mountPath: "/runtime-backend"
							},
							{
								name:      "site-runtime"
								mountPath: "/runtime-site"
							},
						]
					},
					for ic in #config.initContainers {
						ic
					},
				]
				containers: [
					{
						name:            "hoppscotch"
						image:           "\(#config.image.repository):\(#config.image.tag)"
						imagePullPolicy: #config.image.pullPolicy
						securityContext: #config.containerSecurityContext
						ports: [
							{
								name:          "http"
								containerPort: #config.service.containerPort
								protocol:      "TCP"
							},
						]
						envFrom: [
							{
								configMapRef: name: #config.fullname
							},
							for ef in #config.extraEnvFrom {
								ef
							},
						]
						env: list.Concat([#config.databaseEnv, [
							{
								name:  "HOME"
								value: "/tmp"
							},
							{
								name:  "XDG_DATA_HOME"
								value: "/tmp/.local/share"
							},
							{
								name:  "XDG_CONFIG_HOME"
								value: "/tmp/.config"
							},
							{
								name: "DATA_ENCRYPTION_KEY"
								valueFrom: secretKeyRef: {
									name: #config.encryptionSecretName
									key:  #config.encryptionSecretKey
								}
							},
							{
								name: "WEBAPP_SERVER_SIGNING_KEY"
								valueFrom: secretKeyRef: {
									name: #config.signingSecretName
									key:  #config.signingSecretKey
								}
							},
							if #config.auth.github.enabled {
								{
									name: "GITHUB_CLIENT_ID"
									valueFrom: secretKeyRef: {
										name: [if #config.auth.github.existingSecret != "" { #config.auth.github.existingSecret }, #config.fullname][0]
										key:  #config.auth.github.existingSecretClientIdKey
									}
								}
							},
							if #config.auth.github.enabled {
								{
									name: "GITHUB_CLIENT_SECRET"
									valueFrom: secretKeyRef: {
										name: [if #config.auth.github.existingSecret != "" { #config.auth.github.existingSecret }, #config.fullname][0]
										key:  #config.auth.github.existingSecretClientSecretKey
									}
								}
							},
							if #config.auth.google.enabled {
								{
									name: "GOOGLE_CLIENT_ID"
									valueFrom: secretKeyRef: {
										name: [if #config.auth.google.existingSecret != "" { #config.auth.google.existingSecret }, #config.fullname][0]
										key:  #config.auth.google.existingSecretClientIdKey
									}
								}
							},
							if #config.auth.google.enabled {
								{
									name: "GOOGLE_CLIENT_SECRET"
									valueFrom: secretKeyRef: {
										name: [if #config.auth.google.existingSecret != "" { #config.auth.google.existingSecret }, #config.fullname][0]
										key:  #config.auth.google.existingSecretClientSecretKey
									}
								}
							},
							if #config.auth.microsoft.enabled {
								{
									name: "MICROSOFT_CLIENT_ID"
									valueFrom: secretKeyRef: {
										name: [if #config.auth.microsoft.existingSecret != "" { #config.auth.microsoft.existingSecret }, #config.fullname][0]
										key:  #config.auth.microsoft.existingSecretClientIdKey
									}
								}
							},
							if #config.auth.microsoft.enabled {
								{
									name: "MICROSOFT_CLIENT_SECRET"
									valueFrom: secretKeyRef: {
										name: [if #config.auth.microsoft.existingSecret != "" { #config.auth.microsoft.existingSecret }, #config.fullname][0]
										key:  #config.auth.microsoft.existingSecretClientSecretKey
									}
								}
							},
							if #config.mailer.enabled {
								if #config.mailer.useCustomConfigs {
									{
										name: "MAILER_SMTP_PASSWORD"
										valueFrom: secretKeyRef: {
											name: [if #config.mailer.existingSecret != "" { #config.mailer.existingSecret }, #config.fullname][0]
											key:  #config.mailer.existingSecretPasswordKey
										}
									}
								}
							},
							if #config.mailer.enabled {
								if !#config.mailer.useCustomConfigs {
									{
										name: "MAILER_SMTP_URL"
										valueFrom: secretKeyRef: {
											name: [if #config.mailer.existingSecret != "" { #config.mailer.existingSecret }, #config.fullname][0]
											key:  #config.mailer.existingSecretSmtpUrlKey
										}
									}
								}
							},
							for ev in #config.extraEnv {
								ev
							},
						]])
						volumeMounts: [
							{
								name:      "backend-runtime"
								mountPath: "/dist/backend"
							},
							{
								name:      "site-runtime"
								mountPath: "/site"
							},
						]
						livenessProbe: {
							httpGet: {
								if #config.enableSubpathBasedAccess {
									path: "/backend/health"
									port: "http"
								}
								if !#config.enableSubpathBasedAccess {
									path: "/health"
									port: 3170
								}
							}
							initialDelaySeconds: 30
							periodSeconds:        10
							timeoutSeconds:       5
							failureThreshold:     6
						}
						readinessProbe: {
							httpGet: {
								if #config.enableSubpathBasedAccess {
									path: "/backend/health"
									port: "http"
								}
								if !#config.enableSubpathBasedAccess {
									path: "/health"
									port: 3170
								}
							}
							initialDelaySeconds: 15
							periodSeconds:        10
							timeoutSeconds:       5
							failureThreshold:     3
						}
						startupProbe: {
							httpGet: {
								if #config.enableSubpathBasedAccess {
									path: "/backend/health"
									port: "http"
								}
								if !#config.enableSubpathBasedAccess {
									path: "/health"
									port: 3170
								}
							}
							initialDelaySeconds: 20
							periodSeconds:        10
							failureThreshold:     30
						}
						resources: #config.resources
					},
				]
				volumes: [
					{
						name: "backend-runtime"
						emptyDir: {}
					},
					{
						name: "site-runtime"
						emptyDir: {}
					},
				]
				if #config.nodeSelector != _|_ && len(#config.nodeSelector) > 0 {
					nodeSelector: #config.nodeSelector
				}
				if #config.tolerations != _|_ && len(#config.tolerations) > 0 {
					tolerations: #config.tolerations
				}
				if #config.affinity != _|_ && len(#config.affinity) > 0 {
					affinity: #config.affinity
				}
				if #config.topologySpreadConstraints != _|_ && len(#config.topologySpreadConstraints) > 0 {
					topologySpreadConstraints: #config.topologySpreadConstraints
				}
			}
		}
	}
}
