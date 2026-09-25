# An IAM role that Kubernetes service accounts can assume through the
# cluster's OIDC provider (IAM Roles for Service Accounts).

variable "name" {
  description = "Role name."
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the cluster's IAM OIDC provider."
  type        = string
}

variable "oidc_issuer_host" {
  description = "OIDC issuer URL without https://."
  type        = string
}

variable "service_accounts" {
  description = "namespace:name pairs allowed to assume the role. Wildcards are allowed in the name."
  type        = list(string)
}

variable "policy_arns" {
  description = "Managed policies to attach."
  type        = list(string)
  default     = []
}

variable "policy_json" {
  description = "Optional inline policy document."
  type        = string
  default     = null
}

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_issuer_host}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "${var.oidc_issuer_host}:sub"
      values   = [for sa in var.service_accounts : "system:serviceaccount:${sa}"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = var.name
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = toset(var.policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "inline" {
  count = var.policy_json == null ? 0 : 1

  name   = "${var.name}-inline"
  role   = aws_iam_role.this.id
  policy = var.policy_json
}

output "arn" {
  value = aws_iam_role.this.arn
}
