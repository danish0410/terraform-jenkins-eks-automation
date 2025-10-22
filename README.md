aws s3api create-bucket \
  --bucket tfstatebackup-16102025-south \
  --region ap-south-1 \
  --create-bucket-configuration LocationConstraint=ap-south-1

aws dynamodb create-table \
  --table-name terraformsouth-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region ap-south-1
***before delete all the keys in AWS console***
chmod +x scripts/generate_ed25519_key.sh
./scripts/generate_ed25519_key.sh dev-classic-ap-south-1 ap-south-1

nano update-bastion-ip.sh
Press Ctrl + O → hit Enter to save
Press Ctrl + X to exit
chmod +x update-bastion-ip.sh
./update-bastion-ip.sh

mv backend-ap-southeast-1.hcl backend-ap-southeast-1.hcl.disabled
mv backend-ap-south-1.hcl.disabled backend-ap-south-1.hcl
terraform init -reconfigure -backend-config="backend-ap-south-1.hcl"
terraform fmt -recursive
terraform validate
terraform plan -var-file="terraform-ap-south-1.tfvars"
terraform apply -var-file="terraform-ap-south-1.tfvars"
scp -i /home/thani/.ssh/dev-classic-ap-south-1.pem ~/.ssh/dev-classic-ap-south-1.pem ~/.ssh/dev-classic-ap-south-1 ~/.ssh/dev-classic-ap-south-1.pub ubuntu@13.235.50.20:/home/ubuntu/.ssh
terraform destroy -var-file="terraform-ap-south-1.tfvars"
###rm -rf .terraform/ terraform.tfstate terraform.tfstate.backup

aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=dev_classic-instance-*" \
  --query 'Reservations[].Instances[].[InstanceId,PublicIpAddress,State.Name,Placement.AvailabilityZone]' \
  --output table \
  --region ap-south-1

ssh -i ./dev_classic-ap-south-1.pem ubuntu@<PUBLIC_IP>
terraform destroy -var-file="terraform-ap-south-1.tfvars"
****************************************************************************************************************
****************************************************************************************************************

aws s3api create-bucket \
  --bucket tfstatebackup-16102025-southeast \
  --region ap-southeast-1 \
  --create-bucket-configuration LocationConstraint=ap-southeast-1

aws dynamodb create-table \
  --table-name terraformsoutheast-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region ap-southeast-1
***before delete all the keys in AWS console***
chmod +x scripts/generate_ed25519_key.sh
./scripts/generate_ed25519_key.sh dev-classic-ap-southeast-1 ap-southeast-1

mv backend-ap-south-1.hcl backend-ap-south-1.hcl.disabled
mv backend-ap-southeast-1.hcl.disabled backend-ap-southeast-1.hcl
terraform init -reconfigure -backend-config="backend-ap-southeast-1.hcl"
terraform fmt -recursive
terraform validate
terraform plan -var-file="terraform-ap-southeast-1.tfvars"
terraform apply -var-file="terraform-ap-southeast-1.tfvars"
cp dev-classic-ap-south-1.pem ~/.ssh/
terraform destroy -var-file="terraform-ap-southeast-1.tfvars"

aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=dev_classic-instance-*" \
  --query 'Reservations[].Instances[].[InstanceId,PublicIpAddress,State.Name,Placement.AvailabilityZone]' \
  --output table \
  --region ap-southeast-1

ssh -i ./dev_classic-ap-southeast-1.pem ubuntu@<PUBLIC_IP>
terraform destroy -var-file="terraform-ap-southeast-1.tfvars"

permanently delete

/home/thani/github_new/terraform-jenkins-eks-automation/infra/dev-classic-ap-south-1.pub
scp -i /home/thani/.ssh/ap-south-1-dev-classic.pem ~/.ssh/ap-south-1-dev-classic.pem ~/.ssh/dev-classic-ap-south-1.pem ~/.ssh/dev-classic-ap-south-1 ~/.ssh/dev-classic-ap-south-1.pub ubuntu@13.233.238.247:/home/ubuntu/.ssh

hosts.ini
[myservers]
newvm ansible_host=<new-server-public-ip> ansible_user=ubuntu ansible_port=22 ansible_ssh_private_key_file=~/.ssh/my-key.pem

##########################################create-user.yml playbook##########################################################
---
- name: Create linux user with SSH access
  hosts: myservers
  become: true
  vars:
    user_name: thanigai
    user_shell: /bin/bash
    user_groups: sudo               # use "wheel" on RHEL/CentOS
    user_ssh_pubkey: "{{ lookup('file', '~/.ssh/id_rsa.pub') }}"
    allow_passwordless_sudo: true

  tasks:
    - name: Ensure groups exist
      ansible.builtin.group:
        name: "{{ item }}"
        state: present
      loop: "{{ user_groups.split(',') if user_groups is string else [user_groups] }}"

    - name: Create user "{{ user_name }}"
      ansible.builtin.user:
        name: "{{ user_name }}"
        shell: "{{ user_shell }}"
        groups: "{{ user_groups }}"
        append: yes
        home: "/home/{{ user_name }}"
        create_home: yes
        state: present

    - name: Create .ssh directory
      ansible.builtin.file:
        path: "/home/{{ user_name }}/.ssh"
        owner: "{{ user_name }}"
        group: "{{ user_name }}"
        mode: "0700"
        state: directory

    - name: Add authorized_keys
      ansible.builtin.copy:
        dest: "/home/{{ user_name }}/.ssh/authorized_keys"
        content: "{{ user_ssh_pubkey }}\n"
        owner: "{{ user_name }}"
        group: "{{ user_name }}"
        mode: "0600"

    - name: Ensure passwordless sudo
      ansible.builtin.copy:
        dest: "/etc/sudoers.d/{{ user_name }}"
        content: "{{ user_name }} ALL=(ALL) NOPASSWD:ALL\n"
        owner: root
        group: root
        mode: "0440"
      when: allow_passwordless_sudo


*********password 
python3 - <<'PY'
import crypt
pw = "YourStrongPasswordHere"
print(crypt.crypt(pw, crypt.mksalt(crypt.METHOD_SHA512)))
PY

sudo apt update
sudo apt install -y awscli
aws --version
aws configure
aws ec2 authorize-security-group-ingress \
    --group-id sg-06dacc171d6e96938 \
    --protocol tcp \
    --port 22 \
    --cidr 49.204.128.24/32
ssh -i /home/ubuntu/.ssh/dev-classic-ap-south-1.pem ubuntu@3.109.49.71
ansible-playbook -i hosts.ini create-user.yml

##########################################nginx playbook##########################################################
setup.yml
---
- name: Setup Web Server
  hosts: webservers
  become: true

  tasks:
    - name: Update apt cache
      apt:
        update_cache: yes

    - name: Install Nginx
      apt:
        name: nginx
        state: present

    - name: Ensure Nginx is running
      service:
        name: nginx
        state: started
        enabled: yes

ansible-playbook -i hosts.ini setup.yml
********************************************

03-09-25 
10:00am - 12:00pm identified the problem why github is not push the code, then only created github_new folder and clone the repo 
12:00pm - 14:00pm updated the code with ebs_csi_driver, cert_manager, cluster_autoscaler etc - run the terraform init, terraform validate, terraform plan and terraform apply the got the error cluster name is not matched so updated the correct cluster name and re-run the terraform apply couple to times
14:00pm - 16:00pm eks was created but dono how to view the addons in eks, so destroy the eks because manually updated the providers - today evening will view the related videos and do the same process and finally view the addons
below are the codes updated in the repo

resource "helm_release" "ebs_csi_driver"
Uses - CSI = Container Storage Interface
It’s an add-on for Kubernetes/EKS that allows pods to dynamically provision and use Amazon EBS volumes as persistent storage.
Without it, your workloads in EKS cannot request EBS volumes via
Code
resource "helm_release" "ebs_csi_driver" {
  name       = "aws-ebs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  chart      = "aws-ebs-csi-driver"
  # version    = var.ebs_csi_version
  namespace  = "kube-system"

  depends_on = [aws_eks_node_group.private_nodes]
}

resource "helm_release" "cert_manager" {
uses
An open-source Kubernetes add-on for automating the management and issuance of TLS certificates.
Commonly used with Let’s Encrypt or private CAs.
It handles certificate requests, renewals, and injection into Kubernetes Secrets
code
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  # version          = var.cert_manager_version
  namespace        = "cert-manager"
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }

  depends_on = [aws_eks_node_group.private_nodes]
}

resource "helm_release" "cluster_autoscaler" 
uses
A Kubernetes component that automatically adjusts the number of nodes in your cluster based on workload demand.
If pods are pending because there aren’t enough resources → adds nodes.
If nodes are underutilized → removes them (scales down).
code
resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  # version    = var.cluster_autoscaler_version
  namespace  = "kube-system"

  set {
    name  = "autoDiscovery.clusterName"
    value = aws_eks_cluster.this.name
  }

  set {
    name  = "awsRegion"
    value = var.region
  }

  depends_on = [aws_eks_node_group.private_nodes]
}

resource "null_resource" "validate_vpc_cni"
uses
The Amazon VPC CNI (Container Network Interface) plugin is the default networking plugin for EKS.
It lets pods get native VPC IP addresses directly from the VPC subnet instead of using an overlay network.
This means pods behave like regular EC2 instances on the VPC network (same security groups, VPC routing, etc.)
code
resource "null_resource" "validate_vpc_cni" {
  depends_on = [aws_eks_addon.vpc_cni]

  triggers = {
    addon_name    = aws_eks_addon.vpc_cni.addon_name
    addon_version = aws_eks_addon.vpc_cni.addon_version
  }

  provisioner "local-exec" {
    command = "kubectl rollout status daemonset/aws-node -n kube-system --timeout=300s"
  }
}

resource "null_resource" "validate_coredns"
uses
CoreDNS is the DNS server inside Kubernetes.
It provides internal DNS resolution so pods can resolve service names like my-service.default.svc.cluster.local.
Without CoreDNS, service discovery inside the cluster would break
code
resource "null_resource" "validate_coredns" {
  depends_on = [aws_eks_addon.coredns]

  triggers = {
    addon_name    = aws_eks_addon.coredns.addon_name
    addon_version = aws_eks_addon.coredns.addon_version
  }

  provisioner "local-exec" {
    command = "kubectl rollout status deployment/coredns -n kube-system --timeout=300s"
  }
}

resource "null_resource" "validate_kube_proxy"
uses
A Kubernetes networking component that runs on every worker node.
It maintains iptables or IPVS rules so pods and services can talk to each other.
Handles:
Service routing (ClusterIP, NodePort, LoadBalancer)
Load balancing across pod endpoints
NAT translations for pod/service traffic
code
resource "null_resource" "validate_kube_proxy" {
  depends_on = [aws_eks_addon.kube_proxy]

  triggers = {
    addon_name    = aws_eks_addon.kube_proxy.addon_name
    addon_version = aws_eks_addon.kube_proxy.addon_version
  }

  provisioner "local-exec" {
    command = "kubectl rollout status daemonset/kube-proxy -n kube-system --timeout=300s"
  }
}

resource "null_resource" "validate_ebs_csi_driver"
uses
The Amazon EBS CSI driver lets Kubernetes/EKS pods dynamically provision and use EBS volumes as persistent storage.
Required for stateful apps (databases, message brokers, etc.) that need data to survive pod restarts.
code
resource "null_resource" "validate_ebs_csi_driver" {
  depends_on = [helm_release.ebs_csi_driver]

  triggers = {
    helm_name    = helm_release.ebs_csi_driver.name
    helm_version = helm_release.ebs_csi_driver.version
    chart        = helm_release.ebs_csi_driver.chart
    namespace    = helm_release.ebs_csi_driver.namespace
  }

  provisioner "local-exec" {
    command = <<EOT
      kubectl rollout status daemonset/ebs-csi-node -n kube-system --timeout=300s
      kubectl rollout status deployment/ebs-csi-controller -n kube-system --timeout=300s
    EOT
  }
}

resource "null_resource" "validate_cert_manager"
uses
cert-manager is a Kubernetes add-on that automates issuing and renewing TLS certificates.
Commonly used with Ingress controllers (Nginx, ALB) to automatically provision Let’s Encrypt certificates.
It also supports private CAs, Vault, and other external issuers.
code
resource "null_resource" "validate_cert_manager" {
  depends_on = [helm_release.cert_manager]

  triggers = {
    helm_name    = helm_release.cert_manager.name
    helm_version = helm_release.cert_manager.version
    chart        = helm_release.cert_manager.chart
    namespace    = helm_release.cert_manager.namespace
  }

  provisioner "local-exec" {
    command = <<EOT
      kubectl rollout status deployment/cert-manager -n cert-manager --timeout=300s
      kubectl rollout status deployment/cert-manager-webhook -n cert-manager --timeout=300s
      kubectl rollout status deployment/cert-manager-cainjector -n cert-manager --timeout=300s
    EOT
  }
}

resource "null_resource" "validate_cluster_autoscaler"
uses
The Cluster Autoscaler automatically adjusts the number of nodes in your Kubernetes/EKS cluster.
Scales up when pods are unschedulable (not enough resources).
Scales down when nodes are underutilized (to save cost).
In EKS, it integrates with Managed Node Groups or EC2 Auto Scaling Groups
code
resource "null_resource" "validate_cluster_autoscaler" {
  depends_on = [helm_release.cluster_autoscaler]

  triggers = {
    helm_name    = helm_release.cluster_autoscaler.name
    helm_version = helm_release.cluster_autoscaler.version
    chart        = helm_release.cluster_autoscaler.chart
    namespace    = helm_release.cluster_autoscaler.namespace
  }

  provisioner "local-exec" {
    command = "kubectl rollout status deployment/cluster-autoscaler -n kube-system --timeout=300s"
  }
}
