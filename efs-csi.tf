# EFS CSI driver as an EKS managed add-on, plus a StorageClass that gives
# each PersistentVolumeClaim its own access point (and directory) on the
# shared file system.

module "efs_csi_role" {
  source = "./modules/irsa-role"

  name              = "${var.cluster_name}-efs-csi-driver"
  oidc_provider_arn = local.oidc_provider_arn
  oidc_issuer_host  = local.oidc_issuer_host
  # Controller and node service accounts.
  service_accounts = ["kube-system:efs-csi-*"]
  policy_arns      = ["arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"]
}

data "aws_eks_addon_version" "efs_csi" {
  addon_name         = "aws-efs-csi-driver"
  kubernetes_version = data.aws_eks_cluster.this.version
  most_recent        = true
}

resource "aws_eks_addon" "efs_csi" {
  cluster_name             = var.cluster_name
  addon_name               = "aws-efs-csi-driver"
  addon_version            = data.aws_eks_addon_version.efs_csi.version
  service_account_role_arn = module.efs_csi_role.arn

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"
}

resource "kubernetes_storage_class_v1" "efs" {
  metadata {
    name = "efs-sc"
  }

  storage_provisioner = "efs.csi.aws.com"
  # Deleting a claim keeps its data; clean up access points deliberately.
  reclaim_policy      = "Retain"
  volume_binding_mode = "Immediate"

  parameters = {
    provisioningMode = "efs-ap"
    fileSystemId     = aws_efs_file_system.this.id
    directoryPerms   = "700"
    basePath         = "/dynamic"
  }

  depends_on = [aws_eks_addon.efs_csi, aws_efs_mount_target.this]
}
