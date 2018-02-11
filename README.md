# Kubernetes Cluster Installation

Using terraform and ansible this example installs a kubernetes cluster following
this description: https://coreos.com/kubernetes/docs/1.6.1/getting-started.html

## Prerequisites

* Terraform version 10.8+ installed
* configured cloudstack terraform provider

## Run example

     terraform init
     terraform plan -var-file='./exoscale.tfvars' -out=next-steps.plan
     terraform apply -parallelism=10 next-steps.plan

## Cloudstack Provider Configuration

To configure the cloudstack provider just create a file exoscale.tfvars inside the
root directory of this example, which contains information about the API. Eg.

      cloudstack_api_url = "https://api.exoscale.ch/compute"
      cloudstack_api_key = "EXO02a0186f1234ab2a606700a9"
      cloudstack_secret_key = "6uRPl00k9EddcljHJlywFJEFFOUzJnV9GXICXyicgvY"

## Contribute

Before contribution run

      terraform fmt
      terraform validate -var-file='./exoscale.tfvars'

to run

## Clean up

terraform destroy -parallelism=10 -var-file='./exoscale.tfvars'
