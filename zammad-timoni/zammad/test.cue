package main

import (
	corev1 "k8s.io/api/core/v1"
)

probe: corev1.#Probe
probe: {
	tcpSocket: port: 8080
}
