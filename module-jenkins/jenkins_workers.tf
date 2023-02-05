// Jenkins worker AMI
data "aws_ami" "jenkins-worker" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["jenkins-worker*"]
  }
}


locals {
  user_data_jenkins_worker = templatefile("${path.module}/scripts/join-cluster.tpl", {
    jenkins_url            = "http://${aws_instance.jenkins_master.private_ip}:8080"
    jenkins_username       = var.jenkins_username
    jenkins_password       = var.jenkins_password
    jenkins_credentials_id = var.jenkins_credentials_id
  })
}


// Jenkinw workers security group
resource "aws_security_group" "jenkins_workers_sg" {
  name        = "jenkins_workers_sg"
  description = "Allow traffic on port 22 from Jenkins master SG"
  vpc_id      = aws_vpc.management.id

  ingress {
    from_port       = "22"
    to_port         = "22"
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins_master_sg.id, aws_security_group.bastion_host.id]
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name   = "jenkins_workers_sg"
    Author = var.author
  }
}

// Jenkins workers launch configuration
resource "aws_launch_configuration" "jenkins_workers_launch_conf" {
  name            = "jenkins_workers_config"
  image_id        = data.aws_ami.jenkins-worker.id
  instance_type   = var.jenkins_worker_instance_type
  key_name        = aws_key_pair.management.id
  security_groups = [aws_security_group.jenkins_workers_sg.id]
  user_data       = local.user_data_jenkins_worker

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 15
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

// ASG Jenkins workers
resource "aws_autoscaling_group" "jenkins_workers" {
  name                 = "jenkins_workers_asg"
  launch_configuration = aws_launch_configuration.jenkins_workers_launch_conf.name
  vpc_zone_identifier  = [for subnet in aws_subnet.public_subnets : subnet.id]
  min_size             = 1
  max_size             = 5

  depends_on = [aws_instance.jenkins_master, aws_elb.jenkins_elb]

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "jenkins_worker"
    propagate_at_launch = true
  }

  tag {
    key                 = "Author"
    value               = var.author
    propagate_at_launch = true
  }
}