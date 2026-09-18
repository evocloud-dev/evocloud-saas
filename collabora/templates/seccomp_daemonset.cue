package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#SeccompProfileDaemonSet: appsv1.#DaemonSet & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "DaemonSet"
	metadata: {
		name:      "\(#config.metadata.name)-seccomp-profile-installer"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
	spec: appsv1.#DaemonSetSpec & {
		selector: matchLabels: {
			name: "\(#config.metadata.name)-seccomp-installer"
		}
		template: {
			metadata: labels: {
				name: "\(#config.metadata.name)-seccomp-installer"
			}
			spec: corev1.#PodSpec & {
				serviceAccountName: #config._daemonSetServiceAccountName
				containers: [
					{
						name:  "installer"
						image: "docker.io/alpine:latest"
						command: ["/bin/sh", "-c"]
						args: [
							"""
							if [ ! -f /host-seccomp/cool-seccomp-profile.json ]; then
							  wget -O /host-seccomp/cool-seccomp-profile.json \\
							    https://raw.githubusercontent.com/CollaboraOnline/online/main/docker/cool-seccomp-profile.json
							  echo "Profile installed on $(hostname)"
							else
							  echo "Profile already exists on $(hostname)"
							fi
							sleep infinity
							""",
						]
						securityContext: privileged: true
						volumeMounts: [
							{
								name:      "seccomp-profiles"
								mountPath: "/host-seccomp"
							},
						]
					},
				]
				volumes: [
					{
						name: "seccomp-profiles"
						hostPath: {
							path: "/var/lib/kubelet/seccomp"
							type: "DirectoryOrCreate"
						}
					},
				]
				tolerations: [
					{
						operator: "Exists"
					},
				]
			}
		}
	}
}

