# eks

## S3 terraform bucket
Create S3 bucket 
name: terraform-s3-state-****
Set same name in provider configuration. 
```
aws s3api create-bucket --bucket terraform-s3-state-**** --region <REGION>
```

## Run Terraform
```
terraform apply -target module.eks
terraform apply -target helm_release.argocd
terraform apply -target argocd_application.cert-manager
terraform apply
```

