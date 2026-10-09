package templates

import (
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/resource"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#PersistentVolumeClaim: corev1.#PersistentVolumeClaim & {
	#config: #Config
	#name:   string
	#item:   #PersistenceItem

	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: #name
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: [#item.accessMode]
		resources: requests: (corev1.#ResourceStorage): resource.#Quantity & {
			#item.size
		}
		if #item.storageClass != _|_ {
			storageClassName: #item.storageClass
		}
	}
}

