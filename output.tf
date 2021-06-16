# Output
output "FGT1_Public_EIP" {
  value       = aws_eip.eip-public1.public_ip
  description = "Public IP address for FortiGate1's Port1 (Public) interface"
}

output "FGT1_Admin_URL" {
  value       = "https://${aws_eip.eip-public1.public_ip}"
  description = "Admin URL for FortiGate1"
}

output "FGT1_Password" {
  value       = var.fgt_admin_password
  description = "Initial Password for FortiGate1"
}

output "FGT2_Public_EIP" {
  value       = aws_eip.eip-public2.public_ip
  description = "Public IP address for FortiGate2's Port1 (Public) interface"
}

output "FGT2_Admin_URL" {
  value       = "https://${aws_eip.eip-public2.public_ip}"
  description = "Admin URL for FortiGate1"
}

output "FGT2_Password" {
  value       = var.fgt_admin_password
  description = "Initial Password for FortiGate2"
}

output "FGT_Username" {
  value       = "admin"
  description = "Default Username for FortiGate Firewalls"
}

output "FWB1_Admin_URL" {
  value       = "https://${aws_eip.fwb1-eip20-public1.public_ip}:8443"
  description = "Admin URL for FortiWeb1"
}

output "FWB1_Password" {
  value       = aws_instance.fwb1-instance.id
  description = "Initial Password for FortiWeb1"
}

output "FWB2_Admin_URL" {
  value       = "https://${aws_eip.fwb2-eip20-public2.public_ip}:8443"
  description = "Admin URL for FortiWeb2"
}

output "FWB2_Password" {
  value       = aws_instance.fwb2-instance.id
  description = "Initial Password for FortiWeb2"
}


output "TransitGwy_ID" {
  value       = aws_ec2_transit_gateway.TGW-XAZ.id
  description = "Transit Gateway ID"
}

output "Linux_MGMT_Public_EIP" {
  value       = aws_instance.instance-mgmt.public_ip
  description = "Linux MGMT Instance Public IP"
}

output "Linux_MGMT_Private_IP" {
  value       = aws_instance.instance-mgmt.private_ip
  description = "Linux MGMT Instance Private IP"
}

output "Linux_Spoke1_Private_IP" {
  value       = aws_instance.instance-spoke1.private_ip
  description = "Linux Spoke1 Instance Private IP"
}

output "Linux_Spoke1_Public_EIP_and_Port-through_NLB-Public1" {
  value       = "${aws_eip.eip-fgt1-nlb-public1.public_ip}:${aws_lb_target_group.fgt-nlb-target-group.port}"
  description = "Linux Spoke1 Public EIP and Port-through NLB on Public1 Subnet"
}

output "Linux_Spoke1_Public_EIP_and_Port-through_NLB-Public2" {
  value       = "${aws_eip.eip-fgt2-nlb-public2.public_ip}:${aws_lb_target_group.fgt-nlb-target-group.port}"
  description = "Linux Spoke1 Public EIP and Port-through NLB on Public2 Subnet"
}

output "Linux_Spoke2_Private_IP" {
  value       = aws_instance.instance-spoke2.private_ip
  description = "Linux Spoke1 Instance Private IP"
}

output "AWS_Application_Load_Balancer_1_DNS_Name" {
  value       = aws_lb.fwb-alb1.dns_name
  description = "AWS Application Load Balancer 1 DNS Name"
}



output "AWS_Application_Load_Balancer_1_Public_IPs" {
  value = join(",", data.dns_a_record_set.fwb-alb1-public-ip.addrs)
  description = "AWS Application Load Balancer 1 Public IPs"
}


/*
output "aws_s3_bucket_name" {
  value       = "${aws_s3_bucket.s3_bucket_fwb_tmp.id}"
  description = "Temporary S3 bucket for FortiWeb bootstrap"
}
*/

