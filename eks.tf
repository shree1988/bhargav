resource "aws_eks_cluster" "gitlab-demo" {
  name     = "gitlab-demo-cluster"
  role_arn = aws_iam_role.gitlab-role.arn

  vpc_config {
    subnet_ids = [aws_subnet.private_subnet01.id, aws_subnet.private_subnet02.id]
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.gitlab-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.gitlab-AmazonEKSVPCResourceController,
  ]
}

##########IAM policy for EKS#############3
data "aws_iam_policy_document" "gitlab_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "gitlab-role" {
  name     = "gitlab-demo-cluster"
  assume_role_policy = data.aws_iam_policy_document.gitlab_assume_role.json
}

resource "aws_iam_role_policy_attachment" "gitlab-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.gitlab-role.name
}

# Optionally, enable Security Groups for Pods
# Reference: https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html
resource "aws_iam_role_policy_attachment" "gitlab-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.gitlab-role.name
}

#######Fargate
resource "aws_eks_fargate_profile" "gitlab_fargate" {
  cluster_name           = aws_eks_cluster.gitlab-demo.name
  fargate_profile_name   = "gitlab-fargate"
  pod_execution_role_arn = aws_iam_role.gitlab-fargate-assumerole.arn
  subnet_ids             = [aws_subnet.private_subnet01.id, aws_subnet.private_subnet02.id]

  selector {
    namespace = "gitlab"
  }
}

resource "aws_iam_role" "gitlab-fargate-assumerole" {
  name = "eks-fargate-gitlab"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "gitlab-AmazonEKSFargatePodExecutionRolePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.gitlab-fargate-assumerole.name
}