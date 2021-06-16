#
# FortiWeb instances deployment with bootstraed configuration
################



#Get AMI of latest FortiWeb Amazon Machine Image for BYOL
data "aws_ami" "latest_fwb_ami_byol" {
    most_recent = true
    owners = ["679593333241"] # Fortinet
        filter {
            name   = "name"
            values = ["*FortiWeb-AWS-*BYOL*"]
        }
}

#Get AMI of latest FortiWeb Amazon Machine Image for PAYGO / On Demand
data "aws_ami" "latest_fwb_ami_ond" {
    most_recent = true
    owners = ["679593333241"] # Fortinet
        filter {
            name   = "name"
            values = ["*FortiWeb-AWS-*OnDemand*"]
        }
}



# Create the temp s3 bucket for FortiWeb bootstrap
resource "aws_s3_bucket" "s3_bucket_fwb_tmp" {
    bucket = var.s3_bucket_fwb_tmp 
    acl    = "private" 
    tags = {
        Name = var.s3_bucket_fwb_tmp
    }
}

# Upload FortiWeb licenses to bucket
resource "aws_s3_bucket_object" "fwb1-license" {
    bucket = aws_s3_bucket.s3_bucket_fwb_tmp.id
    key    = var.fwb1_license_file
    acl    = "private" 
    source = var.fwb1_license_file
    etag   = filemd5(var.fwb1_license_file)
}

resource "aws_s3_bucket_object" "fwb2-license" {
    bucket = aws_s3_bucket.s3_bucket_fwb_tmp.id
    key    = var.fwb2_license_file
    acl    = "private" 
    source = var.fwb2_license_file
    etag   = filemd5(var.fwb2_license_file)
}


data "template_file" "fwb1_cli" {
    template = file("${path.module}/fwb-userdata.tpl")
    vars = {
      fwb_vm_name              = "FWB1"
      fwb_public_ip            = element(tolist(aws_network_interface.eni-fwb1-public1-subnet.private_ips), 0)
      fwb_ha_peer_ip           = element(tolist(aws_network_interface.eni-fwb2-public2-subnet.private_ips), 0)
      dns_server               = cidrhost(var.security_vpc_cidr, 2)
      linux_spoke1_private_dns = aws_instance.instance-spoke1.private_dns
      linux_spoke1_private_ip  = aws_instance.instance-spoke1.private_ip
      linux_spoke2_private_dns = aws_instance.instance-spoke1.private_dns
      linux_spoke2_private_ip  = aws_instance.instance-spoke2.private_ip
      fwb_alb1_public_ip_0     = data.dns_a_record_set.fwb-alb1-public-ip.addrs[0]
      fwb_alb1_public_ip_1     = data.dns_a_record_set.fwb-alb1-public-ip.addrs[1]
      fwb_alb1_dns_name        = aws_lb.fwb-alb1.dns_name
      fwb_ha_priority          = 1
      public_subnet_gw        = cidrhost(var.security_vpc_public_subnet_cidr2, 1)
      spoke1_cidr              = var.spoke_vpc1_cidr
      spoke2_cidr              = var.spoke_vpc2_cidr
    }
}

data "template_file" "fwb2_cli" {
    template = file("${path.module}/fwb-userdata.tpl")
    vars = {
      fwb_vm_name              = "FWB2"
      fwb_public_ip            = element(tolist(aws_network_interface.eni-fwb2-public2-subnet.private_ips), 0)
      fwb_ha_peer_ip           = element(tolist(aws_network_interface.eni-fwb1-public1-subnet.private_ips), 0)
      dns_server               = cidrhost(var.security_vpc_cidr, 2)      
      linux_spoke1_private_dns = aws_instance.instance-spoke1.private_dns
      linux_spoke1_private_ip  = aws_instance.instance-spoke1.private_ip
      linux_spoke2_private_dns = aws_instance.instance-spoke1.private_dns
      linux_spoke2_private_ip  = aws_instance.instance-spoke2.private_ip
      fwb_alb1_public_ip_0     = data.dns_a_record_set.fwb-alb1-public-ip.addrs[0]
      fwb_alb1_public_ip_1     = data.dns_a_record_set.fwb-alb1-public-ip.addrs[1]      
      fwb_alb1_dns_name        = aws_lb.fwb-alb1.dns_name
      fwb_ha_priority          = 2
      public_subnet_gw        = cidrhost(var.security_vpc_public_subnet_cidr2, 1)
      spoke1_cidr              = var.spoke_vpc1_cidr
      spoke2_cidr              = var.spoke_vpc2_cidr      
    }
}

# Upload file of fortiweb1 list of cli to s3 bucket
resource "aws_s3_bucket_object" "fwb1-cli" {
    bucket  = aws_s3_bucket.s3_bucket_fwb_tmp.id
    key     = "fwb1-cli.txt"
    acl     = "private" 
    content = data.template_file.fwb1_cli.rendered
    etag    = md5(data.template_file.fwb1_cli.rendered)
}

resource "aws_s3_bucket_object" "fwb2-cli" {
    bucket  = aws_s3_bucket.s3_bucket_fwb_tmp.id
    key     = "fwb2-cli.txt"
    acl     = "private" 
    content = data.template_file.fwb2_cli.rendered
    etag    = md5(data.template_file.fwb2_cli.rendered)
}


# Create an S3 IAM role for the FortiWeb instances
resource "aws_iam_role" "fortiweb-iam_role" {
    name = "fortiweb-iam_role"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "fortiweb-instance_profile" {
    name = "fortiweb-instance_profile"
    role = aws_iam_role.fortiweb-iam_role.name
}

resource "aws_iam_role_policy" "fortiweb-iam_role_policy" {
    name = "fortiweb-iam_role_policy"
    role = aws_iam_role.fortiweb-iam_role.id
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": ["arn:aws:s3:::${aws_s3_bucket.s3_bucket_fwb_tmp.id}"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": ["arn:aws:s3:::${aws_s3_bucket.s3_bucket_fwb_tmp.id}/*"]
    }
  ]
}
EOF
}



# Create the Security Group
resource "aws_security_group" "fortiweb-security-group" {
    vpc_id       = aws_vpc.vpc_sec.id
    name         = "FortiWeb Security Group"
    description  = "FortiWeb Security Group"
    
    # allow ingress of all ports ONLY for testing
    ingress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    } 
    
    # allow egress of all ports
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
      Name = "FortiWeb Security Group"
      Description = "FortiWeb Security Group"
    }
}


#FortiWeb  FWB1 ENIs
resource "aws_network_interface" "eni-fwb1-public1-subnet" {
    subnet_id   = aws_subnet.subnet_public1.id
    private_ips = [cidrhost(var.security_vpc_public_subnet_cidr1, 20)]
    security_groups = [aws_security_group.fortiweb-security-group.id]
    tags = {
      Name = "${var.tag_name_prefix}-${var.tag_name_unique}-FWB1 Port1"
    }
}

/*
resource "aws_network_interface" "eni-fwb1-private1-subnet" {
    subnet_id   = aws_subnet.subnet_private1.id
    private_ips = [cidrhost(var.security_vpc_private_subnet_cidr1, 20)]
    tags = {
      Name = "${var.tag_name_prefix}-${var.tag_name_unique}-FWB1 Port2"
    }
}
*/

#Elastic IPs for FBW1
resource "aws_eip" "fwb1-eip20-public1" {
  vpc               = true
  network_interface = aws_network_interface.eni-fwb1-public1-subnet.id
  associate_with_private_ip = element(tolist(aws_network_interface.eni-fwb1-public1-subnet.private_ips), 0)
  tags = {
    Name = "${var.tag_name_prefix}-${var.tag_name_unique}-fwb1-eip-public1"
  }
}



# FortiWeb1 instance deployment
resource "aws_instance" "fwb1-instance" {
    ami           = var.fwb_license_type == "byol" ? data.aws_ami.latest_fwb_ami_byol.image_id : data.aws_ami.latest_fwb_ami_ond.image_id
    instance_type = var.fwb_instance_type
    key_name      = var.keypair
    network_interface {
      network_interface_id = aws_network_interface.eni-fwb1-public1-subnet.id
      device_index         = 0
    }
 
    iam_instance_profile = aws_iam_instance_profile.fortiweb-instance_profile.id
  # in the user_data, the extraneous config_etag is needed to get the instance to be redeployed when the content of the config cli file changes, but not its filename
	user_data = <<-EOF
    fwb_json_start {
        "cloud-initd": "enable",
        "bucket": "${aws_s3_bucket.s3_bucket_fwb_tmp.id}",
        "region": "${var.region}",
        "license": "/${aws_s3_bucket_object.fwb1-license.key}",
        "config": "/${aws_s3_bucket_object.fwb1-cli.key}",
        "config_etag": "${aws_s3_bucket_object.fwb1-cli.etag}"       
    }
    EOF
    tags = {
      Name = "${var.tag_name_prefix}-${var.tag_name_unique}-FWB1"
    }
}



#FortiWeb  fwb2 ENIs
resource "aws_network_interface" "eni-fwb2-public2-subnet" {
    subnet_id   = aws_subnet.subnet_public2.id
    private_ips = [cidrhost(var.security_vpc_public_subnet_cidr2, 20)]
    security_groups = [aws_security_group.fortiweb-security-group.id]
    tags = {
      Name = "${var.tag_name_prefix}-${var.tag_name_unique}-fwb2 Port1"
    }
}


#Elastic IPs for FBW2
resource "aws_eip" "fwb2-eip20-public2" {
  vpc               = true
  network_interface = aws_network_interface.eni-fwb2-public2-subnet.id
  associate_with_private_ip = element(tolist(aws_network_interface.eni-fwb2-public2-subnet.private_ips), 0)
  tags = {
    Name = "${var.tag_name_prefix}-${var.tag_name_unique}-fwb2-eip-public2"
  }
}


# FortiWeb2 instance deployment
resource "aws_instance" "fwb2-instance" {
    ami           = var.fwb_license_type == "byol" ? data.aws_ami.latest_fwb_ami_byol.image_id : data.aws_ami.latest_fwb_ami_ond.image_id
    instance_type = var.fwb_instance_type
    key_name      = var.keypair
    network_interface {
      network_interface_id = aws_network_interface.eni-fwb2-public2-subnet.id
      device_index         = 0
    }
  
    iam_instance_profile = aws_iam_instance_profile.fortiweb-instance_profile.id
  # in the user_data, the extraneous config_etag is needed to get the instance to be redeployed when the content of the config cli file changes, but not its filename    
	user_data = <<-EOF
    fwb_json_start {
        "cloud-initd": "enable",
        "bucket": "${aws_s3_bucket.s3_bucket_fwb_tmp.id}",
        "region": "${var.region}",
        "license": "/${aws_s3_bucket_object.fwb2-license.key}",
        "config": "/${aws_s3_bucket_object.fwb2-cli.key}",
        "config_etag": "${aws_s3_bucket_object.fwb1-cli.etag}"        
    }
    EOF
    tags = {
      Name = "${var.tag_name_prefix}-${var.tag_name_unique}-FWB2"
    }
}