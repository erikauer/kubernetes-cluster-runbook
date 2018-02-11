terraform fmt
terraform validate -var-file='./exoscale.tfvars'
terraform plan -var-file='./exoscale.tfvars' -out=next-steps.plan
terraform apply -parallelism=10 next-steps.plan
