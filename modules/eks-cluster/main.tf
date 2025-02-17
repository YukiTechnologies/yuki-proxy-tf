terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

resource "aws_iam_policy" "autoscaling_policy" {
  name        = "AllowAutoScalingDescribeAutoScalingGroups"
  description = "Policy to allow autoscaling:DescribeAutoScalingGroups action"
  policy      = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "autoscaling:DescribeAutoScalingGroups",
          "ec2:DescribeLaunchTemplateVersions"
        ]
        "Resource": "*"
      }
    ]
  })
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.31.4"

  cluster_name = var.cluster_name
  cluster_version = "1.31"
  
  cluster_endpoint_public_access = true

  create_kms_key              = false
  create_cloudwatch_log_group = false
  cluster_encryption_config   = {}

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  vpc_id                   = var.vpc_id
  subnet_ids               = var.private_subnets
  control_plane_subnet_ids = var.private_subnets
  create_node_security_group = false

  eks_managed_node_group_defaults = {
    ami_type = "AL2_ARM_64"
    instance_types = ["c7g.2xlarge"]
    iam_role_additional_policies = {
      AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy",
      AutoScalingDescribePolicy = aws_iam_policy.autoscaling_policy.arn
    }
  }

  eks_managed_node_groups = {
    yuki-proxy = {
      min_size     = 1
      max_size     = 4
      desired_size = 2
      ebs_optimized = true
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 20
            volume_type           = "gp3"
            encrypted             = true
          }
        }
      }
      tags = {
        Env       = "prd"
        Terraform = "true"
        OwnedBy   = "yuki-proxy"
      }
    }
  }

  enable_cluster_creator_admin_permissions = true

  tags = {
    Env       = "prd"
    Terraform = "true"
    OwnedBy = "yuki-proxy"
  }
}

