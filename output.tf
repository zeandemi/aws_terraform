output "cluster_id" {
  description = "EKS cluster Id"
  value       = aws_eks_cluster.eks_cluster[*].id
}

output "cluster_name" {
    description = "EKS cluster name"
    value = aws_eks_cluster.eks_cluster[*].id
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.eks_cluster[*].id
}

output "cluster_security_group_id" {
  description = "EKS cluster security group Id"
  value       = aws_security_group.private_node_group[*].id
}

output "region" {
    description = "EKS cluster region"
    value = var.region
}