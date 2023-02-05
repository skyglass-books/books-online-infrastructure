// Provided at runtime

variable "region" {
  type = string
  description = "AWS region"
}

variable "author" {
  type = string
  description = "Created by"
}

variable "public_key" {
  type = string
  description = "SSH public key path"
}

variable "hosted_zone_id" {
  type = string
  description = "Route53 hosted zone id"
}

variable "domain_name" {
  type = string
  description = "Domain name"
}

variable "jenkins_username" {
  type = string
  description = "Jenkins admin user"
}

variable "jenkins_password" {
  type = string
  description = "Jenkins admin password"
}

variable "jenkins_credentials_id" {
  type = string
  description = "Jenkins workers SSH based credentials id"
}

variable "environment" {
  description = "EKS Cluster Environment"
  type        = string
}

variable "ssl_certificate_arn" {
  type = string
  description = "SSL Certificate ARN"
}

// Default values

variable "vpc_name" {
  type = string
  description = "VPC name"
  default     = "management"
}

variable "cidr_block" {
  type = string
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
}

variable "public_subnets_count" {
  type = number
  description = "Number of public subnets"
  default = 1
}

variable "bastion_instance_type" {
  type = string
  description = "Bastion instance type"
  default = "t2.micro"
}

variable "jenkins_master_instance_type" {
  type = string
  description = "Jenkins master EC2 instance type"
  default = "t2.medium"
}

variable "jenkins_worker_instance_type" {
  type = string
  description = "Jenkins worker EC2 instance type"
  default = "t2.small"
}