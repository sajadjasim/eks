resource "argocd_application" "nginx" {
  metadata {
    name      = "nginx"
    namespace = "argocd"
  }

  spec {
    project = "default"

    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "demo"
    }

    source {
      repo_url        = "https://github.com/sajadjasim/demo-eks-apps.git"
      path            = "nginx"
      target_revision = "main"
    }

    sync_policy {
      automated {
        prune       = true
        self_heal   = true
        allow_empty = true
      }
    }
  }
}
