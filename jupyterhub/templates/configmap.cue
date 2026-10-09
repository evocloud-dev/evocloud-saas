package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ConfigMap: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      #config.#cmName
		namespace: #config.metadata.namespace
		labels:    #config.#componentLabels & {#component: "hub-config"}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}

	data: {
		"jupyterhub_config.py": """
			import os
			import json

			c.JupyterHub.bind_url = "http://:8081/hub/"
			c.JupyterHub.hub_bind_url = "http://:8081"
			c.JupyterHub.hub_connect_url = "http://\(#config.#hubFullname):8081"
			c.JupyterHub.base_url = "\( #config.hub.baseUrl )"
			\(#config.#dbUrlLine)\(#config.#cookieSecretLine)c.JupyterHub.log_level = "\( #config.hub.logLevel )"
			c.JupyterHub.cleanup_servers = \(#config.#cleanupServersStr)
			c.JupyterHub.authenticate_prometheus = \(#config.#authPrometheusStr)

			c.ConfigurableHTTPProxy.should_start = False
			c.ConfigurableHTTPProxy.api_url = "http://\( #config.#proxyApiFullname ):\( #config.service.proxyApiPort )"
			c.ConfigurableHTTPProxy.auth_token = os.environ["CONFIGPROXY_AUTH_TOKEN"]

			\(#config.#authLines)c.JupyterHub.spawner_class = "kubespawner.KubeSpawner"
			c.KubeSpawner.namespace = os.environ["POD_NAMESPACE"]
			c.KubeSpawner.service_account = "\(#config.#serviceAccountName)"
			c.KubeSpawner.automount_service_account_token = False
			c.KubeSpawner.image = "\( #config.singleuser.image.name ):\( #config.singleuser.image.tag )"
			c.KubeSpawner.image_pull_policy = "\( #config.singleuser.image.pullPolicy )"
			c.KubeSpawner.extra_labels = {
			\(#config.#extraLabelsLines)
			}
			\(#config.#imagePullSecretsLine)c.KubeSpawner.start_timeout = \( #config.singleuser.startTimeout )
			c.KubeSpawner.default_url = "\( #config.singleuser.defaultUrl )"
			c.KubeSpawner.cpu_guarantee = \( #config.singleuser.cpu.guarantee )
			c.KubeSpawner.cpu_limit = \( #config.singleuser.cpu.limit )
			c.KubeSpawner.mem_guarantee = "\( #config.singleuser.memory.guarantee )"
			c.KubeSpawner.mem_limit = "\( #config.singleuser.memory.limit )"
			c.KubeSpawner.uid = 1000
			c.KubeSpawner.gid = 100
			c.KubeSpawner.fs_gid = 100
			\(#config.#singleuserStorageLines)\(#config.#singleuserProfilesLine)\(#config.#hubExtraConfigLines)
			"""
	}
}
