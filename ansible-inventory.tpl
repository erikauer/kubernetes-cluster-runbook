[default]

[etcd_nodes]
${etcd_node01_ip}

[kubernetes_master]
${kubernetes_master_node01_ip}

[kubernetes_nodes]
${kubernetes_worker_node01_ip}
${kubernetes_worker_node02_ip}
${kubernetes_worker_node03_ip}

[etcd_nodes:vars]
ansible_user=core
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_python_interpreter=/opt/bin/python

[kubernetes_master:vars]
ansible_user=core
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_python_interpreter=/opt/bin/python

[kubernetes_nodes:vars]
ansible_user=core
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_python_interpreter=/opt/bin/python
