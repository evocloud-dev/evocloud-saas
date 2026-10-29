# Seafile Pro Cluster Timoni Module

This directory contains the Timoni module for deploying a high-availability, production-grade **Seafile Pro** cluster on Kubernetes.

---

## 1. Prerequisites & External Dependencies

Before applying this Timoni module, the following backing services must be running in your Kubernetes namespace (e.g., `seafile-cluster`):

### A. MariaDB / MySQL
* **Service Endpoint**: `mariadb:3306`

### B. Redis (Master/Replica)
* **Service Endpoint**: `redis-master:6379`

### C. Memcached
* **Service Endpoint**: `memcached:11211`

### D. Elasticsearch (v7.x)
* **Service Endpoint**: `elasticsearch-master:9200`
* **Important**: Must be configured with `clusterHealthCheckParams="wait_for_status=yellow&timeout=1s"` if deployed on a single-node local cluster.

---

## 2. Dependency Setup Commands (Helm)

To deploy the backing dependencies using Helm:

```bash
# 1. Add repositories
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add elastic https://helm.elastic.co
helm repo update

# 2. Deploy MariaDB
helm upgrade --install mariadb bitnami/mariadb -n seafile-cluster \
  --set auth.rootPassword=changeit \
  --set auth.database=ccnet_db \
  --set auth.username=seafile \
  --set auth.password=mysql_password \
  --wait --timeout 3m

# 3. Deploy Redis
helm install redis bitnami/redis -n seafile-cluster \
  --set auth.enabled=false

# 4. Deploy Memcached
helm install memcached bitnami/memcached -n seafile-cluster

# 5. Deploy Elasticsearch (v7.17.3)
helm install elasticsearch elastic/elasticsearch \
  --version 7.17.3 \
  --set replicas=1 \
  --set minimumMasterNodes=1 \
  --set clusterHealthCheckParams="wait_for_status=yellow&timeout=1s" \
  --set esJavaOpts="-Xmx256m -Xms256m" \
  --set resources.requests.cpu=100m \
  --set resources.requests.memory=512Mi \
  --set resources.limits.cpu=1000m \
  --set resources.limits.memory=1Gi \
  -n seafile-cluster
```

---

## 3. Configuration & Deployment

1. **Review and Update Credentials**: Open `values.cue` and customize your admin secrets:
   ```cue
   secretsMap: {
       JWT_PRIVATE_KEY:                  "your-random-jwt-key"
       SEAFILE_MYSQL_DB_PASSWORD:        "database-password"
       INIT_SEAFILE_ADMIN_PASSWORD:      "admin-login-password"
       INIT_SEAFILE_MYSQL_ROOT_PASSWORD: "root-database-password"
   }
   ```
2. **Deploy the Module**: Run `timoni` to build and apply the Seafile frontend and backend workloads:
   ```bash
   timoni apply -n seafile-cluster seafile .
   ```

