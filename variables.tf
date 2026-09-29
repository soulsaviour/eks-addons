variable "region" {
  description = "AWS region of the cluster."
  type        = string
  default     = "ap-south-1"
}

variable "cluster_name" {
  description = "Name of the existing EKS cluster."
  type        = string
}

variable "tags" {
  description = "Extra tags for the AWS resources created here."
  type        = map(string)
  default     = {}
}

variable "lb_controller_version" {
  description = "AWS Load Balancer Controller version; selects both the chart and its IAM policy."
  type        = string
  default     = "3.6.2"
}

variable "efs_subnet_ids" {
  description = "Subnets for EFS mount targets. Defaults to the cluster's subnets; one is used per availability zone."
  type        = list(string)
  default     = []
}

variable "efs_extra_security_group_ids" {
  description = "Security groups besides the cluster security group that may mount EFS (e.g. custom node groups)."
  type        = list(string)
  default     = []
}
