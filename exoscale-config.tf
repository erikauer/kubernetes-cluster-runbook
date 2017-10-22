# Configure the CloudStack Provider
provider "cloudstack" {
  api_url               = "${var.cloudstack_api_url}"
  api_key               = "${var.cloudstack_api_key}"
  secret_key            = "${var.cloudstack_secret_key}"
}

resource "cloudstack_ssh_keypair" "kubernetes-cluster-ssh-key" {
  name       = "kubernetes-cluster-ssh-key"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

# Create a security group
resource "cloudstack_security_group" "kubernetes-cluster-security-group" {
  name                 = "kubernetes-cluster-security-group"
  description          = "Allow access to kubernetes cluster"
}

resource "cloudstack_security_group_rule" "kubernetes-cluster-security-group-rules" {
  security_group_id     = "${cloudstack_security_group.kubernetes-cluster-security-group.id}"
  rule {
    cidr_list           = ["0.0.0.0/0"]
    protocol            = "tcp"
    ports               = ["80", "443"]
  }
  rule {
    cidr_list           = ["0.0.0.0/0"]
    protocol            = "tcp"
    ports               = ["22"]
  }
}

# Create ETCD Single Node (for production you should consider a Multi-Node installation)
resource "cloudstack_instance" "kubernetes-etcd-node01" {
  name                  = "kubernetes-etcd-node01"
  template              = "cc2b7707-3e72-47a6-b881-914eac9f8caf"
  service_offering      = "Micro"
  zone                  = "ch-gva-2"
  security_group_ids    = ["${cloudstack_security_group.kubernetes-cluster-security-group.id}"]
  keypair               = "${cloudstack_ssh_keypair.kubernetes-cluster-ssh-key.id}"
#  user_data             = ${file("etcd-config.yaml")}
}
