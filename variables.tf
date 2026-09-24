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
