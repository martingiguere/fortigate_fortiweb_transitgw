config system global
  set dst enable
  set admin-port 8008
  set admin-sport 8443
  set admintimeout 60
  set admin-lockout-duration 300
  set timezone 12
  set pre-login-banner enable
  set hostname ${fwb_vm_name}
end
config system dns
  set primary ${dns_server}
end
config log disk
    set severity notification
end
config log traffic-log
  set status enable
end
config system interface
  edit "port1"
    set type physical
    set allowaccess ssh http https 
    set mode dhcp
  next
end
config waf signature
  edit "POC_Signatures"
    config  main_class_list
      edit "010000000"
        set fpm-status disable
        set action alert_deny
        set severity High
      next
      edit "020000000"
        set fpm-status disable
      next
      edit "030000000"
        set action alert_deny
        set severity High
      next
      edit "040000000"
      next
      edit "050000000"
        set fpm-status disable
        set action alert_deny
        set severity High
      next
      edit "060000000"
        set fpm-status disable
      next
      edit "070000000"
        set fpm-status disable
      next
      edit "080000000"
        set fpm-status disable
        set severity Low
      next
      edit "090000000"
        set fpm-status disable
        set action alert_deny
        set severity High
      next
      edit "100000000"
        set fpm-status disable
        set severity High
      next
    end
    config  signature_disable_list
      edit "060030001"
      next
      edit "060120001"
      next
      edit "080080005"
      next
      edit "080200001"
      next
      edit "080080003"
      next
      edit "090410001"
      next
      edit "090410002"
      next
      edit "040000141"
      next
      edit "040000136"
      next
      edit "060180001"
      next
      edit "060180002"
      next
      edit "060180003"
      next
      edit "060180004"
      next
      edit "060180005"
      next
      edit "060180006"
      next
      edit "060180007"
      next
      edit "060180008"
      next
      edit "010000072"
      next
      edit "010000092"
      next
      edit "010000093"
      next
      edit "010000214"
      next
      edit "030000182"
      next
      edit "030000195"
      next
      edit "030000204"
      next
      edit "050140001"
      next
      edit "050140003"
      next
      edit "050140004"
      next
      edit "050220001"
      next
      edit "080200004"
      next
      edit "080200005"
      next
      edit "080210001"
      next
      edit "080210002"
      next
      edit "080210003"
      next
      edit "080210004"
      next
      edit "080210005"
      next
      edit "090240001"
      next
      edit "050180003"
      next
      edit "080110001"
      next
      edit "080140012"
      next
      edit "080050001"
      next
      edit "080150006"
      next
      edit "080150003"
      next
      edit "080150002"
      next
      edit "080150008"
      next
      edit "080150014"
      next
      edit "080150004"
      next
      edit "080150005"
      next
      edit "080150032"
      next
      edit "080150029"
      next
      edit "080150009"
      next
      edit "080120002"
      next
      edit "080150020"
      next
      edit "080150031"
      next
      edit "080140015"
      next
      edit "080120001"
      next
      edit "050070002"
      next
      edit "050160002"
      next
      edit "010000108"
      next
      edit "080110003"
      next
    end
    config  alert_only_list
    end
    config  fpm_disable_list
    end
    config  scoring_override_disable_list
    end
    config  score_grade_list
    end
    config  filter_list
    end
  next
end
config waf x-forwarded-for
  edit "POC_X-FWD"
    set x-forwarded-for-support enable
    set tracing-original-ip enable
    set original-ip-header X-FORWARDED-FOR
    config  ip-list
    end
  next
end
config waf web-protection-profile inline-protection
  edit "POC"
    set signature-rule POC_Signatures
    set x-forwarded-for-rule POC_X-FWD
    set file-upload-policy WebShell-Uploading
    set redirect-url http://
    set custom-access-policy "Predefined - Advanced Protection"
    set ip-intelligence enable
    set profile-id 8553341939751044907
    set bot-mitigate-policy "Predefined - Bot Mitigation"
  next
end

config server-policy vserver
  edit 'Virtual_Server_Linux_Spoke1'
    config  vip-list
      edit 1
        set interface port1
        set use-interface-ip enable
      next
    end
  next
end
config server-policy server-pool
  edit 'Server_Pool_Linux_Spoke1'
    set flag 1
    config  pserver-list
      edit 1
        set server-type domain
        set domain ${linux_spoke1_private_dns}
      next
    end
  next
  edit 'Server_Pool_Linux_Spoke2'
    set flag 1
    config  pserver-list
      edit 1
        set ip ${linux_spoke2_private_ip}
      next
    end
  next
end
config server-policy http-content-routing-policy
  edit 'HTTP_Content_Routing_Policy1'
    set server-pool Server_Pool_Linux_Spoke1
    config  content-routing-match-list
      edit 1
        set match-condition equal      
        set match-expression ${fwb_alb1_dns_name}
      next
    end
  next
  edit 'HTTP_Content_Routing_Policy2'
    set server-pool Server_Pool_Linux_Spoke2
    config  content-routing-match-list
      edit 1
        set match-condition equal
        set match-expression ${fwb_alb1_public_ip_0}
       set concatenate or        
      next
      edit 2
        set match-condition equal
        set match-expression ${fwb_alb1_public_ip_1}
       set concatenate or        
      next
    end

  next
end

config server-policy policy
  edit "Server_Policy1"
    set deployment-mode http-content-routing
    set ssl enable
    set vserver Virtual_Server_Linux_Spoke1
    set service HTTP
    set web-protection-profile POC
    set replacemsg Predefined
    set ssl-custom-cipher ECDHE-ECDSA-AES256-GCM-SHA384 ECDHE-RSA-AES256-GCM-SHA384 ECDHE-ECDSA-CHACHA20-POLY1305 ECDHE-RSA-CHACHA20-POLY1305 ECDHE-ECDSA-AES128-GCM-SHA256 ECDHE-RSA-AES128-GCM-SHA256 ECDHE-ECDSA-AES256-SHA384 ECDHE-RSA-AES256-SHA384 ECDHE-ECDSA-AES128-SHA256 ECDHE-RSA-AES128-SHA256 ECDHE-ECDSA-AES256-SHA ECDHE-RSA-AES256-SHA ECDHE-ECDSA-AES128-SHA ECDHE-RSA-AES128-SHA AES256-GCM-SHA384 AES128-GCM-SHA256 AES256-SHA256 AES128-SHA256 
    config  http-content-routing-list
      edit 1
        set content-routing-policy-name HTTP_Content_Routing_Policy1
        set profile-inherit enable
      next
      edit 2
        set content-routing-policy-name HTTP_Content_Routing_Policy2
        set profile-inherit enable
      next
    end
  next
end

#config system ha
#set mode active-active-high-volume
#set group-id 1
#set override enable
#set priority ${fwb_ha_priority}
#set group-name FWBAAGroup
#set network-type udp-tunnel
#set tunnel-local '${fwb_public_ip}'
#set tunnel-peer '${fwb_ha_peer_ip}'
#set monitor port1
#end
