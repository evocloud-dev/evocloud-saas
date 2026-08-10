@extern(embed)
package templates

import (
	"text/template"
	timoniv1 "timoni.sh/core/v1alpha1"
)

_mongodbBackupSh: string @embed(file="mongodb-backup.sh", type=text)
_uploadBackupSh:  string @embed(file="upload-backup.sh", type=text)

#BackupScriptsConfigMap: timoniv1.#ImmutableConfig & {
	#config: #Config
	#Kind:   timoniv1.#ConfigMapKind
	#Meta: {
		#Version:  #config.metadata.#Version
		name:      #config.metadata.name + "-backup-scripts"
		namespace: #config.metadata.namespace
		labels: {
			for k, v in #config.metadata.labels if k != timoniv1.#StdLabelName && k != timoniv1.#StdLabelVersion {
				"\(k)": v
			}
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	#Data: {
		"mongodb-backup.sh": template.Execute(_mongodbBackupSh, #config)
		"upload-backup.sh":  template.Execute(_uploadBackupSh, #config)
	}
}
