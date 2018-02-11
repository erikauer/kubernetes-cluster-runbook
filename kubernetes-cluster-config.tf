# Configure the CloudStack Provider
provider "cloudstack" {
  api_url    = "${var.cloudstack_api_url}"
  api_key    = "${var.cloudstack_api_key}"
  secret_key = "${var.cloudstack_secret_key}"
}

resource "cloudstack_ssh_keypair" "kubernetes-cluster-ssh-key" {
  name       = "kubernetes-cluster-ssh-key"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

# Create a security group
resource "cloudstack_security_group" "kubernetes-cluster-security-group" {
  name        = "kubernetes-cluster-security-group"
  description = "Allow access to kubernetes cluster"
}

# Create a security group
resource "cloudstack_security_group" "etcd-security-group" {
  name        = "etcd-security-group"
  description = "Allow access to etcd machines"
}

resource "cloudstack_security_group_rule" "kubernetes-cluster-security-group-rules" {
  security_group_id = "${cloudstack_security_group.kubernetes-cluster-security-group.id}"

  rule {
    cidr_list = ["0.0.0.0/0"]
    protocol  = "tcp"
    ports     = ["80", "443"]
  }

  rule {
    cidr_list = ["0.0.0.0/0"]
    protocol  = "tcp"
    ports     = ["22"]
  }
}

resource "cloudstack_security_group_rule" "etcd-security-group-rules" {
  security_group_id = "${cloudstack_security_group.etcd-security-group.id}"

  rule {
    cidr_list = ["0.0.0.0/0"]
    protocol  = "tcp"
    ports     = ["2379"]
  }
}

# Create ETCD Single Node (for production you should consider a Multi-Node installation)
resource "cloudstack_instance" "kubernetes-etcd-node01" {
  name               = "kubernetes-etcd-node01"
  template           = "cc2b7707-3e72-47a6-b881-914eac9f8caf"
  service_offering   = "Small"
  root_disk_size     = 50
  zone               = "ch-gva-2"
  security_group_ids = ["${cloudstack_security_group.kubernetes-cluster-security-group.id}", "${cloudstack_security_group.etcd-security-group.id}"]
  keypair            = "${cloudstack_ssh_keypair.kubernetes-cluster-ssh-key.id}"
}

# Create Kubernetes-master
resource "cloudstack_instance" "kubernetes-master-node01" {
  name               = "kubernetes-master-node01"
  template           = "cc2b7707-3e72-47a6-b881-914eac9f8caf"
  service_offering   = "Extra-large"
  root_disk_size     = 50
  zone               = "ch-gva-2"
  security_group_ids = ["${cloudstack_security_group.kubernetes-cluster-security-group.id}"]
  keypair            = "${cloudstack_ssh_keypair.kubernetes-cluster-ssh-key.id}"
}

# Create Kubernetes-worker nodes
resource "cloudstack_instance" "kubernetes-worker-node01" {
  name               = "kubernetes-worker-node01"
  template           = "cc2b7707-3e72-47a6-b881-914eac9f8caf"
  service_offering   = "Large"
  root_disk_size     = 50
  zone               = "ch-gva-2"
  security_group_ids = ["${cloudstack_security_group.kubernetes-cluster-security-group.id}"]
  keypair            = "${cloudstack_ssh_keypair.kubernetes-cluster-ssh-key.id}"
}

resource "cloudstack_instance" "kubernetes-worker-node02" {
  name               = "kubernetes-worker-node02"
  template           = "cc2b7707-3e72-47a6-b881-914eac9f8caf"
  service_offering   = "Large"
  root_disk_size     = 50
  zone               = "ch-gva-2"
  security_group_ids = ["${cloudstack_security_group.kubernetes-cluster-security-group.id}"]
  keypair            = "${cloudstack_ssh_keypair.kubernetes-cluster-ssh-key.id}"
}

resource "cloudstack_instance" "kubernetes-worker-node03" {
  name               = "kubernetes-worker-node03"
  template           = "cc2b7707-3e72-47a6-b881-914eac9f8caf"
  service_offering   = "Large"
  root_disk_size     = 50
  zone               = "ch-gva-2"
  security_group_ids = ["${cloudstack_security_group.kubernetes-cluster-security-group.id}"]
  keypair            = "${cloudstack_ssh_keypair.kubernetes-cluster-ssh-key.id}"
}

# Template for ansible inventory
data "template_file" "ansible-inventory" {
  template = "${file("ansible-inventory.tpl")}"

  vars {
    etcd_node01_ip              = "${cloudstack_instance.kubernetes-etcd-node01.ip_address}"
    kubernetes_master_node01_ip = "${cloudstack_instance.kubernetes-master-node01.ip_address}"
    kubernetes_worker_node01_ip = "${cloudstack_instance.kubernetes-worker-node01.ip_address}"
    kubernetes_worker_node02_ip = "${cloudstack_instance.kubernetes-worker-node02.ip_address}"
    kubernetes_worker_node03_ip = "${cloudstack_instance.kubernetes-worker-node03.ip_address}"
  }
}

# Create inventory file
resource "null_resource" "create-ansible-inventory" {
  # Changes to any instance of the cluster requires re-provisioning
  triggers {
    template = "${data.template_file.ansible-inventory.rendered}"
  }

  provisioner "local-exec" {
    command = "echo \"${data.template_file.ansible-inventory.rendered}\" > inventory"
  }
}

# Template for openssl.cnf file
data "template_file" "openssl-cnf" {
  template = "${file("openssl-cnf.tpl")}"

  vars {
    kubernetes_master_node01_ip = "${cloudstack_instance.kubernetes-master-node01.ip_address}"
  }
}

# Create openssl.cnf and gernerate certs files
resource "null_resource" "create-openssl-cnf" {
  # Changes of the openssl template requires re-provisioning
  triggers {
    template = "${data.template_file.openssl-cnf.rendered}"
  }

  provisioner "local-exec" {
    command = "mkdir -p certs && echo \"${data.template_file.openssl-cnf.rendered}\" > ./certs/openssl.cnf && cd certs && openssl genrsa -out ca-key.pem 2048 && openssl req -x509 -new -nodes -key ca-key.pem -days 10000 -out ca.pem -subj \"/CN=kube-ca\" && openssl genrsa -out apiserver-key.pem 2048 && openssl req -new -key apiserver-key.pem -out apiserver.csr -subj \"/CN=kube-apiserver\" -config openssl.cnf && openssl x509 -req -in apiserver.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out apiserver.pem -days 365 -extensions v3_req -extfile openssl.cnf && openssl genrsa -out worker-key.pem 2048 && openssl req -new -key worker-key.pem -out worker.csr -subj \"/CN=kube-worker\" && openssl x509 -req -in worker.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out worker.pem -days 365 && openssl genrsa -out admin-key.pem 2048 && openssl req -new -key admin-key.pem -out admin.csr -subj \"/CN=kube-admin\" && openssl x509 -req -in admin.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out admin.pem -days 365"
  }
}
