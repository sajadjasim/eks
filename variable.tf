variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "dns_zone" {
  description = "DNS in route53"
  type        = string
  default     = "sopra-demo-eks.click"
}

variable "ecr_name" {
  type    = string
  default = "demo-eks"
}

variable "organization" {
  type    = string
  default = "sajadjasim"
}

variable "github_repo_gitops" {
  type    = string
  default = "https://github.com/sajadjasim/demo-eks-apps.git"
}

variable "github_repo_gitops_secret" {
  type    = string
  default = "github-repo-apps"
}