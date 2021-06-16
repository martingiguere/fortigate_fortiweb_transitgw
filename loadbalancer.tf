#
# AWS Network Load Balancer in front of the FortiGate firewall instances
##
resource "aws_eip" "eip-fgt1-nlb-public1" {
  vpc               = true
  tags = {
    Name = "${var.tag_name_prefix}-eip-fgt1-nlb-public1"
  }
}

resource "aws_eip" "eip-fgt2-nlb-public2" {
  vpc               = true
  tags = {
    Name = "${var.tag_name_prefix}-eip-fgt2-nlb-public2"
  }
}

resource "aws_lb" "fgt-nlb" {
  #depends on igw
  name = "${var.tag_name_prefix}-${var.tag_name_unique}-fgt-nlb"
  internal = false
  enable_cross_zone_load_balancing = true
  load_balancer_type = "network"
  subnet_mapping {
    subnet_id     = aws_subnet.subnet_public1.id
    allocation_id = aws_eip.eip-fgt1-nlb-public1.id
  }
  subnet_mapping {
    subnet_id     = aws_subnet.subnet_public2.id
    allocation_id = aws_eip.eip-fgt2-nlb-public2.id
  }
  tags = {
    Name = "${var.tag_name_prefix}-${var.tag_name_unique}-fgt-nlb"
  }
}

resource "aws_lb_target_group" "fgt-nlb-target-group" {
  name = "${var.tag_name_prefix}-${var.tag_name_unique}-fgt-nlb-targetgrp"
  port = 7021
  protocol = "TCP"
  target_type = "ip"
  vpc_id = aws_vpc.vpc_sec.id
  health_check {
    protocol = "TCP"
    port = 8008
	interval = "10"
	healthy_threshold = "2"
	unhealthy_threshold = "2"
  }
  tags = {
    Name = "${var.tag_name_prefix}-${var.tag_name_unique}-fgt-nlb-targetgrp"
  }
}

resource "aws_lb_listener" "fgt-nlb-listener" {
  load_balancer_arn = aws_lb.fgt-nlb.arn
  port = 7021
  protocol = "TCP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.fgt-nlb-target-group.arn
  }
  tags = {
    Name = "${var.tag_name_prefix}-${var.tag_name_unique}-fgt-nlb-listener"
  }  
}

resource "aws_lb_target_group_attachment" "fgt-nlb-target-group_attachment1" {
  target_group_arn = aws_lb_target_group.fgt-nlb-target-group.arn
  target_id = aws_network_interface.eni-fgt1-public-subnet.private_ip
}

resource "aws_lb_target_group_attachment" "fgt-nlb-target-group_attachment2" {
  target_group_arn = aws_lb_target_group.fgt-nlb-target-group.arn
  target_id = aws_network_interface.eni-fgt2-public-subnet.private_ip
}


#
# AWS Application Load Balancer1 in front of the FortiWeb web application firewall instances
##

resource "aws_lb" "fwb-alb1" {
  name = "${var.tag_name_prefix}-${var.tag_name_unique}-fwb-alb1"
  internal = false
  enable_cross_zone_load_balancing = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.fortiweb-security-group.id]
  subnets         = [aws_subnet.subnet_public1.id,aws_subnet.subnet_public2.id]
  tags = {
    Name = "${var.tag_name_prefix}-${var.tag_name_unique}-fwb-alb1"
  }
}

resource "aws_alb_listener" "fwb-alb1-listener" {
  load_balancer_arn = aws_lb.fwb-alb1.arn
  port = 80
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.fwb-alb1-target-group.arn
  }
  tags = {
    Name = "${var.tag_name_prefix}-${var.tag_name_unique}-fwb-alb1-listener"
  }  
}

resource "aws_lb_target_group" "fwb-alb1-target-group" {
  name = "${var.tag_name_prefix}-${var.tag_name_unique}-fwb-alb1-targetgrp"
  port = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id = aws_vpc.vpc_sec.id
  health_check {
    port = 8443
    protocol = "HTTPS"
    healthy_threshold   = 3    
    unhealthy_threshold = 10    
    timeout             = 5    
    interval            = 10 
  }
  tags = {
    Name = "${var.tag_name_prefix}-${var.tag_name_unique}-fwb-alb1-targetgrp"
  }
}

#timer to wait for ALB in order to resolve A Records in DNS
resource "time_sleep" "wait_300_seconds" {
  //depends_on = [aws_lb.fwb-alb1]
  depends_on = [aws_lb_target_group.fwb-alb1-target-group]
  create_duration = "300s"
}

data "dns_a_record_set" "fwb-alb1-public-ip" {
  depends_on = [time_sleep.wait_300_seconds]  
  host = aws_lb.fwb-alb1.dns_name
}

resource "aws_alb_listener_rule" "fwb-alb1-listener_rule" {
  depends_on   = [aws_lb_target_group.fwb-alb1-target-group]  
  listener_arn = aws_alb_listener.fwb-alb1-listener.arn
  action {    
    type             = "forward"    
    target_group_arn = aws_lb_target_group.fwb-alb1-target-group.id  
  }

  condition {
    host_header {
      values = [aws_lb.fwb-alb1.dns_name]      
    }
  }
}

resource "aws_lb_target_group_attachment" "fwb-alb1-target-group_attachment1" {
  target_group_arn = aws_lb_target_group.fwb-alb1-target-group.arn
  target_id = aws_network_interface.eni-fwb1-public1-subnet.private_ip
}

resource "aws_lb_target_group_attachment" "fwb-alb1-target-group_attachment2" {
  target_group_arn = aws_lb_target_group.fwb-alb1-target-group.arn
  target_id = aws_network_interface.eni-fwb2-public2-subnet.private_ip
}