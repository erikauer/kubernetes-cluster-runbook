# Entry Point
# https://www.terraform.io/docs/modules/create.html

module "kubernetes_cluster_infrastructure" {
  source = "./modules/kubernetes_cluster_infrastructure"
}
