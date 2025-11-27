CODEBASE Full Report — Continued

This file continues the per-file summaries and focuses on infrastructure manifests discovered under `kubernetes/`.

## Kubernetes manifests

All Kubernetes manifests live under `kubernetes/`. They set up namespace, MongoDB PV/PVC/statefulset, ConfigMap & Secrets, the EasyShop deployment and service, Ingress with TLS via cert-manager, an HPA, and a migration job.

### `kubernetes/00-cluster-issuer.yml`
- Purpose: `cert-manager` ClusterIssuer configured for Let's Encrypt production ACME server.
- Key points: Uses HTTP01 solver with nginx ingress class and email `trainwithshubham@gmail.com`.
- Observations: Ready for production TLS via cert-manager; ensure `cert-manager` is installed in the cluster.

### `kubernetes/01-namespace.yaml`
- Purpose: Creates `easyshop` namespace and labels it for environment `production`.

### `kubernetes/02-mongodb-pv.yaml` and `kubernetes/03-mongodb-pvc.yaml`
- Purpose: PersistentVolume and PersistentVolumeClaim for MongoDB storage.
- Key points: `hostPath` PV pointing to `/data/mongodb` with `5Gi` size, `ReadWriteOnce` access, PVC requests the same size.
- Observations: `hostPath` is suitable for single-node or dev clusters; for multi-node/production prefer provisioner-backed PVs (e.g., EBS/GCE PD/CSI driver).

### `kubernetes/04-configmap.yaml` and `kubernetes/05-secrets.yaml`
- Purpose: `ConfigMap` holds non-sensitive config values and `Secret` holds sensitive entries. Both are mounted/used by the `easyshop` deployment.
- Key points: `ConfigMap` includes `MONGODB_URI`, `NODE_ENV`, `NEXT_PUBLIC_API_URL`, `NEXTAUTH_URL`, `NEXTAUTH_SECRET`, `JWT_SECRET` (note: there's a secret-like value in the configmap — secret values should live only in `Secret`).
- Observations: `kubernetes/05-secrets.yaml` has `JWT_SECRET` and `NEXTAUTH_SECRET` with placeholder values; ensure to replace `change-this-in-production` with high-entropy secrets before deploying.

### `kubernetes/06-mongodb-service.yaml` and `kubernetes/07-mongodb-statefulset.yaml`
- Purpose: Expose MongoDB internally and run a single-replica StatefulSet for persistence.
- Key points: Uses `mongo:latest` image. Volume is mounted from the PVC. Resource requests/limits are modest.
- Observations: Consider pinning a specific Mongo image tag (e.g., `mongo:6.0`) for reproducible deployments.

### `kubernetes/08-easyshop-deployment.yaml` and `kubernetes/09-easyshop-service.yaml`
- Purpose: Deploy the Next.js app as a Deployment with 2 replicas, configure env from configmap/secret, expose via `easyshop-service` NodePort on `30000`.
- Key points: `image: trainwithshubham/easyshop-app:1` (image tag 1). Readiness/liveness/startup probes check `/` on port 3000. Uses `http` env values from ConfigMap/Secret.
- Observations: NodePort is used, combined with an Ingress resource; depending on cluster setup, a ClusterIP service is more common with Ingress. Also, ensure the container serves on `/` and port `3000` successfully for probes to pass.

### `kubernetes/10-ingress.yaml`
- Purpose: Ingress resource with TLS configured for `easyshop.letsdeployit.com`.
- Key points: Annotations for nginx and body size increase. Cert-Manager will create/manage `easyshop-tls-secret` via the ClusterIssuer.
- Observations: Make sure DNS for `easyshop.letsdeployit.com` points to your ingress controller.

### `kubernetes/11-hpa.yaml`
- Purpose: Horizontal Pod Autoscaler for the `easyshop` deployment.
- Key points: minReplicas 2, maxReplicas 5, scales on CPU utilization target 70%.

### `kubernetes/12-migration-job.yaml`
- Purpose: Job to run database migrations using a migration image `trainwithshubham/easyshop-migration:1`.
- Key points: Sets `MONGODB_URI` to the cluster-internal MongoDB service.
- Observations: Good pattern for running one-off migrations; ensure the migration image contains the migration script and is idempotent.


---

Progress update: Kubernetes manifests read and summarized into `CODEBASE_FULL_REPORT_CONTINUED.md`.

Next I'll read `terraform/`, `scripts/`, and top-level Dockerfiles and summarize them. If you prefer a different order (e.g., `public/` assets first), tell me now.
