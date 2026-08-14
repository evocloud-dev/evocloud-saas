package templates

import (
	batchv1 "k8s.io/api/batch/v1"
)

#MinioProvisioningJob: batchv1.#Job & {
	#config:    #Config
	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		name:      "\(#config.metadata.name)-minio-provisioning"
		namespace: #config.metadata.namespace
		labels: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-minio-provisioning"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
	spec: {
		template: {
			metadata: {
				labels: {
					"app.kubernetes.io/name":     "\(#config.metadata.name)-minio-provisioning"
					"app.kubernetes.io/instance": #config.metadata.name
				}
			}
			spec: {
				automountServiceAccountToken: false
				restartPolicy: "OnFailure"
				containers: [
					{
						name:  "minio-mc"
						image: "minio/mc:latest"
						command: [
							"/bin/sh",
							"-c",
							"mc alias set myminio http://\(#config.metadata.name)-minio:9000 $(MINIO_ROOT_USER) $(MINIO_ROOT_PASSWORD) && mc mb myminio/\(#config.backend.config.aws.bucketName) || true",
						]
						env: [
							{
								name: "MINIO_ROOT_USER"
								valueFrom: secretKeyRef: {
									name: "\(#config.metadata.name)-minio"
									key:  "rootUser"
								}
							},
							{
								name: "MINIO_ROOT_PASSWORD"
								valueFrom: secretKeyRef: {
									name: "\(#config.metadata.name)-minio"
									key:  "rootPassword"
								}
							},
						]
					},
				]
			}
		}
	}
}
