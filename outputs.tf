output "lb_controller_role_arn" {
  description = "IAM role used by the AWS Load Balancer Controller."
  value       = module.lb_controller_role.arn
}

output "efs_file_system_id" {
  description = "EFS file system behind the efs-sc StorageClass."
  value       = aws_efs_file_system.this.id
}

output "efs_csi_role_arn" {
  description = "IAM role used by the EFS CSI driver."
  value       = module.efs_csi_role.arn
}

output "storage_class" {
  description = "StorageClass for ReadWriteMany volumes on EFS."
  value       = kubernetes_storage_class_v1.efs.metadata[0].name
}
