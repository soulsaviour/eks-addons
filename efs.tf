# Shared, ReadWriteMany storage for pods: an encrypted EFS file system with a
# mount target in each availability zone the cluster uses.

data "aws_subnet" "efs_candidates" {
  for_each = toset(length(var.efs_subnet_ids) > 0 ? var.efs_subnet_ids : tolist(data.aws_eks_cluster.this.vpc_config[0].subnet_ids))
  id       = each.value
}

locals {
  # EFS allows one mount target per AZ, and cluster subnet lists often have
  # several per AZ, so keep the first subnet in each.
  efs_subnets_by_az = { for s in data.aws_subnet.efs_candidates : s.availability_zone => s.id... }
  efs_mount_subnets = { for az, ids in local.efs_subnets_by_az : az => sort(ids)[0] }
}

resource "aws_efs_file_system" "this" {
  creation_token   = "${var.cluster_name}-efs"
  encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = "elastic"

  # Cold files move to Infrequent Access and come back on first read.
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  tags = {
    Name = "${var.cluster_name}-efs"
  }
}

resource "aws_efs_backup_policy" "this" {
  file_system_id = aws_efs_file_system.this.id

  backup_policy {
    status = "ENABLED"
  }
}

resource "aws_security_group" "efs" {
  name_prefix = "${var.cluster_name}-efs-"
  description = "NFS from the EKS cluster to EFS"
  vpc_id      = local.vpc_id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "efs_nfs" {
  for_each = toset(concat(
    [data.aws_eks_cluster.this.vpc_config[0].cluster_security_group_id],
    var.efs_extra_security_group_ids,
  ))

  security_group_id            = aws_security_group.efs.id
  description                  = "NFS from ${each.value}"
  referenced_security_group_id = each.value
  ip_protocol                  = "tcp"
  from_port                    = 2049
  to_port                      = 2049
}

resource "aws_efs_mount_target" "this" {
  for_each = local.efs_mount_subnets

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs.id]
}
