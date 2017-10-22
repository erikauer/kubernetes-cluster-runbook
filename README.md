# Kubernetes Cluster Installation

Using terraform and ansible this example installs a kubernetes cluster following
this description: https://coreos.com/kubernetes/docs/latest/getting-started.html

## Prerequisites

* Terrafrom version 10.7 installed
* configured cloudstack terrafrom provider

## Run example

     terraform init
     terraform apply

##  Cloudstack Provider Configuration

To configure the cloudstack provider just create a file variables.tf inside the
root directory of this example, which contains information about the API. Eg.


      variable "cloudstack_api_url" {
          type = "string"
          default =  "https://api.exoscale.ch/compute"
      }

      variable "cloudstack_api_key" {
          type = "string"
          default = "EXO02a0186f1234ab2a606700a9"
      }

      variable "cloudstack_secret_key" {
          type = "string"
          default =  "6uRPl00k9EddcljHJlywFJEFFOUzJnV9GXICXyicgvY"
      }
