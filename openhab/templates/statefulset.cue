package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#StatefulSetBuilder: {
	_config: #Config

	_hasSitemaps: _config.configMaps.sitemaps.enabled && len(_config.configMaps.sitemaps.files) > 0
	_hasThings:   _config.configMaps.things.enabled && len(_config.configMaps.things.files) > 0
	_hasItems:    _config.configMaps.items.enabled && len(_config.configMaps.items.files) > 0
	_hasConfigMaps: _hasSitemaps || _hasThings || _hasItems

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      _config.fullname
		namespace: _config.namespace
		labels:    _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	spec: appsv1.#StatefulSetSpec & {
		// openHAB does not support horizontal scaling - always 1 replica
		replicas:    1
		serviceName: _config.fullname
		selector: {
			matchLabels: _config.selector.labels
		}
		template: corev1.#PodTemplateSpec & {
			metadata: {
				labels: _config.selector.labels & _config.podLabels
				annotations: {
					if _config.metrics.enabled && _config.metrics.podAnnotations.enabled {
						"prometheus.io/scrape": "true"
						"prometheus.io/path":   "/rest/metrics/prometheus"
						"prometheus.io/port":   "\(_config.service.port)"
					}
					for k, v in _config.podAnnotations {
						"\(k)": v
					}
				}
			}
			spec: corev1.#PodSpec & {
				if _config.imagePullSecrets != _|_ && len(_config.imagePullSecrets) > 0 {
					imagePullSecrets: _config.imagePullSecrets
				}
				serviceAccountName:           _config.serviceAccountName
				automountServiceAccountToken: _config.serviceAccount.automountServiceAccountToken
				securityContext:              _config.podSecurityContext

				if _hasConfigMaps {
					initContainers: [{
						name:            "sync-configmaps"
						image:           "\(_config.configMaps.syncImage.repository):\(_config.configMaps.syncImage.tag)"
						imagePullPolicy: _config.configMaps.syncImage.pullPolicy
						command: [
							"/bin/sh",
							"-ec",
							"""
							mkdir -p /openhab/conf/sitemaps /openhab/conf/things /openhab/conf/items
							if [ -d /config-src/sitemaps ]; then cp -f /config-src/sitemaps/* /openhab/conf/sitemaps/ 2>/dev/null || true; fi
							if [ -d /config-src/things ]; then cp -f /config-src/things/* /openhab/conf/things/ 2>/dev/null || true; fi
							if [ -d /config-src/items ]; then cp -f /config-src/items/* /openhab/conf/items/ 2>/dev/null || true; fi
							""",
						]
						resources: _config.configMaps.syncResources
						securityContext: allowPrivilegeEscalation: false
						volumeMounts: [
							{
								name:      "conf"
								mountPath: "/openhab/conf"
							},
							if _hasSitemaps {
								name:      "sitemaps"
								mountPath: "/config-src/sitemaps"
								readOnly:  true
							},
							if _hasThings {
								name:      "things"
								mountPath: "/config-src/things"
								readOnly:  true
							},
							if _hasItems {
								name:      "items"
								mountPath: "/config-src/items"
								readOnly:  true
							},
						]
					}]
				}

				containers: [{
					name:            "openhab"
					image:           "\(_config.image.repository):\(_config.image.tag)"
					imagePullPolicy: _config.image.pullPolicy
					securityContext: _config.securityContext
					ports: [
						{
							name:          "http"
							containerPort: _config.service.port
							protocol:      "TCP"
						},
						if _config.karaf.enabled {
							name:          "karaf"
							containerPort: _config.karaf.service.port
							protocol:      "TCP"
						},
					]
					env: [
						{name: "TZ", value: _config.env.TZ},
						{name: "EXTRA_JAVA_OPTS", value: _config.env.EXTRA_JAVA_OPTS},
						{name: "OPENHAB_HTTP_PORT", value: "\(_config.env.OPENHAB_HTTP_PORT)"},
						{name: "OPENHAB_HTTPS_PORT", value: "\(_config.env.OPENHAB_HTTPS_PORT)"},
						for e in _config.extraEnv {e},
					]
					startupProbe:  _config.startupProbe
					livenessProbe: _config.livenessProbe
					readinessProbe: _config.readinessProbe
					if _config.resources != _|_ {
						resources: _config.resources
					}
					volumeMounts: [
						if _config.persistence.userdata.enabled {
							name:      "userdata"
							mountPath: "/openhab/userdata"
						},
						if _config.persistence.conf.enabled {
							name:      "conf"
							mountPath: "/openhab/conf"
						},
						if _config.persistence.addons.enabled {
							name:      "addons"
							mountPath: "/openhab/addons"
						},
						for vm in _config.extraVolumeMounts {vm},
					]
				}]

				volumes: [
					if _config.persistence.userdata.enabled {
						name: "userdata"
						persistentVolumeClaim: claimName: _config.userdataPvcName
					},
					if _config.persistence.conf.enabled {
						name: "conf"
						persistentVolumeClaim: claimName: _config.confPvcName
					},
					if _config.persistence.addons.enabled {
						name: "addons"
						persistentVolumeClaim: claimName: _config.addonsPvcName
					},
					if _hasSitemaps {
						name: "sitemaps"
						configMap: name: "\(_config.fullname)-sitemaps"
					},
					if _hasThings {
						name: "things"
						configMap: name: "\(_config.fullname)-things"
					},
					if _hasItems {
						name: "items"
						configMap: name: "\(_config.fullname)-items"
					},
					for v in _config.extraVolumes {v},
				]

				if len(_config.nodeSelector) > 0 {
					nodeSelector: _config.nodeSelector
				}
				if _config.affinity != _|_ {
					affinity: _config.affinity
				}
				if _config.tolerations != _|_ && len(_config.tolerations) > 0 {
					tolerations: _config.tolerations
				}
			}
		}
	}
}
