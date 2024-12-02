data "aws_secretsmanager_secret" "github" {
  name = var.github_repo_gitops_secret
}

data "aws_secretsmanager_secret_version" "github" {
  secret_id     = data.aws_secretsmanager_secret.github.id
}

resource "argocd_repository" "github" {
  repo            = var.github_repo_gitops
  username        = jsondecode(data.aws_secretsmanager_secret_version.github.secret_string)["user"]
  password        = jsondecode(data.aws_secretsmanager_secret_version.github.secret_string)["password"]
}


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
      repo_url        = var.github_repo_gitops
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
  depends_on = [helm_release.argocd, argocd_repository.github]
}
