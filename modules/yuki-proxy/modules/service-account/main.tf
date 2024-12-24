module "service_account_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                              = var.role_name
  attach_external_dns_policy = true

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["${var.namespace}:${var.service_account_name}"]
    }
  }
}

resource "kubernetes_service_account" "route53" {
  metadata {
    name      = var.service_account_name
    namespace = var.namespace 
    annotations = {
      "eks.amazonaws.com/role-arn" = module.service_account_role.iam_role_arn
    }
  }
}