module "cert_manager_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.48.0"

  role_name                     = "cert-manager"
  attach_cert_manager_policy    = true
  cert_manager_hosted_zone_arns = [data.aws_route53_zone.demo_eks.arn]


  oidc_providers = {
    eks = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["cert-manager:cert-manager"]
    }
  }
}

resource "kubernetes_namespace" "cert-manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "argocd_application" "cert-manager" {
  metadata {
    name      = "cert-manager"
    namespace = "argocd"
  }

  spec {
    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "cert-manager"
    }
    sync_policy {
      automated {
        prune       = true
        self_heal   = true
        allow_empty = true
      }
    }
    source {
      repo_url        = "https://charts.jetstack.io"
      chart           = "cert-manager"
      target_revision = "v1.16.2"
      helm {
        release_name = "cert-manager"
        parameter {
          name  = "crds.enabled"
          value = "true"
        }
        parameter {
          name  = "serviceAccount.annotations.eks\\.amazonaws\\.com\\/role-arn"
          value = module.cert_manager_irsa_role.iam_role_arn
        }
      }
    }
  }
  depends_on = [
    helm_release.argocd,
    module.cert_manager_irsa_role,
    kubernetes_namespace.cert-manager
  ]
}

resource "kubernetes_manifest" "issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-production"
    }
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = "sajad.jasim@soprasteria.com"
        privateKeySecretRef = {
          name = "letsencrypt-production"
        }
        solvers = [{
          dns01 = {
            route53 = {
              region = var.region
              role   = module.cert_manager_irsa_role.iam_role_arn
              auth = {
                kubernetes = {
                  serviceAccountRef = {
                    name = "cert-manager"
                  }
                }
              }
            }
          }
          }
        ]
      }
    }
  }
  depends_on = [
    argocd_application.cert-manager
  ]
}


