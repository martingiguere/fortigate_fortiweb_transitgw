Content-Type: multipart/mixed; boundary="==AWS=="
MIME-Version: 1.0

--==AWS==
Content-Type: text/x-shellscript; charset="us-ascii"
MIME-Version: 1.0

config system global
set hostname ${fgt_id}
end
config system admin
edit admin
set password ${admin_password}
end
config system settings
set gui-multiple-interface-policy enable
end
config system vdom-exception
edit 1
set object system.interface
next
edit 2
set object router.static
next
edit 3
set object firewall.vip
next
edit 4
set object firewall.ippool
next
edit 5
set object router.bgp
next
edit 6
set object router.route-map
next
edit 7
set object router.prefix-list
next
edit 8
set object vpn.ipsec.phase1-interface
next
edit 9
set object vpn.ipsec.phase2-interface
next
end
end
config system probe-response
set http-probe-value OK
set mode http-probe
end
config vpn ipsec phase1-interface
edit "tgw-vpn1"
set interface "port1"
set local-gw ${fgt_public_ip}
set keylife 28800
set peertype any
set proposal aes128-sha1
set dhgrp 2
set remote-gw ${t1_ip}
set psksecret ${t1_psk}
set dpd-retryinterval 10
next
edit "tgw-vpn2"
set interface "port1"
set local-gw ${fgt_public_ip}
set keylife 28800
set peertype any
set proposal aes128-sha1
set dhgrp 2
set remote-gw ${t2_ip}
set psksecret ${t2_psk}
set dpd-retryinterval 10
next
end
config vpn ipsec phase2-interface
edit "tgw-vpn1"
set phase1name "tgw-vpn1"
set proposal aes128-sha1
set dhgrp 2
set auto-negotiate enable
set keylifeseconds 3600
next
edit "tgw-vpn2"
set phase1name "tgw-vpn2"
set proposal aes128-sha1
set dhgrp 2
set auto-negotiate enable
set keylifeseconds 3600
next
end
config system interface
edit "tgw-vpn1"
set description ${t1_id}
set ip ${t1_lip} 255.255.255.255
set remote-ip ${t1_rip} 255.255.255.255
next
edit "tgw-vpn2"
set description ${t2_id}
set ip ${t2_lip} 255.255.255.255
set remote-ip ${t2_rip} 255.255.255.255
next
end
config system interface
edit port1
set alias PUBLIC
set mode static
set ip ${fgt_public_ip_w_cidr}
set allowaccess ping https ssh probe-response
set mtu-override enable
set mtu 9001
next
edit port2
set alias PRIVATE
set mode static
set ip ${fgt_private_ip}
set allowaccess ping
set mtu-override enable
set mtu 9001
next
end
config system auto-scale
set status enable
set sync-interface "port2"
%{ if fgt_id == "FGT1" }set role master%{ else }set master-ip ${fgt_peer_private_ip}%{ endif }
end
config firewall ippool
edit "cluster-ippool"
set startip ${fgt_public_ip}
set endip ${fgt_public_ip}
next
end
config router static
edit 1
    set device port1
    set gateway ${public_gw}
next
edit 2
    set dst ${security_vpc_cidr}
    set device port2
    set gateway ${private_gw}
next
edit 3
  set dst ${spoke1_cidr}
  set distance 5
  set device "tgw-vpn1"
next
edit 4
  set dst ${spoke1_cidr}
  set device "tgw-vpn2"
next
edit 5
  set dst ${spoke2_cidr}
  set distance 5
  set device "tgw-vpn1"
next
edit 6
  set dst ${spoke2_cidr}
  set device "tgw-vpn2"
next
edit 7
  set dst ${mgmt_cidr}
  set distance 5
  set device "tgw-vpn1"
next
edit 8
  set dst ${mgmt_cidr}
  set device "tgw-vpn2"
next
end
config firewall vip
edit "Linux_Spoke1"
set extip ${fgt_public_ip}
set mappedip "${linux_spoke1_ip}"
set extintf "port1"
set portforward enable
set extport 7021
set mappedport 22
next
end
config firewall policy
edit 1
  set name "to-Internet-from-Security-VPC"
  set srcintf "port2"
  set dstintf "port1"
  set srcaddr "all"
  set dstaddr "all"
  set action accept
  set schedule "always"
  set service "ALL"
  set logtraffic all
  set ippool enable
  set poolname "cluster-ippool"      
  set nat enable
  set logtraffic-start enable
next
edit 2
  set name "to-Internet-from-TGW"
  set srcintf "tgw-vpn1" "tgw-vpn2"
  set dstintf "port1"
  set srcaddr "all"
  set dstaddr "all"
  set action accept
  set schedule "always"
  set service "ALL"
  set logtraffic all
  set ippool enable
  set poolname "cluster-ippool"
  set nat enable
  set logtraffic-start enable
next
edit 3
  set name "to-Security-VPC-from-TGW"
  set srcintf "tgw-vpn1" "tgw-vpn2"
  set dstintf "port2"
  set srcaddr "all"
  set dstaddr "all"
  set action accept
  set schedule "always"
  set service "ALL"
  set logtraffic all
  set logtraffic-start enable
next
edit 4
  set name "to-TGW-from-Security-VPC"
  set srcintf "port2"
  set dstintf "tgw-vpn1" "tgw-vpn2"
  set srcaddr "all"
  set dstaddr "all"
  set action accept
  set schedule "always"
  set service "ALL"
  set logtraffic all
  set logtraffic-start enable
  set ippool enable
  set poolname "cluster-ippool"
  set nat enable  
next
edit 5
    set name "SSH-to-Linux-Spoke-1"
    set srcintf "port1"
    set dstintf "tgw-vpn1" "tgw-vpn2"
    set srcaddr "all"
    set dstaddr "Linux_Spoke1"
    set action accept
    set schedule "always"
    set service "SSH"
    set logtraffic all
    set ippool enable
    set poolname "cluster-ippool"
    set nat enable
next
end
config router access-list
  edit "TGW-DenyAllInbound"
      config rule
          edit 1
              set action deny
              set prefix 0.0.0.0 0.0.0.0
          next
      end
  next
end
config router prefix-list
  edit "pflist-default-route"
  config rule
    edit 1
      set prefix 0.0.0.0 0.0.0.0
      unset ge
      unset le
    next
  end
  next
  edit "pflist-port1-ip"
  config rule
    edit 1
      set prefix ${fgt_public_ip} 255.255.255.255
      unset ge
      unset le
    next
  end
  next
end
config router route-map
edit "rmap-outbound"
config rule
edit 1
  set match-ip-address "pflist-default-route"
  set set-local-preference 200
next
edit 2
  set match-ip-address "pflist-port1-ip"
  set set-local-preference 200
next
end
next
edit "rmap-outbound-prepend"
config rule
edit 1
  set match-ip-address "pflist-default-route"
  set set-aspath "${fgt_bgp_asn} ${fgt_bgp_asn} ${fgt_bgp_asn}"
  set set-local-preference 100
next
edit 2
  set match-ip-address "pflist-port1-ip"
  set set-aspath "${fgt_bgp_asn} ${fgt_bgp_asn} ${fgt_bgp_asn}"
  set set-local-preference 100
next
end
next
edit "RMAP-IN-DENY-ALL"
    config rule
        edit 1
            set match-ip-address "TGW-DenyAllInbound"
        next
    end
next
end
config router bgp
set as ${fgt_bgp_asn}
set router-id ${fgt_public_eip}
set ebgp-multipath enable
set network-import-check disable
config neighbor
edit ${t1_rip}
set capability-default-originate enable
set default-originate-routemap "rmap-outbound"
set remote-as ${tgw_bgp_asn}
set route-map-in "RMAP-IN-DENY-ALL"
set route-map-out "rmap-outbound"
set link-down-failover enable
next
edit ${t2_rip}
set capability-default-originate enable
set default-originate-routemap "rmap-outbound-prepend"    
set remote-as ${tgw_bgp_asn}
set route-map-in "RMAP-IN-DENY-ALL"
set route-map-out "rmap-outbound-prepend"
set link-down-failover enable
next
end
config network
  edit 1
    set prefix ${fgt_public_ip} 255.255.255.255
  next
end  
end

%{ if type == "byol" }
--==AWS==
Content-Type: text/plain; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="license"

${file(license_file)}

%{ endif }
--==AWS==--
