package templates

import (
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
)

#PostgresMigrationJob: {
	#config: #Config
	#helpers: #Helpers

	job: {
		apiVersion: "batch/v1"
		kind:       "Job"
		metadata: {
			name:      "\(#helpers.fullname)-postgres-migration"
			namespace: #config.metadata.namespace
			labels:    #helpers.labels
		}
		spec: batchv1.#JobSpec & {
			ttlSecondsAfterFinished: 300
			activeDeadlineSeconds:   300
			backoffLimit:            3
			template: {
				metadata: name: "postgres-migration"
				spec: corev1.#PodSpec & {
					restartPolicy:      "OnFailure"
					serviceAccountName: "\(#helpers.fullname)-migration"
					securityContext: #config.podSecurityContext
					containers: [{
						name:  "migrate"
						image: #config.postgres.migration.image
						securityContext: #config.securityContext
						args: [
							"delete",
							"statefulset",
							"-n",
							"\(#config.metadata.namespace)",
							"-l",
							"app.kubernetes.io/name=\(#helpers.name),app.kubernetes.io/managed-by=Helm",
							"--cascade=orphan",
							"--ignore-not-found",
						]
						volumeMounts: [
							if #config.securityContext.readOnlyRootFilesystem != _|_ && #config.securityContext.readOnlyRootFilesystem == true {
								{
									name:      "tmp"
									mountPath: "/tmp"
								}
							},
						]
					}]
					volumes: [
						if #config.securityContext.readOnlyRootFilesystem != _|_ && #config.securityContext.readOnlyRootFilesystem == true {
							{
								name: "tmp"
								emptyDir: {}
							}
						},
					]
				}
			}
		}
	}

	sa: {
		apiVersion: "v1"
		kind:       "ServiceAccount"
		metadata: {
			name:      "\(#helpers.fullname)-migration"
			namespace: #config.metadata.namespace
		}
	}

	role: {
		apiVersion: "rbac.authorization.k8s.io/v1"
		kind:       "Role"
		metadata: {
			name:      "\(#helpers.fullname)-migration"
			namespace: #config.metadata.namespace
		}
		rules: [{
			apiGroups: ["apps"]
			resources: ["statefulsets"]
			verbs: ["get", "list", "delete", "patch"]
		}, {
			apiGroups: ["apps"]
			resources: ["statefulsets/scale"]
			verbs: ["get", "patch", "update"]
		}, {
			apiGroups: [""]
			resources: ["pods"]
			verbs: ["get", "list", "watch"]
		}]
	}

	rolebinding: {
		apiVersion: "rbac.authorization.k8s.io/v1"
		kind:       "RoleBinding"
		metadata: {
			name:      "\(#helpers.fullname)-migration"
			namespace: #config.metadata.namespace
		}
		roleRef: {
			apiGroup: "rbac.authorization.k8s.io"
			kind:     "Role"
			name:     "\(#helpers.fullname)-migration"
		}
		subjects: [{
			kind:      "ServiceAccount"
			name:      "\(#helpers.fullname)-migration"
			namespace: #config.metadata.namespace
		}]
	}
}
