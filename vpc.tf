##############################################################################################################
# VPC SECURITY
##############################################################################################################
resource "aws_vpc" "vpc_sec" {
  cidr_block           = var.security_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.tag_name_prefix}-vpc_sec"
  }
}

# IGW
resource "aws_internet_gateway" "igw_sec" {
  vpc_id = aws_vpc.vpc_sec.id
  tags = {
    Name = "${var.tag_name_prefix}-${var.tag_name_unique}-igw_sec"
  }
}

# Subnets
resource "aws_subnet" "subnet_public1" {
  vpc_id            = aws_vpc.vpc_sec.id
  cidr_block        = var.security_vpc_public_subnet_cidr1
  availability_zone = var.availability_zone1
  tags = {
    Name = "${var.tag_name_prefix}-${var.tag_name_unique}-public-subnet1"
  }
}

resource "aws_subnet" "subnet_public2" {
  vpc_id            = aws_vpc.vpc_sec.id
  cidr_block        = var.security_vpc_public_subnet_cidr2
  availability_zone = var.availability_zone2
  tags = {
    Name = "${var.tag_name_prefix}-${var.tag_name_unique}-public-subnet2"
  }
}

resource "aws_subnet" "subnet_private1" {
  vpc_id            = aws_vpc.vpc_sec.id
  cidr_block        = var.security_vpc_private_subnet_cidr1
  availability_zone = var.availability_zone1
  tags = {
    Name = "${var.tag_name_prefix}-${var.tag_name_unique}-private-subnet1"
  }
}

resource "aws_subnet" "subnet_private2" {
  vpc_id            = aws_vpc.vpc_sec.id
  cidr_block        = var.security_vpc_private_subnet_cidr2
  availability_zone = var.availability_zone2
  tags = {
    Name = "${var.tag_name_prefix}-${var.tag_name_unique}-private-subnet2"
  }
}

# Routes
resource "aws_route_table" "public_subnet_rt" {
  vpc_id = aws_vpc.vpc_sec.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_sec.id
  }
  route {
    cidr_block         = var.spoke_vpc1_cidr
    network_interface_id  = aws_network_interface.eni-fgt1-private-subnet.id
  }
  route {
    cidr_block         = var.spoke_vpc2_cidr
    network_interface_id  = aws_network_interface.eni-fgt2-private-subnet.id
  }
  tags = {
    Name = "${var.tag_name_prefix}-${var.tag_name_unique}-public-subnet-rt"
  }
}

resource "aws_route_table" "private_subnet_rt" {
  vpc_id = aws_vpc.vpc_sec.id
  tags = {
    Name = "${var.tag_name_prefix}-${var.tag_name_unique}-private-subnet-rt"
  }
}

# Route tables associations
resource "aws_route_table_association" "public_subnet_rt_association1" {
  subnet_id      = aws_subnet.subnet_public1.id
  route_table_id = aws_route_table.public_subnet_rt.id
}

resource "aws_route_table_association" "public_subnet_rt_association2" {
  subnet_id      = aws_subnet.subnet_public2.id
  route_table_id = aws_route_table.public_subnet_rt.id
}


#############################################################################################################
# VPC SPOKE1
#############################################################################################################
resource "aws_vpc" "spoke_vpc1" {
  cidr_block = var.spoke_vpc1_cidr

  tags = {
    Name     = "${var.tag_name_prefix}-vpc-spoke1"
  }
}

# Subnets
resource "aws_subnet" "spoke_vpc1-priv1" {
  vpc_id            = aws_vpc.spoke_vpc1.id
  cidr_block        = var.spoke_vpc1_private_subnet_cidr1
  availability_zone = var.availability_zone1

  tags = {
    Name = "${aws_vpc.spoke_vpc1.tags.Name}-priv1"
  }
}

resource "aws_subnet" "spoke_vpc1-priv2" {
  vpc_id            = aws_vpc.spoke_vpc1.id
  cidr_block        = var.spoke_vpc1_private_subnet_cidr2
  availability_zone = var.availability_zone2

  tags = {
    Name = "${aws_vpc.spoke_vpc1.tags.Name}-priv2"
  }
}

# Routes
resource "aws_route_table" "spoke1-rt" {
  vpc_id = aws_vpc.spoke_vpc1.id

  route {
    cidr_block         = "0.0.0.0/0"
    transit_gateway_id = aws_ec2_transit_gateway.TGW-XAZ.id
  }

  tags = {
    Name     = "spoke-vpc1-rt"
  }
  depends_on = [aws_ec2_transit_gateway.TGW-XAZ]
}

# Route tables associations
resource "aws_route_table_association" "spoke1_rt_association1" {
  subnet_id      = aws_subnet.spoke_vpc1-priv1.id
  route_table_id = aws_route_table.spoke1-rt.id
}

resource "aws_route_table_association" "spoke1_rt_association2" {
  subnet_id      = aws_subnet.spoke_vpc1-priv2.id
  route_table_id = aws_route_table.spoke1-rt.id
}

# Attachment to TGW
resource "aws_ec2_transit_gateway_vpc_attachment" "tgw-att-spoke-vpc1" {
  subnet_ids                                      = [aws_subnet.spoke_vpc1-priv1.id, aws_subnet.spoke_vpc1-priv2.id]
  transit_gateway_id                              = aws_ec2_transit_gateway.TGW-XAZ.id
  vpc_id                                          = aws_vpc.spoke_vpc1.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  tags = {
    Name     = "tgw-att-spoke-vpc1"
  }
  depends_on = [aws_ec2_transit_gateway.TGW-XAZ]
}

#############################################################################################################
# VPC SPOKE2
#############################################################################################################
resource "aws_vpc" "spoke_vpc2" {
  cidr_block = var.spoke_vpc2_cidr

  tags = {
    Name     = "${var.tag_name_prefix}-vpc-spoke2"
  }
}

# Subnets
resource "aws_subnet" "spoke_vpc2-priv1" {
  vpc_id            = aws_vpc.spoke_vpc2.id
  cidr_block        = var.spoke_vpc2_private_subnet_cidr1
  availability_zone = var.availability_zone1

  tags = {
    Name = "${aws_vpc.spoke_vpc2.tags.Name}-priv1"
  }
}

resource "aws_subnet" "spoke_vpc2-priv2" {
  vpc_id            = aws_vpc.spoke_vpc2.id
  cidr_block        = var.spoke_vpc2_private_subnet_cidr2
  availability_zone = var.availability_zone2

  tags = {
    Name = "${aws_vpc.spoke_vpc2.tags.Name}-priv2"
  }
}

# Routes
resource "aws_route_table" "spoke2-rt" {
  vpc_id = aws_vpc.spoke_vpc2.id

  route {
    cidr_block         = "0.0.0.0/0"
    transit_gateway_id = aws_ec2_transit_gateway.TGW-XAZ.id
  }

  tags = {
    Name     = "spoke-vpc2-rt"
  }
  depends_on = [aws_ec2_transit_gateway.TGW-XAZ]
}

# Route tables associations
resource "aws_route_table_association" "spoke2_rt_association1" {
  subnet_id      = aws_subnet.spoke_vpc2-priv1.id
  route_table_id = aws_route_table.spoke2-rt.id
}

resource "aws_route_table_association" "spoke2_rt_association2" {
  subnet_id      = aws_subnet.spoke_vpc2-priv2.id
  route_table_id = aws_route_table.spoke2-rt.id
}

# Attachment to TGW
resource "aws_ec2_transit_gateway_vpc_attachment" "tgw-att-spoke-vpc2" {
  subnet_ids                                      = [aws_subnet.spoke_vpc2-priv1.id, aws_subnet.spoke_vpc2-priv2.id]
  transit_gateway_id                              = aws_ec2_transit_gateway.TGW-XAZ.id
  vpc_id                                          = aws_vpc.spoke_vpc2.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  tags = {
    Name     = "tgw-att-spoke-vpc2"
  }
  depends_on = [aws_ec2_transit_gateway.TGW-XAZ]
}

#############################################################################################################
# VPC MGMT
#############################################################################################################
resource "aws_vpc" "spoke_mgmt" {
  cidr_block = var.mgmt_cidr

  tags = {
    Name     = "${var.tag_name_prefix}-vpc-mgmt"
  }
}

# IGW
resource "aws_internet_gateway" "igw_mgmt" {
  vpc_id = aws_vpc.spoke_mgmt.id
  tags = {
    Name = "${var.tag_name_prefix}-${var.tag_name_unique}-igw_mgmt"
  }
}

# Subnets
resource "aws_subnet" "spoke_mgmt-priv1" {
  vpc_id            = aws_vpc.spoke_mgmt.id
  cidr_block        = var.mgmt_private_subnet_cidr1
  availability_zone = var.availability_zone1

  tags = {
    Name = "${aws_vpc.spoke_mgmt.tags.Name}-priv1"
  }
}

resource "aws_subnet" "spoke_mgmt-priv2" {
  vpc_id            = aws_vpc.spoke_mgmt.id
  cidr_block        = var.mgmt_private_subnet_cidr2
  availability_zone = var.availability_zone2

  tags = {
    Name = "${aws_vpc.spoke_mgmt.tags.Name}-priv2"
  }
}

# Routes
resource "aws_route_table" "mgmt-rt" {
  vpc_id = aws_vpc.spoke_mgmt.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_mgmt.id
  }
  route {
    cidr_block         = var.spoke_vpc1_cidr
    transit_gateway_id = aws_ec2_transit_gateway.TGW-XAZ.id
  }
  route {
    cidr_block         = var.spoke_vpc2_cidr
    transit_gateway_id = aws_ec2_transit_gateway.TGW-XAZ.id
  }

  tags = {
    Name     = "mgmt-rt"
  }
  depends_on = [aws_ec2_transit_gateway.TGW-XAZ]
}

# Route tables associations
resource "aws_route_table_association" "mgmtvpc_rt_association1" {
  subnet_id      = aws_subnet.spoke_mgmt-priv1.id
  route_table_id = aws_route_table.mgmt-rt.id
}

resource "aws_route_table_association" "mgmtvpc_rt_association2" {
  subnet_id      = aws_subnet.spoke_mgmt-priv2.id
  route_table_id = aws_route_table.mgmt-rt.id
}

# Attachment to TGW
resource "aws_ec2_transit_gateway_vpc_attachment" "tgw-att-mgmt" {
  subnet_ids                                      = [aws_subnet.spoke_mgmt-priv1.id, aws_subnet.spoke_mgmt-priv2.id]
  transit_gateway_id                              = aws_ec2_transit_gateway.TGW-XAZ.id
  vpc_id                                          = aws_vpc.spoke_mgmt.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  tags = {
    Name     = "tgw-att-spoke-mgmt"
  }
  depends_on = [aws_ec2_transit_gateway.TGW-XAZ]
}



#############################################################################################################
# S3 Endpoint for yum updates for AWS Linux 2
#############################################################################################################


resource "aws_vpc_endpoint" "s3-endpoint-spoke1-vpc" {
  vpc_id          = aws_vpc.spoke_vpc1.id
  service_name    = "com.amazonaws.${var.region}.s3"
  route_table_ids = [aws_route_table.spoke1-rt.id]
      policy = <<POLICY
{
    "Statement": [
        {
            "Action": "*",
            "Effect": "Allow",
            "Resource": "*",
            "Principal": "*"
        }
    ]
}
POLICY
  tags = {
    Name     = "s3-endpoint-spoke1-vpc"
  }
}

resource "aws_vpc_endpoint" "s3-endpoint-spoke2-vpc" {
  vpc_id          = aws_vpc.spoke_vpc2.id
  service_name    = "com.amazonaws.${var.region}.s3"
  route_table_ids = [aws_route_table.spoke2-rt.id]
      policy = <<POLICY
{
    "Statement": [
        {
            "Action": "*",
            "Effect": "Allow",
            "Resource": "*",
            "Principal": "*"
        }
    ]
}
POLICY
  tags = {
    Name     = "s3-endpoint-spoke2-vpc"
  }
}