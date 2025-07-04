# 🚀 Elasticache Data Migration with Terraform & Redis-Shake

This project helps you migrate from a standalone Redis setup to a **cluster-enabled Valkey** deployment on AWS using `redis-shake` and Terraform

---

## 1️⃣ Deploy Valkey Cluster (Terraform)
- Run the new terraform plan

---

## 2️⃣ Run migration using EC2 (Terraform)
- Get source and destination cluster ids:
```bash
  aws elasticache describe-replication-groups \
  --query "ReplicationGroups[].ReplicationGroupId" \
  --output table
```
- Run the terraform module:
```bash
cd migration/
terraform init
terraform apply -var-file=vars.tfvars
```
- Monitor EC2 logs with:

```bash
aws ec2 get-console-output \
--instance-id <instance_id> \
--output text \
--latest
```

---

``## 4️⃣ Update proxy to point to new cluster
- Update `REDIS_HOST` env var with the new endpoint
- Rollout the deployment
- Profit 💰

``---

## 5️⃣ Cleanup
- once verified the new cluster works:
```bash
terraform destroy -var-file=vars.tfvars
```