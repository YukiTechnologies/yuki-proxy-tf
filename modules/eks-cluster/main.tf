terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.81.0"
    }
  }
}

resource "aws_iam_policy" "autoscaling_policy" {
  name        = "${var.cluster_name}-autoscaler-policy"
  path        = "/"
  description = "IAM policy for EKS Cluster Autoscaler"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:DescribeInstanceTypes"
        ],
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_policy" "secrets_manager_policy" {
  name        = "${var.cluster_name}-AllowSecretsManagerAccess"
  description = "Policy to allow access to AWS Secrets Manager resources"
  policy      = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets"
        ],
        "Resource": "arn:aws:secretsmanager:*:*:secret:*",
        "Condition": {
          "StringEquals": {
            "secretsmanager:ResourceTag/${var.shared_secrets_tag.key}": var.shared_secrets_tag.value,
          }
        }
      },
      {
        "Effect": "Allow",
        "Action": [
          "kms:Decrypt"
        ],
        "Resource": "*",
        "Condition": {
          "StringEquals": {
            "kms:ViaService": "secretsmanager.*.amazonaws.com"
          }
        }
      }
    ]
  })
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.32.0"

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
      AutoScalingDescribePolicy = aws_iam_policy.autoscaling_policy.arn,
      SecretsManagerPolicy = aws_iam_policy.secrets_manager_policy.arn
    }
  }

  eks_managed_node_groups = {
    yuki-proxy = {
      min_size     = var.eks_nodes.min_size
      max_size     = var.eks_nodes.max_size
      desired_size = var.eks_nodes.desired_size
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
      tags = var.tags
    }
  }

  enable_cluster_creator_admin_permissions = true

  tags = var.tags
}
