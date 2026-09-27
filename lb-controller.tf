# AWS Load Balancer Controller: provisions ALBs for Ingresses and NLBs for
# LoadBalancer Services.

# The IAM policy published with the controller release, pinned to the same
# version as the chart so permissions and code always match.
data "http" "lb_controller_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v${var.lb_controller_version}/docs/install/iam_policy.json"

  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "Could not download the Load Balancer Controller IAM policy."
    }
  }
}

module "lb_controller_role" {
  source = "./modules/irsa-role"

  name              = "${var.cluster_name}-aws-load-balancer-controller"
  oidc_provider_arn = local.oidc_provider_arn
  oidc_issuer_host  = local.oidc_issuer_host
  service_accounts  = ["kube-system:aws-load-balancer-controller"]
  policy_json       = data.http.lb_controller_policy.response_body
}

resource "helm_release" "lb_controller" {
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.lb_controller_version

  values = [yamlencode({
    clusterName  = var.cluster_name
    region       = var.region
    vpcId        = local.vpc_id
    replicaCount = 2
    serviceAccount = {
      name = "aws-load-balancer-controller"
      annotations = {
        "eks.amazonaws.com/role-arn" = module.lb_controller_role.arn
      }
    }
  })]

  wait    = true
  timeout = 600
}
