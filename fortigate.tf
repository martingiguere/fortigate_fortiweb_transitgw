##############################################################################################################
#
# AWS Transit Gateway
# FortiGate setup with Active/Active in Multiple Availability Zones
#
##############################################################################################################

##############################################################################################################
# GENERAL
##############################################################################################################

# Security Groups
## Need to create 4 of them as our Security Groups are linked to a VPC

resource "aws_security_group" "SG-spoke1-ssh-icmp-https" {
  name        = "SG-spoke1-ssh-icmp-https"
  description = "Allow SSH, HTTPS and ICMP traffic"
  vpc_id      = aws_vpc.spoke_vpc1.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8 # the ICMP type number for 'Echo'
    to_port     = 0 # the ICMP code
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0 # the ICMP type number for 'Echo Reply'
    to_port     = 0 # the ICMP code
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name     = "SG-spoke1-ssh-icmp-https"
  }
}

resource "aws_security_group" "SG-spoke2-ssh-icmp-https" {
  name        = "SG-spoke2-ssh-icmp-https"
  description = "Allow SSH, HTTPS and ICMP traffic"
  vpc_id      = aws_vpc.spoke_vpc2.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    from_port   = -1 # all icmp
    to_port     = -1 # all icmp
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name     = "SG-spoke2-ssh-icmp-https"
  }
}

resource "aws_security_group" "SG-mgmt-ssh-icmp-https" {
  name        = "SG-mgmt-ssh-icmp-https"
  description = "Allow SSH, HTTPS and ICMP traffic"
  vpc_id      = aws_vpc.spoke_mgmt.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1 # the ICMP type number for 'Echo Reply'
    to_port     = -1 # the ICMP code
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name     = "SG-mgmt-ssh-icmp-https"
  }
}

resource "aws_security_group" "SG-vpc-sec-all" {
  name        = "SG-all"
  description = "Allow all traffic"
  vpc_id      = aws_vpc.vpc_sec.id

  ingress {
    description = "Allow remote access to FGT"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name     = "SG-vpc-all"
  }
}

##############################################################################################################
# FORTIGATES VM
##############################################################################################################
# Create the IAM role/profile for the API Call
resource "aws_iam_instance_profile" "APICall_profile" {
  name = "APICall_profile"
  role = aws_iam_role.APICallrole.name
}

resource "aws_iam_role" "APICallrole" {
  name = "APICall_role"

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

resource "aws_iam_policy" "APICallpolicy" {
  name        = "APICall_policy"
  path        = "/"
  description = "Policies for the FGT APICall Role"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement":
      [
        {
          "Effect": "Allow",
          "Action": 
            [
              "ec2:Describe*",
              "ec2:AssociateAddress",
              "ec2:AssignPrivateIpAddresses",
              "ec2:UnassignPrivateIpAddresses",
              "ec2:ReplaceRoute"
            ],
            "Resource": "*"
        }
      ]
}
EOF
}

resource "aws_iam_policy_attachment" "APICall-attach" {
  name       = "APICall-attachment"
  roles      = [aws_iam_role.APICallrole.name]
  policy_arn = aws_iam_policy.APICallpolicy.arn
}


# Create all the eni interfaces
resource "aws_network_interface" "eni-fgt1-public-subnet" {
  subnet_id         = aws_subnet.subnet_public1.id
  security_groups   = [aws_security_group.SG-vpc-sec-all.id]
  private_ips       = [cidrhost(var.security_vpc_public_subnet_cidr1, 10)]  
  source_dest_check = false
  tags = {
    Name = "${var.tag_name_prefix}-fgt1-eni-public-subnet"
  }
}

resource "aws_network_interface" "eni-fgt2-public-subnet" {
  subnet_id         = aws_subnet.subnet_public2.id
  security_groups   = [aws_security_group.SG-vpc-sec-all.id]
  private_ips       = [cidrhost(var.security_vpc_public_subnet_cidr2, 10)]    
  source_dest_check = false
  tags = {
    Name = "${var.tag_name_prefix}-fgt2-eni-public-subnet"
  }
}

resource "aws_network_interface" "eni-fgt1-private-subnet" {
  subnet_id         = aws_subnet.subnet_private1.id
  security_groups   = [aws_security_group.SG-vpc-sec-all.id]
  private_ips       = [cidrhost(var.security_vpc_private_subnet_cidr1, 10)]
  source_dest_check = false
  tags = {
    Name = "${var.tag_name_prefix}-fgt1-enihb"
  }
}

resource "aws_network_interface" "eni-fgt2-private-subnet" {
  subnet_id         = aws_subnet.subnet_private2.id
  security_groups   = [aws_security_group.SG-vpc-sec-all.id]
  private_ips       = [cidrhost(var.security_vpc_private_subnet_cidr2, 10)]
  source_dest_check = false
  tags = {
    Name = "${var.tag_name_prefix}-fgt2-enihb"
  }
}


# Create and attach the eip to the FortiGate firewalls
resource "aws_eip" "eip-public1" {
  vpc               = true
  network_interface = aws_network_interface.eni-fgt1-public-subnet.id
  tags = {
    Name = "${var.tag_name_prefix}-eip-public1"
  }
}

resource "aws_eip" "eip-public2" {
  vpc               = true
  network_interface = aws_network_interface.eni-fgt2-public-subnet.id
  tags = {
    Name = "${var.tag_name_prefix}-eip-public2"
  }
}



##
# Transit Gateway VPN Attachments
resource "aws_customer_gateway" "fgt1-cgw" {
  bgp_asn =  var.cgw_bgp_asn
  ip_address = aws_eip.eip-public1.public_ip
  type = "ipsec.1"
  tags = {
	  Name = "${var.tag_name_prefix}-fgt1-cgw"
  }
}

resource "aws_customer_gateway" "fgt2-cgw" {
  bgp_asn =  var.cgw_bgp_asn
  ip_address = aws_eip.eip-public2.public_ip
  type = "ipsec.1"
  tags = {
	  Name = "${var.tag_name_prefix}-fgt2-cgw"
  }
}

resource "aws_vpn_connection" "tgw-vpn-fgt1" {
  customer_gateway_id = aws_customer_gateway.fgt1-cgw.id
  transit_gateway_id = aws_ec2_transit_gateway.TGW-XAZ.id
  type = "ipsec.1"
  static_routes_only = false
  tags = {
	  Name = "${var.tag_name_prefix}-fgt1-vpn"
  }
}

resource "aws_vpn_connection" "tgw-vpn-fgt2" {
  customer_gateway_id = aws_customer_gateway.fgt2-cgw.id
  transit_gateway_id = aws_ec2_transit_gateway.TGW-XAZ.id
  type = "ipsec.1"
  static_routes_only = false
  tags = {
	  Name = "${var.tag_name_prefix}-fgt2-vpn"
  }
}



#Get AMI of FortiGate Amazon Machine Image Bring Your Own License
data "aws_ami" "latest_fgt_ami_byol" {
    most_recent = true
    owners = ["679593333241"] # Fortinet
        filter {
            name   = "name"
            values = ["*FortiGate-VM64-AWS*(6.4.5)*"]
        }
}

#Get AMI of FortiGate Amazon Machine Image PAYGO / On Demand
data "aws_ami" "latest_fgt_ami_ond" {
    most_recent = true
    owners = ["679593333241"] # Fortinet
        filter {
            name   = "name"
            values = ["*FortiGate-VM64-AWS*OND*(6.4.5)*"]
        }
}



# Create the instances
resource "aws_instance" "fgt1" {
  ami                  = var.fgt_license_type == "byol" ? data.aws_ami.latest_fgt_ami_byol.image_id : data.aws_ami.latest_fgt_ami_ond.image_id
  instance_type        = var.fgt_instance_type
  availability_zone    = var.availability_zone1
  key_name             = var.keypair
  user_data            = data.template_file.fgt_userdata1.rendered
  iam_instance_profile = aws_iam_instance_profile.APICall_profile.name
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.eni-fgt1-public-subnet.id
  }
  network_interface {
    device_index         = 1
    network_interface_id = aws_network_interface.eni-fgt1-private-subnet.id
  }
  tags = {
    Name = "${var.tag_name_prefix}-${var.tag_name_unique}-fgt1"
  }
}

resource "aws_instance" "fgt2" {
  ami                  = var.fgt_license_type == "byol" ? data.aws_ami.latest_fgt_ami_byol.image_id : data.aws_ami.latest_fgt_ami_ond.image_id
  instance_type        = var.fgt_instance_type
  availability_zone    = var.availability_zone2
  key_name             = var.keypair
  user_data            = data.template_file.fgt_userdata2.rendered
  iam_instance_profile = aws_iam_instance_profile.APICall_profile.name
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.eni-fgt2-public-subnet.id
  }
  network_interface {
    device_index         = 1
    network_interface_id = aws_network_interface.eni-fgt2-private-subnet.id
  }
  tags = {
    Name = "${var.tag_name_prefix}-${var.tag_name_unique}-fgt2"
  }
}

data "template_file" "fgt_userdata1" {
  template = file("./fgt-userdata.tpl")

  vars = {
    fgt_id               = "FGT1"
    type                 = var.fgt_license_type
    license_file         = var.fgt1_license_file
    fgt_public_ip        = element(tolist(aws_network_interface.eni-fgt1-public-subnet.private_ips), 0)
    fgt_public_ip_w_cidr = join("/", [element(tolist(aws_network_interface.eni-fgt1-public-subnet.private_ips), 0), cidrnetmask(var.security_vpc_public_subnet_cidr1)])
    fgt_private_ip       = join("/", [element(tolist(aws_network_interface.eni-fgt1-private-subnet.private_ips), 0), cidrnetmask(var.security_vpc_private_subnet_cidr1)])
    fgt_public_eip       = aws_eip.eip-public1.public_ip
    fgt_peer_private_ip  = element(tolist(aws_network_interface.eni-fgt2-public-subnet.private_ips), 0)
    public_gw            = cidrhost(var.security_vpc_public_subnet_cidr1, 1)
    private_gw           = cidrhost(var.security_vpc_private_subnet_cidr1, 1)
    security_vpc_cidr    = var.security_vpc_cidr
    spoke1_cidr          = var.spoke_vpc1_cidr
    spoke2_cidr          = var.spoke_vpc2_cidr
    mgmt_cidr            = var.mgmt_cidr
    linux_spoke1_ip      = aws_instance.instance-spoke1.private_ip
    admin_password       = var.fgt_admin_password
    fgt_bgp_asn          = var.cgw_bgp_asn
    tgw_bgp_asn          = aws_ec2_transit_gateway.TGW-XAZ.amazon_side_asn
    t1_id = "${aws_vpn_connection.tgw-vpn-fgt1.id}-1"
    t1_ip = aws_vpn_connection.tgw-vpn-fgt1.tunnel1_address
    t1_lip = aws_vpn_connection.tgw-vpn-fgt1.tunnel1_cgw_inside_address
    t1_rip = aws_vpn_connection.tgw-vpn-fgt1.tunnel1_vgw_inside_address
    t1_psk = aws_vpn_connection.tgw-vpn-fgt1.tunnel1_preshared_key
    t1_bgp = aws_vpn_connection.tgw-vpn-fgt1.tunnel1_bgp_asn
    t2_id = "${aws_vpn_connection.tgw-vpn-fgt1.id}-2"
    t2_ip = aws_vpn_connection.tgw-vpn-fgt1.tunnel2_address
    t2_lip = aws_vpn_connection.tgw-vpn-fgt1.tunnel2_cgw_inside_address
    t2_rip = aws_vpn_connection.tgw-vpn-fgt1.tunnel2_vgw_inside_address
    t2_psk = aws_vpn_connection.tgw-vpn-fgt1.tunnel2_preshared_key
    t2_bgp = aws_vpn_connection.tgw-vpn-fgt1.tunnel2_bgp_asn
  }
}

data "template_file" "fgt_userdata2" {
  template = file("./fgt-userdata.tpl")

  vars = {
    fgt_id               = "FGT2"
    type                 = var.fgt_license_type
    license_file         = var.fgt2_license_file
    fgt_public_ip        = element(tolist(aws_network_interface.eni-fgt2-public-subnet.private_ips), 0)
    fgt_public_ip_w_cidr = join("/", [element(tolist(aws_network_interface.eni-fgt2-public-subnet.private_ips), 0), cidrnetmask(var.security_vpc_public_subnet_cidr1)])    
    fgt_private_ip       = join("/", [element(tolist(aws_network_interface.eni-fgt2-private-subnet.private_ips), 0), cidrnetmask(var.security_vpc_private_subnet_cidr2)])
    fgt_public_eip       = aws_eip.eip-public2.public_ip    
    fgt_peer_private_ip  = element(tolist(aws_network_interface.eni-fgt1-public-subnet.private_ips), 0)    
    public_gw            = cidrhost(var.security_vpc_public_subnet_cidr2, 1)
    private_gw           = cidrhost(var.security_vpc_private_subnet_cidr2, 1)    
    security_vpc_cidr    = var.security_vpc_cidr
    spoke1_cidr          = var.spoke_vpc1_cidr
    spoke2_cidr          = var.spoke_vpc2_cidr
    mgmt_cidr            = var.mgmt_cidr
    linux_spoke1_ip      = aws_instance.instance-spoke1.private_ip    
    admin_password       = var.fgt_admin_password
    fgt_bgp_asn          = var.cgw_bgp_asn
    tgw_bgp_asn          = aws_ec2_transit_gateway.TGW-XAZ.amazon_side_asn
    t1_id                = "${aws_vpn_connection.tgw-vpn-fgt2.id}-1"
    t1_ip = aws_vpn_connection.tgw-vpn-fgt2.tunnel1_address
    t1_lip = aws_vpn_connection.tgw-vpn-fgt2.tunnel1_cgw_inside_address
    t1_rip = aws_vpn_connection.tgw-vpn-fgt2.tunnel1_vgw_inside_address
    t1_psk = aws_vpn_connection.tgw-vpn-fgt2.tunnel1_preshared_key
    t1_bgp = aws_vpn_connection.tgw-vpn-fgt2.tunnel1_bgp_asn
    t2_id = "${aws_vpn_connection.tgw-vpn-fgt2.id}-2"
    t2_ip = aws_vpn_connection.tgw-vpn-fgt2.tunnel2_address
    t2_lip = aws_vpn_connection.tgw-vpn-fgt2.tunnel2_cgw_inside_address
    t2_rip = aws_vpn_connection.tgw-vpn-fgt2.tunnel2_vgw_inside_address
    t2_psk = aws_vpn_connection.tgw-vpn-fgt2.tunnel2_preshared_key
    t2_bgp = aws_vpn_connection.tgw-vpn-fgt2.tunnel2_bgp_asn    
  }
}
