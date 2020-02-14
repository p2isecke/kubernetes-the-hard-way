provider "aws" {
  profile = "default"
  region  = "us-east-1"
  version = "2.46"
}

resource "aws_vpc" "kubernetes-the-hard-way" {
  cidr_block           = "10.240.0.0/24"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  tags = {
    Name    = "kubernetes-the-hard-way"
    Creator = "terraform"
  }
}

resource "aws_subnet" "public-kubernetes-the-hard-way" {
  vpc_id     = "${aws_vpc.kubernetes-the-hard-way.id}"
  cidr_block = "10.240.0.0/25"

  tags = {
    Name    = "public-kubernetes-the-hard-way"
    Creator = "terraform"
  }
}

resource "aws_subnet" "private-kubernetes-the-hard-way" {
  vpc_id     = "${aws_vpc.kubernetes-the-hard-way.id}"
  cidr_block = "10.240.0.128/25"

  tags = {
    Name    = "private-kubernetes-the-hard-way"
    Creator = "terraform"
  }
}

resource "aws_internet_gateway" "igw-kubernetes-the-hard-way" {
  vpc_id = "${aws_vpc.kubernetes-the-hard-way.id}"

  tags = {
    Name    = "igw-kubernetes-the-hard-way"
    Creator = "terraform"
  }
}

resource "aws_eip" "eip-kubernetes-the-hard-way" {
  vpc = true

  tags = {
    Name    = "eip-kubernetes-the-hard-way"
    Creator = "terraform"
  }

  depends_on = ["aws_internet_gateway.igw-kubernetes-the-hard-way"]
}

resource "aws_nat_gateway" "nat-kubernetes-the-hard-way" {
  allocation_id = "${aws_eip.eip-kubernetes-the-hard-way.id}"
  subnet_id     = "${aws_subnet.public-kubernetes-the-hard-way.id}"

  tags = {
    Name    = "nat-kubernetes-the-hard-way"
    Creator = "terraform"
  }

  depends_on = ["aws_internet_gateway.igw-kubernetes-the-hard-way"]
}

resource "aws_route_table" "public-route-table-kubernetes-the-hard-way" {
  vpc_id = "${aws_vpc.kubernetes-the-hard-way.id}"

  tags = {
    Name    = "public-route-table-kubernetes-the-hard-way"
    Creator = "terraform"
  }
}

resource "aws_route" "public-route-kubernetes-the-hard-way" {
  route_table_id         = "${aws_route_table.public-route-table-kubernetes-the-hard-way.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.igw-kubernetes-the-hard-way.id}"
  depends_on             = ["aws_route_table.public-route-table-kubernetes-the-hard-way"]
}

resource "aws_route_table_association" "public-route-subnet-kubernetes-the-hard-way" {
  subnet_id      = "${aws_subnet.public-kubernetes-the-hard-way.id}"
  route_table_id = "${aws_route_table.public-route-table-kubernetes-the-hard-way.id}"
}

resource "aws_route_table" "private-route-table-kubernetes-the-hard-way" {
  vpc_id = "${aws_vpc.kubernetes-the-hard-way.id}"

  tags = {
    Name    = "private-route-table-kubernetes-the-hard-way"
    Creator = "terraform"
  }
}

resource "aws_route" "private-route-kubernetes-the-hard-way" {
  route_table_id         = "${aws_route_table.private-route-table-kubernetes-the-hard-way.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.nat-kubernetes-the-hard-way.id}"
  depends_on             = ["aws_nat_gateway.nat-kubernetes-the-hard-way"]
}

resource "aws_route_table_association" "private-route-subnet-kubernetes-the-hard-way" {
  subnet_id      = "${aws_subnet.private-kubernetes-the-hard-way.id}"
  route_table_id = "${aws_route_table.private-route-table-kubernetes-the-hard-way.id}"
}

resource "aws_security_group" "kubernetes-the-hard-way-sg" {
  name        = "kubernetes-the-hard-way-sg"
  description = "Kubernetes security group"
  vpc_id      = "${aws_vpc.kubernetes-the-hard-way.id}"

  tags = {
    Name    = "sg-kubernetes-the-hard-way"
    Creator = "terraform"
  }
}

resource "aws_security_group_rule" "internal-comm-kubernetes-the-hard-way" {
  security_group_id = "${aws_security_group.kubernetes-the-hard-way-sg.id}"
  type              = "ingress"
  description       = "firewall rule that allows internal communication across all protocols"
  from_port         = -1
  to_port           = -1
  protocol          = "all"
  cidr_blocks       = ["10.240.0.0/24", "10.200.0.0/16"]
}

resource "aws_security_group_rule" "k8s-api-server-comm-kubernetes-the-hard-way" {
  security_group_id = "${aws_security_group.kubernetes-the-hard-way-sg.id}"
  type              = "ingress"
  description       = "firewall rule that allows access to the Kubernetes API server on port 6443"
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_security_group_rule" "https-comm-kubernetes-the-hard-way" {
  security_group_id = "${aws_security_group.kubernetes-the-hard-way-sg.id}"
  type              = "ingress"
  description       = "firewall rule that allows external HTTPS"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "icmp-comm-kubernetes-the-hard-way" {
  security_group_id = "${aws_security_group.kubernetes-the-hard-way-sg.id}"
  type              = "ingress"
  description       = "firewall rule that allows external ICMP"
  from_port         = -1
  to_port           = -1
  protocol          = "icmp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "egress-kubernetes-the-hard-way" {
  security_group_id = "${aws_security_group.kubernetes-the-hard-way-sg.id}"
  type              = "egress"
  description       = "default-egress-kubernetes-the-hard-way"
  from_port         = -1
  to_port           = -1
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_lb" "nlb-kubernetes-the-hard-way" {
  name               = "nlb-kubernetes-the-hard-way"
  internal           = false
  load_balancer_type = "network"
  subnets            = ["${aws_subnet.public-kubernetes-the-hard-way.id}"]

  enable_deletion_protection = false

  tags = {
    Name    = "nlb-kubernetes-the-hard-way"
    Creator = "terraform"
  }
}

resource "aws_lb_target_group" "tg-kubernetes-the-hard-way" {
  name        = "tg-kubernetes-the-hard-way"
  port        = 6443
  protocol    = "TCP"
  vpc_id      = "${aws_vpc.kubernetes-the-hard-way.id}"
  target_type = "ip"
}

variable "control_plane_instances" {
  description = "Create three compute instances which will host the Kubernetes control plane"
  type        = "list"
  default     = ["10.240.0.140", "10.240.0.141", "10.240.0.142"]
}

resource "aws_lb_target_group_attachment" "register-tg-kubernetes-the-hard-way" {
  count            = length(var.control_plane_instances)
  target_group_arn = "${aws_lb_target_group.tg-kubernetes-the-hard-way.arn}"
  target_id        = "${element(var.control_plane_instances, count.index)}"
  port             = 80
}

resource "aws_lb_listener" "public-access-kubernetes-the-hard-way" {
  load_balancer_arn = "${aws_lb.nlb-kubernetes-the-hard-way.arn}"
  port              = "443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.tg-kubernetes-the-hard-way.arn}"
  }
}

output "kubernetes-public-ip" {
  value = "${aws_lb.nlb-kubernetes-the-hard-way.dns_name}"
}

data "aws_ami" "kubernetes-the-hard-way-ubuntu" {
  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["*ubuntu-bionic-18.04*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_instance" "kubernetes-the-hard-way-controller0" {
  ami                         = "${data.aws_ami.kubernetes-the-hard-way-ubuntu.id}"
  instance_type               = "t2.micro"
  associate_public_ip_address = false
  key_name                    = "kubernetes-the-hard-way"
  vpc_security_group_ids      = ["${aws_security_group.kubernetes-the-hard-way-sg.id}"]
  private_ip                  = "10.240.0.140"
  user_data                   = "name=controller-0"
  subnet_id                   = "${aws_subnet.private-kubernetes-the-hard-way.id}"
  source_dest_check           = true

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 50
  }

  tags = {
    Name    = "kubernetes-the-hard-way-controller0"
    Creator = "terraform"
  }
}

output "controller-0" {
  value = "${aws_instance.kubernetes-the-hard-way-controller0.private_ip}"
}

resource "aws_instance" "kubernetes-the-hard-way-controller1" {
  ami                         = "${data.aws_ami.kubernetes-the-hard-way-ubuntu.id}"
  instance_type               = "t2.micro"
  associate_public_ip_address = false
  key_name                    = "kubernetes-the-hard-way"
  vpc_security_group_ids      = ["${aws_security_group.kubernetes-the-hard-way-sg.id}"]
  private_ip                  = "10.240.0.141"
  user_data                   = "name=controller-1"
  subnet_id                   = "${aws_subnet.private-kubernetes-the-hard-way.id}"
  source_dest_check           = true

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 50
  }

  tags = {
    Name    = "kubernetes-the-hard-way-controller1"
    Creator = "terraform"
  }
}

output "controller-1" {
  value = "${aws_instance.kubernetes-the-hard-way-controller1.private_ip}"
}

resource "aws_instance" "kubernetes-the-hard-way-controller2" {
  ami                         = "${data.aws_ami.kubernetes-the-hard-way-ubuntu.id}"
  instance_type               = "t2.micro"
  associate_public_ip_address = false
  key_name                    = "kubernetes-the-hard-way"
  vpc_security_group_ids      = ["${aws_security_group.kubernetes-the-hard-way-sg.id}"]
  private_ip                  = "10.240.0.142"
  user_data                   = "name=controller-2"
  subnet_id                   = "${aws_subnet.private-kubernetes-the-hard-way.id}"
  source_dest_check           = true

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 50
  }

  tags = {
    Name    = "kubernetes-the-hard-way-controller2"
    Creator = "terraform"
  }
}

output "controller-2" {
  value = "${aws_instance.kubernetes-the-hard-way-controller2.private_ip}"
}

resource "aws_instance" "kubernetes-the-hard-way-worker0" {
  ami                         = "${data.aws_ami.kubernetes-the-hard-way-ubuntu.id}"
  instance_type               = "t2.micro"
  associate_public_ip_address = false
  key_name                    = "kubernetes-the-hard-way"
  vpc_security_group_ids      = ["${aws_security_group.kubernetes-the-hard-way-sg.id}"]
  private_ip                  = "10.240.0.240"
  user_data                   = "name=worker-0"
  subnet_id                   = "${aws_subnet.private-kubernetes-the-hard-way.id}"
  source_dest_check           = true

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 10
  }

  tags = {
    Name    = "kubernetes-the-hard-way-worker0"
    Creator = "terraform"
  }
}

output "worker-0" {
  value = "${aws_instance.kubernetes-the-hard-way-worker0.private_ip}"
}

resource "aws_instance" "kubernetes-the-hard-way-worker1" {
  ami                         = "${data.aws_ami.kubernetes-the-hard-way-ubuntu.id}"
  instance_type               = "t2.micro"
  associate_public_ip_address = false
  key_name                    = "kubernetes-the-hard-way"
  vpc_security_group_ids      = ["${aws_security_group.kubernetes-the-hard-way-sg.id}"]
  private_ip                  = "10.240.0.241"
  user_data                   = "name=worker-1"
  subnet_id                   = "${aws_subnet.private-kubernetes-the-hard-way.id}"
  source_dest_check           = true

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 10
  }

  tags = {
    Name    = "kubernetes-the-hard-way-worker1"
    Creator = "terraform"
  }
}

output "worker-1" {
  value = "${aws_instance.kubernetes-the-hard-way-worker1.private_ip}"
}

resource "aws_instance" "kubernetes-the-hard-way-worker2" {
  ami                         = "${data.aws_ami.kubernetes-the-hard-way-ubuntu.id}"
  instance_type               = "t2.micro"
  associate_public_ip_address = false
  key_name                    = "kubernetes-the-hard-way"
  vpc_security_group_ids      = ["${aws_security_group.kubernetes-the-hard-way-sg.id}"]
  private_ip                  = "10.240.0.242"
  user_data                   = "name=worker-2"
  subnet_id                   = "${aws_subnet.private-kubernetes-the-hard-way.id}"
  source_dest_check           = true

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 10
  }

  tags = {
    Name    = "kubernetes-the-hard-way-worker2"
    Creator = "terraform"
  }
}

output "worker-2" {
  value = "${aws_instance.kubernetes-the-hard-way-worker2.private_ip}"
}

resource "aws_security_group" "ssh-access-kubernetes-the-hard-way" {
  name        = "ssh-access-kubernetes-the-hard-way"
  description = "Kubernetes security group"
  vpc_id      = "${aws_vpc.kubernetes-the-hard-way.id}"

  tags = {
    Name    = "ssh-access-kubernetes-the-hard-way"
    Creator = "terraform"
  }
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

resource "aws_security_group_rule" "ssh-kubernetes-the-hard-way" {
  security_group_id = "${aws_security_group.ssh-access-kubernetes-the-hard-way.id}"
  type              = "ingress"
  description       = "firewall rule that allows SSH access"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["${chomp(data.http.myip.body)}/32"]
}

resource "aws_security_group_rule" "ssh-egress-kubernetes-the-hard-way" {
  security_group_id = "${aws_security_group.ssh-access-kubernetes-the-hard-way.id}"
  type              = "egress"
  description       = "default-egress-kubernetes-the-hard-way"
  from_port         = -1
  to_port           = -1
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
}
variable "jump-server" {
  type = string
  default = "10.240.0.10"
}

resource "aws_security_group_rule" "ssh-jump-kubernetes-the-hard-way" {
  security_group_id = "${aws_security_group.kubernetes-the-hard-way-sg.id}"
  type              = "ingress"
  description       = "firewall rule that allows SSH access only from the jump server"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["${var.jump-server}/32"]
}

resource "aws_instance" "jump-kubernetes-the-hard-way" {
  ami                         = "${data.aws_ami.kubernetes-the-hard-way-ubuntu.id}"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  key_name                    = "kubernetes-the-hard-way"
  vpc_security_group_ids      = ["${aws_security_group.ssh-access-kubernetes-the-hard-way.id}"]
  private_ip                  = "${var.jump-server}"
  user_data                   = "name=jump"
  subnet_id                   = "${aws_subnet.public-kubernetes-the-hard-way.id}"
  source_dest_check           = true

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 10
  }

  tags = {
    Name    = "jump-kubernetes-the-hard-way"
    Creator = "terraform"
  }
}

output "jump-server" {
  value = "${aws_instance.jump-kubernetes-the-hard-way.public_ip}"
}