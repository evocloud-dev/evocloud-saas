package templates

import (
	"crypto/sha256"
	"encoding/hex"
	"strings"

	corev1 "k8s.io/api/core/v1"
)

#Secret: corev1.#Secret & {
	#config: #Config

	_defaultCode: strings.SliceRunes(hex.Encode(sha256.Sum256(#config.metadata.name + "/" + #config.metadata.namespace + "-siyuan-auth-seed")), 0, 32)
	_code: [
		if #config.auth.accessCode != "" {#config.auth.accessCode},
		_defaultCode,
	][0]

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config.authSecretName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	type: corev1.#SecretTypeOpaque
	stringData: {
		(#config.auth.accessCodeKey): _code
	}
}

