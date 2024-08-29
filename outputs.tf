output "endpoint" {
  value = aws_eks_cluster.gitlab-demo.endpoint
}
output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.gitlab-demo.certificate_authority[0].data
}