{{/*
Expand the name of the chart.
*/}}
{{- define "hievents.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "hievents.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "hievents.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Component name. Call with dict "root" . "component" "backend".
*/}}
{{- define "hievents.componentName" -}}
{{- printf "%s-%s" (include "hievents.fullname" .root) .component | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Migration job name.
Hook jobs keep a stable name so Helm hook delete policies can clean them up.
Regular jobs include the release revision because Job pod templates are immutable.
*/}}
{{- define "hievents.migrationJobName" -}}
{{- if .Values.migration.useHelmHooks -}}
{{ include "hievents.componentName" (dict "root" . "component" "migration") }}
{{- else -}}
{{ printf "%s-%d" (include "hievents.componentName" (dict "root" . "component" "migration")) .Release.Revision | trunc 63 | trimSuffix "-" }}
{{- end -}}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "hievents.labels" -}}
helm.sh/chart: {{ include "hievents.chart" . }}
app.kubernetes.io/name: {{ include "hievents.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.labels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Component labels. Call with dict "root" . "component" "backend".
*/}}
{{- define "hievents.componentLabels" -}}
{{ include "hievents.labels" .root }}
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{/*
Selector labels. Call with dict "root" . "component" "backend".
*/}}
{{- define "hievents.selectorLabels" -}}
app.kubernetes.io/name: {{ include "hievents.name" .root }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{/*
Pod labels. Call with dict "root" . "component" "backend".
*/}}
{{- define "hievents.podLabels" -}}
{{ include "hievents.componentLabels" . }}
{{- with .root.Values.podLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Common annotations.
*/}}
{{- define "hievents.annotations" -}}
{{- with .Values.commonAnnotations }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Pod annotations.
*/}}
{{- define "hievents.podAnnotations" -}}
{{ include "hievents.annotations" . }}
{{- with .Values.podAnnotations }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Service account name.
*/}}
{{- define "hievents.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "hievents.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Application config map name.
*/}}
{{- define "hievents.configMapName" -}}
{{ include "hievents.fullname" . }}-config
{{- end }}

{{- define "hievents.nginxConfigMapName" -}}
{{ include "hievents.fullname" . }}-configmap-nginx
{{- end }}

{{- define "hievents.nginxDeploymentName" -}}
{{ include "hievents.fullname" . }}-deployment-nginx
{{- end }}

{{- define "hievents.nginxServiceName" -}}
{{ include "hievents.fullname" . }}-service-nginx
{{- end }}

{{/*
Secret names.
*/}}
{{- define "hievents.appSecretName" -}}
{{- if .Values.secrets.app.useExisting -}}
{{ .Values.secrets.app.secretName }}
{{- else -}}
{{ include "hievents.fullname" . }}-{{ .Values.secrets.app.secretName }}
{{- end -}}
{{- end }}

{{- define "hievents.postgresqlSecretName" -}}
{{- if .Values.secrets.postgresql.useExisting -}}
{{ .Values.secrets.postgresql.secretName }}
{{- else -}}
{{ include "hievents.fullname" . }}-{{ .Values.secrets.postgresql.secretName }}
{{- end -}}
{{- end }}

{{- define "hievents.redisSecretName" -}}
{{- if .Values.secrets.redis.useExisting -}}
{{ .Values.secrets.redis.secretName }}
{{- else -}}
{{ include "hievents.fullname" . }}-{{ .Values.secrets.redis.secretName }}
{{- end -}}
{{- end }}

{{- define "hievents.s3SecretName" -}}
{{- if .Values.secrets.s3.useExisting -}}
{{ .Values.secrets.s3.secretName }}
{{- else -}}
{{ include "hievents.fullname" . }}-{{ .Values.secrets.s3.secretName }}
{{- end -}}
{{- end }}

{{- define "hievents.mailSecretName" -}}
{{- if .Values.secrets.mail.useExisting -}}
{{ .Values.secrets.mail.secretName }}
{{- else -}}
{{ include "hievents.fullname" . }}-{{ .Values.secrets.mail.secretName }}
{{- end -}}
{{- end }}

{{/*
Service hosts.
*/}}
{{- define "hievents.databaseHost" -}}
{{- if .Values.postgresql.enabled -}}
{{ include "hievents.fullname" . }}-postgresql
{{- else -}}
{{ .Values.externalDatabase.host }}
{{- end -}}
{{- end }}

{{- define "hievents.redisHost" -}}
{{- if .Values.redis.enabled -}}
{{ include "hievents.fullname" . }}-redis
{{- else -}}
{{ .Values.externalRedis.host }}
{{- end -}}
{{- end }}

{{/*
Internal backend service URL for the frontend.
*/}}
{{- define "hievents.backendInternalUrl" -}}
{{- printf "http://%s" (include "hievents.componentName" (dict "root" . "component" "backend")) -}}
{{- end }}

{{- define "hievents.nginxInternalUrl" -}}
{{- printf "http://%s" (include "hievents.nginxServiceName" .) -}}
{{- end }}

{{/*
Extract host from APP_URL for probes.
*/}}
{{- define "hievents.appHost" -}}
{{- .Values.hieventsConfig.app.url | replace "https://" "" | replace "http://" "" | splitList "/" | first -}}
{{- end }}

{{/*
Render image reference. Call with .Values.backend.image or another image object.
*/}}
{{- define "hievents.image" -}}
{{- if .digest -}}
{{- if .registry -}}
{{ printf "%s/%s@%s" .registry .repository .digest }}
{{- else -}}
{{ printf "%s@%s" .repository .digest }}
{{- end -}}
{{- else -}}
{{- if .registry -}}
{{ printf "%s/%s:%s" .registry .repository (.tag | default "latest") }}
{{- else -}}
{{ printf "%s:%s" .repository (.tag | default "latest") }}
{{- end -}}
{{- end -}}
{{- end }}

{{/*
Image pull secrets.
*/}}
{{- define "hievents.imagePullSecrets" -}}
{{- with .Values.imagePullSecrets }}
imagePullSecrets:
{{ toYaml . | indent 2 }}
{{- end }}
{{- end }}

{{/*
Common pod scheduling fields. Call with dict "root" . "componentValues" .Values.backend.
*/}}
{{- define "hievents.podScheduling" -}}
{{- with .componentValues.nodeSelector }}
nodeSelector:
{{ toYaml . | nindent 2 }}
{{- end }}
{{- with .componentValues.affinity }}
affinity:
{{ toYaml . | nindent 2 }}
{{- end }}
{{- with .componentValues.tolerations }}
tolerations:
{{ toYaml . | nindent 2 }}
{{- end }}
{{- with .componentValues.topologySpreadConstraints }}
topologySpreadConstraints:
{{ toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Shared Laravel environment variables.
*/}}
{{- define "hievents.storagePublicDisk" -}}
{{- if .Values.hieventsConfig.storage.publicDisk -}}
{{ .Values.hieventsConfig.storage.publicDisk }}
{{- else if eq .Values.hieventsConfig.storage.driver "local" -}}
public
{{- else -}}
s3-public
{{- end -}}
{{- end }}

{{- define "hievents.storagePrivateDisk" -}}
{{- if .Values.hieventsConfig.storage.privateDisk -}}
{{ .Values.hieventsConfig.storage.privateDisk }}
{{- else if eq .Values.hieventsConfig.storage.driver "local" -}}
local
{{- else -}}
s3-private
{{- end -}}
{{- end }}

{{- define "hievents.storageDisk" -}}
{{- if .Values.hieventsConfig.storage.disk -}}
{{ .Values.hieventsConfig.storage.disk }}
{{- else if eq .Values.hieventsConfig.storage.driver "local" -}}
public
{{- else -}}
s3
{{- end -}}
{{- end }}

{{- define "hievents.env.laravelVariables" -}}
- name: APP_NAME
  value: {{ .Values.hieventsConfig.app.name | quote }}
- name: APP_ENV
  value: {{ .Values.hieventsConfig.app.env | quote }}
- name: APP_DEBUG
  value: {{ .Values.hieventsConfig.app.debug | quote }}
- name: APP_URL
  value: {{ .Values.hieventsConfig.app.url | quote }}
- name: APP_FRONTEND_URL
  value: {{ .Values.hieventsConfig.app.frontendUrl | quote }}
- name: APP_TIMEZONE
  value: {{ .Values.hieventsConfig.app.timezone | quote }}
- name: APP_LOCALE
  value: {{ .Values.hieventsConfig.app.locale | quote }}
- name: VITE_API_URL
  value: {{ .Values.hieventsConfig.app.viteApiUrlClient | default (printf "%s/api" .Values.hieventsConfig.app.url) | quote }}
- name: VITE_API_URL_CLIENT
  value: {{ .Values.hieventsConfig.app.viteApiUrlClient | default (printf "%s/api" .Values.hieventsConfig.app.url) | quote }}
- name: VITE_FRONTEND_URL
  value: {{ .Values.hieventsConfig.app.viteFrontendUrl | default .Values.hieventsConfig.app.frontendUrl | quote }}
- name: SANCTUM_STATEFUL_DOMAINS
  value: {{ .Values.hieventsConfig.app.sanctumStatefulDomains | quote }}
{{ if .Values.hieventsConfig.app.sessionDomain }}
- name: SESSION_DOMAIN
  value: {{ .Values.hieventsConfig.app.sessionDomain | quote }}
{{ end }}
- name: CORS_ALLOWED_ORIGINS
  value: {{ printf "%s,%s" .Values.hieventsConfig.app.url .Values.hieventsConfig.app.frontendUrl | quote }}
- name: TRUSTED_PROXIES
  value: {{ .Values.hieventsConfig.app.trustedProxies | quote }}
- name: SESSION_SECURE_COOKIE
  value: {{ eq .Values.hieventsConfig.app.env "local" | ternary "false" "true" | quote }}
{{- if .Values.hieventsConfig.app.cdnUrl }}
- name: APP_CDN_URL
  value: {{ .Values.hieventsConfig.app.cdnUrl | quote }}
{{- end }}
- name: APP_LOG_QUERIES
  value: {{ .Values.hieventsConfig.app.logQueries | quote }}
- name: APP_HOMEPAGE_VIEWS_UPDATE_BATCH_SIZE
  value: {{ .Values.hieventsConfig.app.homepageViewsUpdateBatchSize | quote }}
- name: APP_ALLOWED_INTERNAL_WEBHOOK_HOSTS
  value: {{ .Values.hieventsConfig.app.allowedInternalWebhookHosts | quote }}
{{- if .Values.hieventsConfig.app.emailLogoUrl }}
- name: APP_EMAIL_LOGO_URL
  value: {{ .Values.hieventsConfig.app.emailLogoUrl | quote }}
{{- end }}
{{- if .Values.hieventsConfig.app.emailLogoLinkUrl }}
- name: APP_EMAIL_LOGO_LINK_URL
  value: {{ .Values.hieventsConfig.app.emailLogoLinkUrl | quote }}
{{- end }}
- name: APP_DISABLE_REGISTRATION
  value: {{ .Values.hieventsConfig.app.disableRegistration | quote }}
- name: APP_PLATFORM_SUPPORT_EMAIL
  value: {{ .Values.hieventsConfig.app.platformSupportEmail | quote }}
- name: APP_SAAS_MODE_ENABLED
  value: {{ .Values.hieventsConfig.app.saasModeEnabled | quote }}
- name: APP_SAAS_STRIPE_APPLICATION_FEE_PERCENT
  value: {{ .Values.hieventsConfig.app.saasStripeApplicationFeePercent | quote }}
- name: APP_SAAS_STRIPE_APPLICATION_FEE_FIXED
  value: {{ .Values.hieventsConfig.app.saasStripeApplicationFeeFixed | quote }}
- name: APP_STRIPE_CONNECT_ACCOUNT_TYPE
  value: {{ .Values.hieventsConfig.app.stripeConnectAccountType | quote }}
- name: LOG_CHANNEL
  value: {{ .Values.hieventsConfig.logging.channel | quote }}
- name: LOG_LEVEL
  value: {{ .Values.hieventsConfig.logging.level | quote }}
{{- if .Values.hieventsConfig.logging.deprecationsChannel }}
- name: LOG_DEPRECATIONS_CHANNEL
  value: {{ .Values.hieventsConfig.logging.deprecationsChannel | quote }}
{{- end }}
- name: QUEUE_CONNECTION
  value: {{ .Values.hieventsConfig.queue.connection | quote }}
- name: WEBHOOK_QUEUE_NAME
  value: {{ .Values.hieventsConfig.queue.webhookQueueName | quote }}
- name: CACHE_DRIVER
  value: {{ .Values.hieventsConfig.cache.driver | quote }}
- name: SESSION_DRIVER
  value: {{ .Values.hieventsConfig.session.driver | quote }}
- name: SESSION_LIFETIME
  value: {{ .Values.hieventsConfig.session.lifetime | quote }}
- name: BROADCAST_DRIVER
  value: {{ .Values.hieventsConfig.broadcast.driver | quote }}
- name: FILESYSTEM_DISK
  value: {{ include "hievents.storageDisk" . | quote }}
- name: FILESYSTEM_DRIVER
  value: {{ .Values.hieventsConfig.storage.filesystemDriver | default (include "hievents.storageDisk" .) | quote }}
- name: FILESYSTEM_PUBLIC_DISK
  value: {{ include "hievents.storagePublicDisk" . | quote }}
- name: FILESYSTEM_PRIVATE_DISK
  value: {{ include "hievents.storagePrivateDisk" . | quote }}
- name: APP_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "hievents.appSecretName" . }}
      key: {{ .Values.secrets.app.appKeySecretKey  }}
- name: JWT_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ include "hievents.appSecretName" . }}
      key: {{ .Values.secrets.app.jwtSecretKey }}
- name: JWT_ALGO
  value: {{ .Values.hieventsConfig.jwt.algo | quote }}
{{ include "hievents.env.stripeVariables" . }}
{{ include "hievents.env.mailVariables" . }}
{{- end }}

{{/*
Stripe environment variables.
*/}}
{{- define "hievents.env.stripeVariables" -}}
{{- if .Values.secrets.app.stripePublishableKey }}
- name: STRIPE_PUBLIC_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "hievents.appSecretName" . }}
      key: {{ .Values.secrets.app.stripePublishableKeyKey }}
- name: STRIPE_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "hievents.appSecretName" . }}
      key: {{ .Values.secrets.app.stripePublishableKeyKey }}
{{- end }}
{{- if .Values.secrets.app.stripeSecretKey }}
- name: STRIPE_SECRET_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "hievents.appSecretName" . }}
      key: {{ .Values.secrets.app.stripeSecretKeyKey }}
- name: STRIPE_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ include "hievents.appSecretName" . }}
      key: {{ .Values.secrets.app.stripeSecretKeyKey }}
{{- end }}
{{- if .Values.secrets.app.stripeWebhookSecret }}
- name: STRIPE_WEBHOOK_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ include "hievents.appSecretName" . }}
      key: {{ .Values.secrets.app.stripeWebhookSecretKey }}
{{- end }}
{{- end }}


{{/*
Laravel database environment variables.
*/}}
{{- define "hievents.env.databaseVariables" -}}
- name: DB_CONNECTION
  value: "pgsql"
- name: DB_HOST
  value: {{ include "hievents.databaseHost" . | quote }}
- name: DB_PORT
  value: {{ .Values.hieventsConfig.postgresql.port | quote }}
- name: DB_DATABASE
  value: {{ .Values.hieventsConfig.postgresql.database | quote }}
- name: DB_USERNAME
  value: {{ .Values.hieventsConfig.postgresql.username | quote }}
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "hievents.postgresqlSecretName" . }}
      key: {{ .Values.secrets.postgresql.passwordKey }}
- name: DATABASE_URL
  value: {{ .Values.hieventsConfig.postgresql.databaseUrl | quote }}
{{- end }}

{{/*
Mail environment variables.
*/}}
{{- define "hievents.env.mailVariables" -}}
- name: MAIL_MAILER
  value: {{ .Values.hieventsConfig.mail.mailer | quote }}
- name: MAIL_DRIVER
  value: {{ .Values.hieventsConfig.mail.driver | default .Values.hieventsConfig.mail.mailer | quote }}
- name: MAIL_HOST
  value: {{ .Values.hieventsConfig.mail.host | quote }}
- name: MAIL_PORT
  value: {{ .Values.hieventsConfig.mail.port | quote }}
- name: MAIL_USERNAME
  value: {{ .Values.hieventsConfig.mail.username | quote }}
- name: MAIL_ENCRYPTION
  value: {{ .Values.hieventsConfig.mail.encryption | quote }}
- name: MAIL_FROM_ADDRESS
  value: {{ .Values.hieventsConfig.mail.fromAddress | quote }}
- name: MAIL_FROM_NAME
  value: {{ .Values.hieventsConfig.mail.fromName | quote }}
{{- if or .Values.secrets.mail.password .Values.secrets.mail.useExisting }}
- name: MAIL_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "hievents.mailSecretName" . }}
      key: {{ .Values.secrets.mail.passwordKey }}
{{- end }}
{{- end }}

{{/*
Redis environment variables. Sentinel is intentionally omitted unless the application config supports it.
*/}}
{{- define "hievents.env.redisVariables" -}}
- name: REDIS_HOST
  value: {{ include "hievents.redisHost" . | quote }}
- name: REDIS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "hievents.redisSecretName" . }}
      key: {{ .Values.secrets.redis.passwordKey }}
- name: REDIS_PORT
  value: {{ .Values.hieventsConfig.redis.port | quote }}
- name: REDIS_CLIENT
  value: {{ .Values.hieventsConfig.redis.client | default "phpredis" | quote }}
- name: REDIS_DB
  value: {{ .Values.hieventsConfig.redis.database | quote }}
- name: REDIS_CACHE_DB
  value: {{ .Values.hieventsConfig.redis.cacheDatabase | quote }}
{{- if .Values.hieventsConfig.redis.username }}
- name: REDIS_USERNAME
  value: {{ .Values.hieventsConfig.redis.username | quote }}
- name: REDIS_USER
  value: {{ .Values.hieventsConfig.redis.username | quote }}
{{- end }}
{{- if .Values.hieventsConfig.redis.url }}
- name: REDIS_URL
  value: {{ .Values.hieventsConfig.redis.url | quote }}
{{- end }}
{{- end }}

{{/*
S3 / object storage environment variables.
*/}}
{{- define "hievents.env.s3Variables" -}}
{{- if eq .Values.hieventsConfig.storage.driver "s3" }}
- name: AWS_DEFAULT_REGION
  value: {{ .Values.hieventsConfig.s3.region | quote }}
- name: AWS_PUBLIC_BUCKET
  value: {{ .Values.hieventsConfig.s3.publicBucket | quote }}
- name: AWS_PRIVATE_BUCKET
  value: {{ .Values.hieventsConfig.s3.privateBucket | quote }}
{{- if .Values.hieventsConfig.s3.endpoint }}
- name: AWS_ENDPOINT
  value: {{ .Values.hieventsConfig.s3.endpoint | quote }}
{{- end }}
{{- if .Values.hieventsConfig.s3.url }}
- name: AWS_URL
  value: {{ .Values.hieventsConfig.s3.url | quote }}
{{- end }}
- name: AWS_USE_PATH_STYLE_ENDPOINT
  value: {{ .Values.hieventsConfig.s3.usePathStyleEndpoint | quote }}
- name: AWS_ACCESS_KEY_ID
  valueFrom:
    secretKeyRef:
      name: {{ include "hievents.s3SecretName" . }}
      key: {{ .Values.secrets.s3.accessKeyIdKey }}
- name: AWS_SECRET_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "hievents.s3SecretName" . }}
      key: {{ .Values.secrets.s3.secretAccessKeyKey }}
{{- end }}
{{- end }}

{{/*
Backend storage PVC name.
*/}}
{{- define "hievents.localStorageEnabled" -}}
{{- if and .Values.backend.enabled .Values.backend.persistence.enabled (eq .Values.hieventsConfig.storage.driver "local") -}}
true
{{- end -}}
{{- end }}

{{- define "hievents.backendStorageClaimName" -}}
{{- if .Values.backend.persistence.existingClaim -}}
{{ .Values.backend.persistence.existingClaim }}
{{- else -}}
{{ include "hievents.componentName" (dict "root" . "component" "backend-storage") }}
{{- end -}}
{{- end }}

{{- define "hievents.backendStorageVolumeMounts" -}}
{{- if include "hievents.localStorageEnabled" . }}
volumeMounts:
  - name: storage
    mountPath: {{ .Values.backend.persistence.mountPath }}
{{- end }}
{{- end }}

{{- define "hievents.backendStorageVolumes" -}}
{{- if include "hievents.localStorageEnabled" . }}
volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: {{ include "hievents.backendStorageClaimName" . }}
{{- end }}
{{- end }}

{{/*
Frontend environment variables.
*/}}
{{- define "hievents.env.frontendVariables" -}}
- name: VITE_API_URL
  value: {{ .Values.hieventsConfig.app.viteApiUrlClient | default (printf "%s/api" .Values.hieventsConfig.app.url) | quote }}
- name: VITE_API_URL_CLIENT
  value: {{ .Values.hieventsConfig.app.viteApiUrlClient | default (printf "%s/api" .Values.hieventsConfig.app.url) | quote }}
- name: VITE_API_URL_SERVER
  value: {{ .Values.hieventsConfig.app.viteApiUrlServer | default (printf "%s/api" ( .Values.frontend.env.viteApiUrlServer | default (ternary (include "hievents.nginxInternalUrl" .) (include "hievents.backendInternalUrl" .) .Values.webProxy.enabled) )) | quote }}
- name: VITE_FRONTEND_URL
  value: {{ .Values.hieventsConfig.app.viteFrontendUrl | default .Values.hieventsConfig.app.frontendUrl | quote }}
- name: VITE_APP_NAME
  value: {{ .Values.hieventsConfig.app.name | quote }}
- name: NODE_PORT
  value: {{ .Values.frontend.service.targetPort | quote }}
- name: VITE_STRIPE_PUBLISHABLE_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "hievents.appSecretName" . }}
      key: {{ .Values.secrets.app.stripePublishableKeyKey }}
{{- end }}

{{/*
Wait for PostgreSQL init container.
*/}}
{{- define "hievents.initContainers.waitForPostgresql" -}}
- name: wait-for-postgresql
  image: {{ .Values.initContainers.postgresql.image | quote }}
  imagePullPolicy: {{ .Values.initContainers.postgresql.imagePullPolicy | quote }}
  env:
    - name: PGPASSWORD
      valueFrom:
        secretKeyRef:
          name: {{ include "hievents.postgresqlSecretName" . }}
          key: {{ .Values.secrets.postgresql.passwordKey }}
  command:
    - sh
    - -c
    - |
      until pg_isready -h {{ include "hievents.databaseHost" . }} -p {{ .Values.hieventsConfig.postgresql.port }} -U {{ .Values.hieventsConfig.postgresql.username }} -d {{ .Values.hieventsConfig.postgresql.database }}; do
        echo "waiting for postgresql"
        sleep 2
      done
{{- end }}

{{/*
Wait for Redis init container.
*/}}
{{- define "hievents.initContainers.waitForRedis" -}}
- name: wait-for-redis
  image: {{ .Values.initContainers.redis.image | quote }}
  imagePullPolicy: {{ .Values.initContainers.redis.imagePullPolicy | quote }}
  env:
    - name: REDISCLI_AUTH
      valueFrom:
        secretKeyRef:
          name: {{ include "hievents.redisSecretName" . }}
          key: {{ .Values.secrets.redis.passwordKey }}
  command:
    - sh
    - -c
    - |
      until redis-cli -h {{ include "hievents.redisHost" . }} -p {{ .Values.hieventsConfig.redis.port }} ping; do
        echo "waiting for redis"
        sleep 2
      done
{{- end }}
