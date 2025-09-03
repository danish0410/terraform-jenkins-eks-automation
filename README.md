created github_new folder and clone the repo
updated the code with ebs_csi_driver, cert_manager, cluster_autoscaler etc
run the terraform init, terraform validate, terraform plan and terraform apply
eks was created but dono how to view the addons in eks
tomorrow with do the same process and view the addons

resource "helm_release" "ebs_csi_driver" {
  name       = "aws-ebs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  chart      = "aws-ebs-csi-driver"
  # version    = var.ebs_csi_version
  namespace  = "kube-system"

  depends_on = [aws_eks_node_group.private_nodes]
}

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
