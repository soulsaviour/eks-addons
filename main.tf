data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_partition" "current" {}

# The cluster's IAM OIDC provider, which IRSA trusts. Created alongside the
# cluster (eksctl, the EKS Terraform module, or the console's "Associate").
data "aws_iam_openid_connect_provider" "this" {
  url = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
}

locals {
  oidc_provider_arn = data.aws_iam_openid_connect_provider.this.arn
  oidc_issuer_host  = replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")
  vpc_id            = data.aws_eks_cluster.this.vpc_config[0].vpc_id

  tags = merge({ ManagedBy = "terraform", Cluster = var.cluster_name }, var.tags)
}
