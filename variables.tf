##############################################################################################################
#
# FortiGate Terraform deployment
# Active Passive High Availability MultiAZ with AWS Transit Gateway with VPC standard attachment -
#
##############################################################################################################

# Access and secret keys to your environment
variable "access_key" {}
variable "secret_key" {}

# Prefix for all resources created for this deployment in AWS
variable "tag_name_prefix" {
  description = "Common tag prefix value that will be used in the name tag for all resources"
  default     = "TGW"
}

variable "tag_name_unique" {
  description = "Unique tag prefix value that will be used in the name tag for each modules resources"
  default     = "terraform"
}


#
# References of your environment
variable "region" {
  description = "Region to deploy the entire template in"
  default     = "ca-central-1"
}

variable "availability_zone1" {
  description = "First availability zone to create the subnets in"
  default     = "ca-central-1a"
}

variable "availability_zone2" {
  description = "Second availability zone to create the subnets in"
  default     = "ca-central-1b"
}


# 
# Security VPC
variable "security_vpc_cidr" {
  description = "Network CIDR for the VPC"
  default     = "10.0.0.0/16"
}

variable "security_vpc_public_subnet_cidr1" {
  description = "Network CIDR for the Public Subnet1 in security vpc"
  default     = "10.0.1.0/24"
}

variable "security_vpc_public_subnet_cidr2" {
  description = "Network CIDR for the Public Subnet1 in security vpc"
  default     = "10.0.10.0/24"
}

variable "security_vpc_private_subnet_cidr1" {
  description = "Network CIDR for the Private Subnet1 in security vpc"
  default     = "10.0.2.0/24"
}

variable "security_vpc_private_subnet_cidr2" {
  description = "Network CIDR for the Private Subnet2 in security vpc"
  default     = "10.0.20.0/24"
}



#
# spoke1 VPC
variable "spoke_vpc1_cidr" {
  description = "Network CIDR for the VPC"
  default     = "10.1.0.0/16"
}

variable "spoke_vpc1_private_subnet_cidr1" {
  description = "Network CIDR for the private subnet1 in spoke vpc1"
  default     = "10.1.1.0/24"
}

variable "spoke_vpc1_private_subnet_cidr2" {
  description = "Network CIDR for the private subnet2 in spoke vpc1"
  default     = "10.1.10.0/24"
}


#
# spoke2 VPC
variable "spoke_vpc2_cidr" {
  description = "Network CIDR for the VPC"
  default     = "10.2.0.0/16"
}

variable "spoke_vpc2_private_subnet_cidr1" {
  description = "Network CIDR for the private subnet1 in spoke vpc2"
  default     = "10.2.1.0/24"
}

variable "spoke_vpc2_private_subnet_cidr2" {
  description = "Network CIDR for the private subnet2 in spoke vpc2"
  default     = "10.2.10.0/24"
}


#
# Mgmt VPC
variable "mgmt_cidr" {
  description = "Network CIDR for the Mgmt VPC"
  default     = "10.3.0.0/16"
}

variable "mgmt_private_subnet_cidr1" {
  description = "Network CIDR for the mgmt subnet1 in spoke mgmt"
  default     = "10.3.1.0/24"
}

variable "mgmt_private_subnet_cidr2" {
  description = "Network CIDR for the mgmt subnet2 in spoke mgmt"
  default     = "10.3.10.0/24"
}


#
# FortiGate Firewalls

variable "fgt_instance_type" {
  description = "Instance type for the FortiGate instances"
  default     = "c5n.xlarge"
}

variable "keypair" {
  description = "SSH keypair for accessing the FortiGate instances"
  default     = ""
}

variable "cidr_for_access" {
  description = "Network CIDR for accessing the FortiGate instances"
  default     = "0.0.0.0/0"
}

variable "fgt_license_type" {
  description = "license type for FortiGate-VM Instances, either byol or payg"
  default     = "byol"
}

variable "fgt1_license_file" {
  description = "License file for FortiGate1 if using BYOL"
  type    = string
  default = ""
}

variable "fgt2_license_file" {
  description = "License file for FortiGate2 if using BYOL"
  type    = string
  default = ""
}

variable "fgt_admin_password" {
  description = "Password for admin for FortiGate firewalls"
  default = ""
}

variable "cgw_bgp_asn" {
  description = "BGP Autonomous System Number for the FortiGate"
  default = "64513"
}



#
# FortiWeb Web Application Firewalls
variable "fwb_instance_type" {
  description = "Instance type for the Fortiweb instances"
  default     = "c5.large"
}

variable "fwb1_license_file" {
  description = "License file for FortiWeb1 if using BYOL"
  type    = string
  default = ""
}

variable "fwb2_license_file" {
  description = "License file for FortiWeb2 if using BYOL"
  type    = string
  default = ""
}

variable "s3_bucket_fwb_tmp" {
  description = "Temporary S3 bucket for FortiWeb bootstrap, randomly created name if variable is empty"
  default     = ""
}

variable "fwb_license_type" {
  description = "License type for FortiWeb Instances, either byol or payg"
  default     = "byol"
}