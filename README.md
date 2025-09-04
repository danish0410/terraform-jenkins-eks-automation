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
