##############################################################################################################
# TRANSIT GATEWAY
##############################################################################################################
resource "aws_ec2_transit_gateway" "TGW-XAZ" {
  description                     = "Transit Gateway with 3 VPCs. 2 subnets in each."
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  vpn_ecmp_support = "enable"
  dns_support = "enable"
  amazon_side_asn = "64512"  
  tags = {
    Name     = var.tag_name_prefix
  }
}

# Route Tables
resource "aws_ec2_transit_gateway_route_table" "TGW-spoke-rt" {
  depends_on         = [aws_ec2_transit_gateway.TGW-XAZ]
  transit_gateway_id = aws_ec2_transit_gateway.TGW-XAZ.id
  tags = {
    Name     = "TGW-SPOKES-RT"
  }
}

resource "aws_ec2_transit_gateway_route_table" "TGW-VPC-SEC-rt" {
  depends_on         = [aws_ec2_transit_gateway.TGW-XAZ]
  transit_gateway_id = aws_ec2_transit_gateway.TGW-XAZ.id
  tags = {
    Name     = "TGW-VPC-SEC-RT"
  }
}

resource "aws_ec2_transit_gateway_route_table" "TGW-VPC-MGMT-rt" {
  depends_on         = [aws_ec2_transit_gateway.TGW-XAZ]
  transit_gateway_id = aws_ec2_transit_gateway.TGW-XAZ.id
  tags = {
    Name     = "TGW-VPC-MGMT-RT"
  }
}

# TGW routes
resource "aws_ec2_transit_gateway_route" "spokes_to-mgmt" {
  destination_cidr_block         = var.mgmt_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-att-mgmt.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.TGW-spoke-rt.id
}

# Route Tables Associations to VPC attachments
resource "aws_ec2_transit_gateway_route_table_association" "tgw-rt-vpc-spoke1-assoc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-att-spoke-vpc1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.TGW-spoke-rt.id
}

resource "aws_ec2_transit_gateway_route_table_association" "tgw-rt-vpc-spoke2-assoc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-att-spoke-vpc2.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.TGW-spoke-rt.id
}

resource "aws_ec2_transit_gateway_route_table_association" "tgw-rt-vpc_mgmt" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-att-mgmt.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.TGW-VPC-MGMT-rt.id
}

# Route Tables Propagations in VPC attachments
## This section defines which VPCs will be routed from each Route Table created in the Transit Gateway

resource "aws_ec2_transit_gateway_route_table_propagation" "tgw-rt-prp-vpc1" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-att-spoke-vpc1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.TGW-VPC-SEC-rt.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "tgw-rt-prp-vpc2" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-att-spoke-vpc2.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.TGW-VPC-SEC-rt.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "tgw-rt-prp-mgmt-tovpc1" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-att-spoke-vpc1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.TGW-VPC-MGMT-rt.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "tgw-rt-prp-mgmt-tovpc2" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-att-spoke-vpc2.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.TGW-VPC-MGMT-rt.id
}

#VPN attachements to the FortiGate firewalls association and propagation
data "aws_ec2_transit_gateway_vpn_attachment" "tgw-vpn-fgt1" {
  transit_gateway_id = aws_ec2_transit_gateway.TGW-XAZ.id
  vpn_connection_id  = aws_vpn_connection.tgw-vpn-fgt1.id 
}

data "aws_ec2_transit_gateway_vpn_attachment" "tgw-vpn-fgt2" {
  transit_gateway_id = aws_ec2_transit_gateway.TGW-XAZ.id
  vpn_connection_id  = aws_vpn_connection.tgw-vpn-fgt2.id 
}

resource "aws_ec2_transit_gateway_route_table_association" "tgw-rt-sec-fgt1-assoc" {
  transit_gateway_attachment_id  = data.aws_ec2_transit_gateway_vpn_attachment.tgw-vpn-fgt1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.TGW-VPC-SEC-rt.id
}

resource "aws_ec2_transit_gateway_route_table_association" "tgw-rt-sec-fgt2-assoc" {
  transit_gateway_attachment_id  = data.aws_ec2_transit_gateway_vpn_attachment.tgw-vpn-fgt2.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.TGW-VPC-SEC-rt.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "tgw-rt-prp-fgt1" {
  transit_gateway_attachment_id  = data.aws_ec2_transit_gateway_vpn_attachment.tgw-vpn-fgt1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.TGW-spoke-rt.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "tgw-rt-prp-fgt2" {
  transit_gateway_attachment_id  = data.aws_ec2_transit_gateway_vpn_attachment.tgw-vpn-fgt2.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.TGW-spoke-rt.id
}
