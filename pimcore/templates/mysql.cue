package templates

import (
    appsv1 "k8s.io/api/apps/v1"
    corev1 "k8s.io/api/core/v1"
)

#MySQLStatefulSet: appsv1.#StatefulSet & {
    #config: #Config
    apiVersion: "apps/v1"
    kind:       "StatefulSet"
    metadata: {
        name:      "mysql-mariadb"
        namespace: #config.metadata.namespace
        labels:    #config.metadata.labels
    }
    spec: appsv1.#StatefulSetSpec & {
        serviceName: "mysql-mariadb-headless"
        replicas:    #config.mysql.replicas
        selector: matchLabels: {
            "app.kubernetes.io/name":     "mariadb"
            "app.kubernetes.io/instance": "mysql"
            "app.kubernetes.io/component": "primary"
        }
        template: {
            metadata: {
                labels: {
                    "app.kubernetes.io/name":     "mariadb"
                    "app.kubernetes.io/instance": "mysql"
                    "app.kubernetes.io/component": "primary"
                }
            }
            spec: corev1.#PodSpec & {
                containers: [
                    {
                        name:            "mariadb"
                        image:           "\(#config.mysql.image.registry):\(#config.mysql.image.tag)"
                        imagePullPolicy: #config.mysql.image.pullPolicy
                        ports: [
                            {
                                containerPort: 3306
                                name:          "mysql"
                            },
                        ]
                        env: [
                            {
                                name:  "MARIADB_ROOT_PASSWORD"
                                value: "#config.pimcore.db.root_password"
                            },
                            {
                                name:  "MARIADB_DATABASE"
                                value: #config.pimcore.db.name
                            },
                            {
                                name:  "MARIADB_USER"
                                value: #config.pimcore.db.username
                            },
                            {
                                name:  "MARIADB_PASSWORD"
                                value: #config.pimcore.db.password
                            },
                        ]
                        volumeMounts: [
                            {
                                name:      "mysql-data"
                                mountPath: "/bitnami/mariadb"
                            },
                        ]
                        if #config.mysql.resources != _|_ {
                            resources: #config.mysql.resources
                        }
                    },
                ]
            }
        }
        volumeClaimTemplates: [
            corev1.#PersistentVolumeClaim & {
                metadata: name: "mysql-data"
                spec: corev1.#PersistentVolumeClaimSpec & {
                    accessModes: [#config.pvc.mysql.accessMode]
                    resources: {
                        requests: storage: #config.pvc.mysql.storage
                    }
                    if #config.pvc.mysql.storageClass != "" {
                        storageClassName: #config.pvc.mysql.storageClass
                    }
                }
            },
        ]
    }
}

#MySQLHeadlessService: corev1.#Service & {
    #config: #Config
    apiVersion: "v1"
    kind:       "Service"
    metadata: {
        name:      "mysql-mariadb-headless"
        namespace: #config.metadata.namespace
        labels:    #config.metadata.labels
    }
    spec: corev1.#ServiceSpec & {
        clusterIP: "None"
        selector: {
            "app.kubernetes.io/name":     "mariadb"
            "app.kubernetes.io/instance": "mysql"
            "app.kubernetes.io/component": "primary"
        }
        ports: [
            {
                name:       "mysql"
                port:       3306
                targetPort: 3306
            },
        ]
    }
}

#MySQLService: corev1.#Service & {
    #config: #Config
    apiVersion: "v1"
    kind:       "Service"
    metadata: {
        name:      "mysql-mariadb"
        namespace: #config.metadata.namespace
        labels:    #config.metadata.labels
    }
    spec: corev1.#ServiceSpec & {
        type: corev1.#ServiceTypeClusterIP
        selector: {
            "app.kubernetes.io/name":     "mariadb"
            "app.kubernetes.io/instance": "mysql"
            "app.kubernetes.io/component": "primary"
        }
        ports: [
            {
                name:       "mysql"
                port:       3306
                targetPort: 3306
            },
        ]
    }
}
