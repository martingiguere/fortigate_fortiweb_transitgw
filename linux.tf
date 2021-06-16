##############################################################################################################
# Intances AWS LINUX 2 for testing, with Apache2 httpd
##############################################################################################################
## Retrieve AMI info
data "aws_ami" "amazon-linux-2" {
 most_recent = true
 owners = ["amazon"]

 filter {
   name   = "name"
   values = ["amzn2-ami-hvm*"]
 }

 filter {
   name   = "architecture"
   values = ["x86_64"]
 }
}

# test linux in spoke1
resource "aws_instance" "instance-spoke1" {
  ami                    = data.aws_ami.amazon-linux-2.id
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.spoke_vpc1-priv1.id
  vpc_security_group_ids = [aws_security_group.SG-spoke1-ssh-icmp-https.id]
  key_name               = var.keypair
  user_data              = <<-EOF
    #!/bin/bash
    exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
    yum update -y
    yum install docker git -y
    systemctl enable docker
    systemctl start docker
    #Wait for Internet access through the FGT and TGW
    while ! ping -c 1 -n -w 1 www.google.com &> /dev/null
    do continue
    done
    #install docker container
    docker run --restart=always --name dvwa -d -p 80:80 vulnerables/web-dvwa
    EOF
  tags = {
    Name     = "${var.tag_name_prefix}-${var.tag_name_unique}-linux-spoke1"
  }
}

# test linux in spoke2
resource "aws_instance" "instance-spoke2" {
  ami                    = data.aws_ami.amazon-linux-2.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.spoke_vpc2-priv2.id
  vpc_security_group_ids = [aws_security_group.SG-spoke2-ssh-icmp-https.id]
  key_name               = var.keypair
  user_data              = <<-EOF
    #!/bin/bash
    exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1    
    yum update -y
    yum install httpd -y
    systemctl start httpd
    systemctl enable httpd
    echo "Hello from the EC2 instance $(hostname -f)." > /var/www/html/index.html
    EOF
  tags = {
    Name     = "${var.tag_name_prefix}-${var.tag_name_unique}-linux-spoke2"
  }
}

# test linux in mgmt
resource "aws_instance" "instance-mgmt" {
  ami                         = data.aws_ami.amazon-linux-2.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.spoke_mgmt-priv1.id
  vpc_security_group_ids      = [aws_security_group.SG-mgmt-ssh-icmp-https.id]
  key_name                    = var.keypair
  associate_public_ip_address = true
  user_data = <<-EOF
    #!/bin/bash
    exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1    
    yum update -y
    EOF

  tags = {
    Name     = "${var.tag_name_prefix}-${var.tag_name_unique}-linux-mgmt"
  }
}
