# eks-addons

Terraform that adds two things most EKS clusters need on day one:

- **AWS Load Balancer Controller**, so Ingresses get ALBs and LoadBalancer
  Services get NLBs.
- **EFS with the EFS CSI driver**, so pods can share ReadWriteMany volumes
  across nodes and availability zones.

Both use IRSA: each controller's service account assumes its own IAM role
through the cluster's OIDC provider, with no node-wide permissions and no
access keys.

## Layout

```
providers.tf          AWS, plus Kubernetes and Helm authenticated with aws eks get-token
main.tf               existing cluster, its OIDC provider, VPC
modules/irsa-role/    IAM role scoped to specific service accounts
lb-controller.tf      controller IAM policy (pinned), IRSA role, Helm release
efs.tf                encrypted file system, mount targets, security group, backups
efs-csi.tf            EFS CSI managed add-on, IRSA role, efs-sc StorageClass
examples/             ALB Ingress, shared EFS volume
```

## Usage

The cluster and its IAM OIDC provider must already exist.

```bash
cp terraform.tfvars.example terraform.tfvars   # region and cluster name
terraform init
terraform apply
kubectl apply -f examples/alb-ingress.yaml
kubectl apply -f examples/efs-shared-volume.yaml
```

| Variable | Default | |
|----------|---------|-|
| `cluster_name` | (required) | Existing EKS cluster |
| `region` | `ap-south-1` | |
| `lb_controller_version` | `3.6.2` | Chart and IAM policy version, kept in step |
| `efs_subnet_ids` | cluster subnets | Where EFS mount targets go |
| `efs_extra_security_group_ids` | `[]` | Node security groups besides the cluster's |

## Details worth knowing

- The controller's IAM policy is downloaded from the controller's own repo at
  the same version as the chart, so upgrading `lb_controller_version` moves
  both together. A changed policy shows up in `terraform plan`.
- EFS allows one mount target per availability zone, and cluster subnet
  lists usually hold several per zone, so the config picks one subnet per
  zone.
- `efs-sc` gives every claim its own EFS access point and directory, with
  `Retain` so deleting a claim doesn't delete data.
- The file system is encrypted, has AWS Backup enabled, and moves files to
  Infrequent Access after 30 days without reads.
- NFS is only open from the cluster security group (and any you add).

## Checks

CI runs `terraform fmt`, `terraform validate`, and validates the example
manifests with kubeconform. Applying it needs a real cluster.
