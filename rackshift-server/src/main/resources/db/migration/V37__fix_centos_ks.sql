update template set content = '# Copyright 2016-2018, DELL EMC, Inc.\ninstall\n#text\ngraphical\nunsupported_hardware\nurl --url=<%=repo%>\n# eula --agreed\nlang en_US.UTF-8\nkeyboard ''us''\ntimezone America/Los_Angeles --isUtc\nfirewall --enabled --http --ssh\nselinux --permissive\n<% if (version === \"6.5\") \{ %>\n  bootloader --location=mbr --driveorder=<%=installDisk%> --append=\"crashkernel=auth rhgb\"\n<% \} else \{ %>\n  bootloader --location=mbr --driveorder=<%=installDisk%> --boot-drive=<%=installDisk%> --append=\"crashkernel=auth rhgb\"\n<% \} %>\nservices --enabled=NetworkManager,sshd\n#network --device=<%=macaddress%> --noipv6 --activate\n\n# enable syslog\n<% if (typeof remoteLogging !== \'undefined\' && remoteLogging) \{ %>\n  logging --host=<%=server%> --level=info\n<% \} %>\n\nauthconfig --enableshadow --passalgo=sha512 --enablefingerprint\n\n#Set the root account\nrootpw --iscrypted <%-rootEncryptedPassword%>\n\n#create all users\n<% if (typeof users !== \'undefined\') \{ %>\n<% users.forEach(function(user) \{ %>\n<%_  if( typeof user.uid !== \'undefined\' ) \{ _%>\n        user --name=<%=user.name%> --uid=<%=user.uid%> --iscrypted --password <%-user.encryptedPassword%>\n<%_  \} else \{ _%>\n        user --name=<%=user.name%>  --iscrypted --password <%-user.encryptedPassword%>\n<%_ \}\}) _%>\n<% \} %>\n\n# Disk Partitioning\nzerombr\nclearpart --all --drives=<%=installDisk%>\n\n<% exist = false;%>\n\n<% if (typeof installPartitions !== \'undefined\' && installPartitions.length > 0) \{ %>\n    <% installPartitions.forEach(function(partition) \{ %>\n     <% if(partition.deviceType === ''lvm'')\{ %>\n    <% exist = true;%>\n    <%\}%>\n    <%\})%>\n<%\}%>\n\n<% if (exist) \{%>\n # Create an LVM partition on sda\n                    part pv.01 --size=1 --ondisk=sda --grow --asprimary\n                    volgroup rootvg --pesize=4096 pv.01\n<%\}%>\n\n\n<% if (typeof installPartitions !== \'undefined\' && installPartitions.length > 0) \{ %>\n    <% installPartitions.forEach(function(partition) \{ %>\n        # mountPoint and size is required\n        <% if(partition.mountPoint !== undefined && partition.size !== undefined) \{ %>\n            \n            # lvm support\n            <% if(partition.deviceType === ''standard'' || partition.deviceType === undefined)\{ %>\n\n              <% if(partition.fsType !== undefined) \{ %>\n                <% if(partition.size === ''auto'') \{ %>\n                    partition <%=partition.mountPoint%> --size=250 --grow --fstype=<%=partition.fsType%>\n                <% \} else \{ %>\n                    partition <%=partition.mountPoint%> --size=<%=partition.size%> --fstype=<%=partition.fsType%>\n                <% \} %>\n                <% \} else \{ %>\n                # fsType is optional\n                <% if(partition.size === ''auto'') \{ %>\n                    partition <%=partition.mountPoint%> --size=250 --grow\n                <% \} else \{ %>\n                    partition <%=partition.mountPoint%> --size=<%=partition.size%>\n                <% \} %>\n              <% \} %>\n\n            <% \} else \{%>\n                    # Create an LVM partition on sda\n                    #part pv.01 --size=1 --ondisk=sda --grow --asprimary\n                    #volgroup rootvg --pesize=4096 pv.01\n\n               <% if(partition.fsType !== undefined) \{ %>\n                <% if(partition.size === ''auto'') \{ %>\n                    logvol <%=partition.mountPoint%> --size=250 --grow --fstype=<%=partition.fsType%> --vgname=\"rootvg\" --name=<%=partition.lvmName%> \n                <% \} else \{ %>\n                    logvol <%=partition.mountPoint%> --size=<%=partition.size%> --fstype=<%=partition.fsType%> --vgname=\"rootvg\" --name=<%=partition.lvmName%> \n                <% \} %>\n                <% \} else \{ %>\n                # fsType is optional\n                <% if(partition.size === ''auto'') \{ %>\n                    logvol <%=partition.mountPoint%> --size=250 --grow --vgname=\"rootvg\" --name=<%=partition.lvmName%> \n                <% \} else \{ %>\n                    logvol <%=partition.mountPoint%> --size=<%=partition.size%> --vgname=\"rootvg\" --name=<%=partition.lvmName%>\n                <% \} %>\n              <% \} %>\n            \n            <% \} %>\n\n\n        <% \} %>\n    <% \}) %>\n<% \} else \{ %>\n    # auto partitioning if no partitions are specified\n    autopart\n<% \} %>\n\n# END of Disk Partitioning\n\n# Make sure we reboot into the new system when we are finished\nreboot\n\n# Package Selection\n%packages --nobase --excludedocs\n@core\n-*firmware\n-iscsi*\n-fcoe*\n-b43-openfwwf\nkernel-firmware\nwget\nsudo\nperl\nlibselinux-python\nnet-tools\n\n<% if( typeof kvm !== \'undefined\' && kvm ) \{ %>\n    <% if (version === \"6.5\") \{ %>\n        kvm\n        virt-manager\n        libvirt\n        libvirt-python\n        python-virtinst\n    <% \} else \{ %>\n        @virtualization-hypervisor\n        @virtualization-client\n        @virtualization-platform\n        @virtualization-tools\n    <% \} %>\n<% \} %>\n\n<% if (typeof packages !== \'undefined\') \{ %>\n<%   for (var i = 0, len = packages.length; i < len; i++) \{ %>\n<%= packages[i] %>\n<%   \} %>\n<% \} %>\n%end\n\n%pre\n# The progress notification is just something nice-to-have, so progress notification failure should\n# never impact the normal installation process\n<% if( typeof progressMilestones !== \'undefined\' && progressMilestones.preConfigUri ) \{ %>\n    # the url may contain query, the symbol ''&'' will mess the command line logic, so the whole url need be wrapped in quotation marks\n    /usr/bin/curl -X POST -H ''Content-Type:application/json'' \"http://<%=server%>:<%=port%><%-progressMilestones.preConfigUri%>\" || true\n<% \} %>\n\n%end\n\n%post --log=/root/install-post.log\n(\n#notify the current progress\n<% if( typeof progressMilestones !== \'undefined\' && progressMilestones.postConfigUri ) \{ %>\n    echo \"RackHD POST script started - curl notify post progress\"\n    # the url may contain query, the symbol ''&'' will mess the command line logic, so the whole url need be wrapped in quotation marks\n    /usr/bin/curl -X POST -H ''Content-Type:application/json'' \"http://<%=server%>:<%=port%><%-progressMilestones.postConfigUri%>\" || true\n    echo \"RackHD POST script started - curl notify post progress after\"\n<% \} %>\n\n# PLACE YOUR POST DIRECTIVES HERE\nPATH=/bin:/sbin:/usr/bin:/usr/sbin\nexport PATH\n\n# copying of SSH key\n<% if (typeof rootSshKey !== \'undefined\') \{ %>\n    mkdir /root/.ssh\n    echo <%=rootSshKey%> > /root/.ssh/authorized_keys\n    chown -R root:root /root/.ssh\n<% \} %>\n<% if (typeof users !== \'undefined\') \{ %>\n<% users.forEach(function(user) \{ %>\n    <% if (typeof user.sshKey !== \'undefined\') \{ %>\n        mkdir /home/<%=user.name%>/.ssh\n        echo <%=user.sshKey%> > /home/<%=user.name%>/.ssh/authorized_keys\n        chown -R <%=user.name%>:<%=user.name%> /home/<%=user.name%>/.ssh\n    <% \} %>\n<% \}) %>\n<% \} %>\n\n#set hostname\n<% if (typeof hostname !== \'undefined\') \{ %>\n    echo <%=hostname%> > /etc/hostname\n    <% if (typeof domain !== \'undefined\') \{ %>\n        echo -e \"NETWORKING=yes\\nHOSTNAME=<%=hostname%>.<%=domain%>\" > /etc/sysconfig/network\n    <% \} %>\n<% \} %>\n\n# Setup BOND Configuration\n<% if (typeof bonds !== \'undefined\') \{ %> \n\n<% bonds.forEach(function(n) \{ %>\n     echo \"Configuring bond <%=n.name%>\"\n     <% var bondname = n.name %>\n     echo DEVICE=<%=bondname%> > /etc/sysconfig/network-scripts/ifcfg-<%=n.name%>\n     echo NAME=<%=bondname%> >> /etc/sysconfig/network-scripts/ifcfg-<%=n.name%>\n     echo TYPE=bond  >> /etc/sysconfig/network-scripts/ifcfg-<%=n.name%>\n     echo BONDING_MASTER=yes >> /etc/sysconfig/network-scripts/ifcfg-<%=n.name%>\n     echo BONDING_OPTS=\"mode=802.3ad miimon=10 lacp_rate=1\"  >> /etc/sysconfig/network-scripts/ifcfg-<%=n.name%>\n     echo USERCTL=no >> /etc/sysconfig/network-scripts/ifcfg-<%=n.name%>\n     echo NM_CONTROLLED=no >> /etc/sysconfig/network-scripts/ifcfg-<%=n.name%>\n     echo BOOTPROTO=none >> /etc/sysconfig/network-scripts/ifcfg-<%=n.name%>\n     echo ONBOOT=yes >> /etc/sysconfig/network-scripts/ifcfg-<%=n.name%>\n     <% if ( typeof n.ipv4 != \'undefined\' ) \{ %>\n          echo IPADDR=\"<%=n.ipv4.ipAddr%>\" >> /etc/sysconfig/network-scripts/ifcfg-<%=n.name%>\n          echo NETMASK=\"<%=n.ipv4.netmask%>\" >> /etc/sysconfig/network-scripts/ifcfg-<%=n.name%>\n          <% if ( undefined != n.ipv4.gateway) \{ %>\n               echo GATEWAY=\"<%=n.ipv4.gateway%>\" >> /etc/sysconfig/network-scripts/ifcfg-<%=n.name%>\n          <% \} %>\n          echo DEFROUTE=yes >> /etc/sysconfig/network-scripts/ifcfg-<%=n.name%>\n          echo PEERDNS=yes >> /etc/sysconfig/network-scripts/ifcfg-<%=n.name%>\n     <% \} %>\n\n     echo IPV4_FAILURE_FATAL=\"no\" >> /etc/sysconfig/network-scripts/ifcfg-<%=n.name%>\n     echo IPV6INIT=\"no\" >> /etc/sysconfig/network-scripts/ifcfg-<%=n.name%>\n     <% if (typeof n.nics !== \'undefined\') \{ %>\n      <%   for (var i = 0, len = n.nics.length; i < len; i++) \{ %>\n        interface=`grep -i /sys/class/net/*/address -e  <%=n.nics[i]%> | cut -d \"/\" -f 5`\n        echo DEVICE=$interface > /etc/sysconfig/network-scripts/ifcfg-$interface\n        echo NAME=<%=bondname%>-slave >> /etc/sysconfig/network-scripts/ifcfg-$interface\n        echo MASTER=<%=bondname%> >> /etc/sysconfig/network-scripts/ifcfg-$interface\n        echo TYPE=Ethernet >> /etc/sysconfig/network-scripts/ifcfg-$interface\n        echo BOOTPROTO=none >> /etc/sysconfig/network-scripts/ifcfg-$interface\n        echo ONBOOT=yes >> /etc/sysconfig/network-scripts/ifcfg-$interface\n        echo NM_CONTROLLED=no >> /etc/sysconfig/network-scripts/ifcfg-$interface\n        echo SLAVE=yes >> /etc/sysconfig/network-scripts/ifcfg-$interface\n      <%   \} %>\n      <% \} %>\n\n      # Bonded VLAN Interface\n      <% if ( typeof n.bondvlaninterfaces != \'undefined\' ) \{ %>\n         <%   for (var i = 0, len = n.bondvlaninterfaces.length; i < len; i++) \{ %>\n         echo DEVICE=<%=n.name%>.<%=n.bondvlaninterfaces[i].vlanid%>  > /etc/sysconfig/network-scripts/ifcfg-<%=n.name%>.<%=n.bondvlaninterfaces[i].vlanid%>\n         echo NAME=<%=n.name%>.<%=n.bondvlaninterfaces[i].vlanid%> >> /etc/sysconfig/network-scripts/ifcfg-<%=n.name%>.<%=n.bondvlaninterfaces[i].vlanid%>\n         echo BOOTPROTO=none >> /etc/sysconfig/network-scripts/ifcfg-<%=n.name%>.<%=n.bondvlaninterfaces[i].vlanid%>\n         echo ONPARENT=yes >> /etc/sysconfig/network-scripts/ifcfg-<%=n.name%>.<%=n.bondvlaninterfaces[i].vlanid%>\n         echo IPADDR=<%=n.bondvlaninterfaces[i].ipv4.ipAddr%> >> /etc/sysconfig/network-scripts/ifcfg-<%=n.name%>.<%=n.bondvlaninterfaces[i].vlanid%>\n         echo NETMASK=<%=n.bondvlaninterfaces[i].ipv4.netmask%> >> /etc/sysconfig/network-scripts/ifcfg-<%=n.name%>.<%=n.bondvlaninterfaces[i].vlanid%>\n         <% if ( undefined != n.bondvlaninterfaces[i].ipv4.gateway) \{ %>\n            echo GATEWAY=<%=n.bondvlaninterfaces[i].ipv4.gateway%> >> /etc/sysconfig/network-scripts/ifcfg-<%=n.name%>.<%=n.bondvlaninterfaces[i].vlanid%>\n         <% \} %>\n         echo VLAN=yes >> /etc/sysconfig/network-scripts/ifcfg-<%=n.name%>.<%=n.bondvlaninterfaces[i].vlanid%>\n         echo NM_CONTROLLED=no >> /etc/sysconfig/network-scripts/ifcfg-<%=n.name%>.<%=n.bondvlaninterfaces[i].vlanid%>\n         <%   \} %>\n       <% \} %>\n  <%\}) %>\n  \n  systemctl stop NetworkManager\n  systemctl disable NetworkManager\n  modprobe --first-time bonding\n  systemctl restart network\n<%\} %>\n\n# Setup static network configuration\n<%_ var macRegex = /(..:*)\{6\}/i; _%>\n<% if (typeof networkDevices !== \'undefined\') \{ %>\n  <% ipv6 = 0 %>\n  <% networkDevices.forEach(function(n) \{ %>\n    interface=<%=n.device%>\n    <%_ if (n.device.search(macRegex) === 0)\{ _%>\n      interface=`grep -i /sys/class/net/*/address -e  $interface | cut -d \"/\" -f 5`\n    <%_ \} _%>\n    <% if( undefined != n.ipv4 ) \{ %>\n      <% if( undefined != n.ipv4.vlanIds && n.ipv4.vlanIds.length > 0 ) \{ %>\n        <% n.ipv4.vlanIds.forEach(function(vid) \{ %>\n          echo \"Configuring vlan <%=vid%> on $interface\"\n          sed -i ''/^BOOTPROTO=/d'' /etc/sysconfig/network-scripts/ifcfg-$interface.<%=vid%>\n          sed -i ''/^ONBOOT=/d'' /etc/sysconfig/network-scripts/ifcfg-$interface.<%=vid%>\n          echo \"DEVICE=$interface.<%=vid%>\" >> /etc/sysconfig/network-scripts/ifcfg-$interface.<%=vid%>\n          echo \"BOOTPROTO=none\" >> /etc/sysconfig/network-scripts/ifcfg-$interface.<%=vid%>\n          echo \"ONBOOT=yes\" >> /etc/sysconfig/network-scripts/ifcfg-$interface.<%=vid%>\n          echo \"IPADDR=<%=n.ipv4.ipAddr%>\" >> /etc/sysconfig/network-scripts/ifcfg-$interface.<%=vid%>\n          echo \"NETMASK=<%=n.ipv4.netmask%>\" >> /etc/sysconfig/network-scripts/ifcfg-$interface.<%=vid%>\n          echo \"GATEWAY=<%=n.ipv4.gateway%>\" >> /etc/sysconfig/network-scripts/ifcfg-$interface.<%=vid%>\n          echo \"VLAN=yes\" >> /etc/sysconfig/network-scripts/ifcfg-$interface.<%=vid%>\n\n          sed -i ''/^ONBOOT=/d'' /etc/sysconfig/network-scripts/ifcfg-$interface\n          echo \"ONBOOT=no\" >> /etc/sysconfig/network-scripts/ifcfg-$interface\n        <% \}); %>\n      <% \} else \{ %>\n        echo \"Configuring device $interface\"\n        sed -i ''/^BOOTPROTO=/d'' /etc/sysconfig/network-scripts/ifcfg-$interface\n        sed -i ''/^ONBOOT=/d'' /etc/sysconfig/network-scripts/ifcfg-$interface\n        echo \"DEVICE=$interface\" >> /etc/sysconfig/network-scripts/ifcfg-$interface\n        <%_ if (n.device.search(macRegex) === 0)\{ _%>\n            echo \"HWADDR=<%=n.device%>\" >> /etc/sysconfig/network-scripts/ifcfg-$interface\n        <%_ \} _%>\n        echo \"BOOTPROTO=none\" >> /etc/sysconfig/network-scripts/ifcfg-$interface\n        echo \"ONBOOT=yes\" >> /etc/sysconfig/network-scripts/ifcfg-$interface\n        echo \"IPADDR=<%=n.ipv4.ipAddr%>\" >> /etc/sysconfig/network-scripts/ifcfg-$interface\n        echo \"NETMASK=<%=n.ipv4.netmask%>\" >> /etc/sysconfig/network-scripts/ifcfg-$interface\n        <% if ( undefined != n.ipv4.gateway) \{ %>\n          echo \"GATEWAY=<%=n.ipv4.gateway%>\" >> /etc/sysconfig/network-scripts/ifcfg-$interface\n        <% \} %>\n        <% if ( undefined != n.ipv4.mtu) \{ %>\n          echo \"MTU=<%=n.ipv4.mtu%>\" >> /etc/sysconfig/network-scripts/ifcfg-$interface\n        <% \} %>\n\n      <% \} %>\n    <% \} %>\n    <% if( undefined != n.ipv6 ) \{ %>\n      <% if( undefined != n.ipv6.vlanIds ) \{ %>\n        <% n.ipv6.vlanIds.forEach(function(vid) \{ %>\n          echo \"Configuring vlan <%=vid%> on $interface\"\n          sed -i ''/^BOOTPROTO=/d'' /etc/sysconfig/network-scripts/ifcfg-$interface.<%=vid%>\n          sed -i ''/^ONBOOT=/d'' /etc/sysconfig/network-scripts/ifcfg-$interface.<%=vid%>\n          echo \"DEVICE=$interface.<%=vid%>\" >> /etc/sysconfig/network-scripts/ifcfg-$interface.<%=vid%>\n          echo \"BOOTPROTO=none\" >> /etc/sysconfig/network-scripts/ifcfg-$interface.<%=vid%>\n          echo \"ONBOOT=yes\" >> /etc/sysconfig/network-scripts/ifcfg-$interface.<%=vid%>\n          echo \"IPV6INIT=yes\" >> /etc/sysconfig/network-scripts/ifcfg-$interface.<%=vid%>\n          echo \"IPV6ADDR=<%=n.ipv6.ipAddr%>/<%=n.ipv6.prefixlen%>\" >> /etc/sysconfig/network-scripts/ifcfg-$interface.<%=vid%>\n          echo \"IPV6_DEFAULTGW=<%=n.ipv6.gateway%>/<%=n.ipv6.prefixlen%>\" >> /etc/sysconfig/network-scripts/ifcfg-$interface.<%=vid%>\n          echo \"VLAN=yes\" >> /etc/sysconfig/network-scripts/ifcfg-$interface.<%=vid%>\n          <% ipv6 = 1 %>\n        <% \}); %>\n      <% \} else \{ %>\n        echo \"Configuring device $interface\"\n        sed -i ''/^BOOTPROTO=/d'' /etc/sysconfig/network-scripts/ifcfg-$interface\n        sed -i ''/^ONBOOT=/d'' /etc/sysconfig/network-scripts/ifcfg-$interface\n        echo \"DEVICE=$interface\" >> /etc/sysconfig/network-scripts/ifcfg-$interface\n        echo \"BOOTPROTO=none\" >> /etc/sysconfig/network-scripts/ifcfg-$interface\n        echo \"ONBOOT=yes\" >> /etc/sysconfig/network-scripts/ifcfg-$interface\n        echo \"IPV6INIT=yes\" >> /etc/sysconfig/network-scripts/ifcfg-$interface\n        echo \"IPV6ADDR=<%=n.ipv6.ipAddr%>/<%=n.ipv6.prefixlen%>\" >> /etc/sysconfig/network-scripts/ifcfg-$interface\n        echo \"IPV6_DEFAULTGW=<%=n.ipv6.gateway%>/<%=n.ipv6.prefixlen%>\" >> /etc/sysconfig/network-scripts/ifcfg-$interface\n        <% ipv6 = 1 %>\n      <% \} %>\n    <% \} %>\n  <% \}); %>\n  <% if( ipv6 ) \{ %>\n    grep -q -F ''NETWORKING_IPV6=yes'' /etc/sysconfig/network || echo \"NETWORKING_IPV6=yes\" >> /etc/sysconfig/network\n    grep -q -F ''IPV6_AUTOCONF=no'' /etc/sysconfig/network || echo \"IPV6_AUTOCONF=no\" >> /etc/sysconfig/network\n  <% \} %>\n<% \} %>\n\n# Setup DNS servers\n<% if (typeof dnsServers !== \'undefined\') \{ %>\n  <% if (typeof domain !== \'undefined\') \{ %>\n    echo \"search <%=domain%>\" > /etc/resolv.conf\n  <% \} %>\n  <% dnsServers.forEach(function(dns) \{ %>\n    echo \"nameserver <%=dns%>\" >> /etc/resolv.conf\n  <% \}) %>\n  chattr +i /etc/resolv.conf\n<% \} %>\n\n# Download the service to callback to RackHD after OS installation/reboot completion\necho \"RackHD POST script wget started\"\n/usr/bin/wget http://<%=server%>:<%=port%>/api/current/templates/<%=rackhdCallbackScript%>?nodeId=<%=nodeId%> -O /etc/rc.d/init.d/<%=rackhdCallbackScript%>\necho \"RackHD POST script chmod callback script\"\nchmod +x /etc/rc.d/init.d/<%=rackhdCallbackScript%>\n# Enable the above service, it should auto-disable after running once\nchkconfig <%=rackhdCallbackScript%> on\necho \"RackHD POST script chkconfig callback script complete\"\n\n# Enable Services\n<% if (typeof enableServices !== \'undefined\') \{ %>\n<%   for (var i = 0, len = enableServices.length; i < len; i++) \{ %>\nsystemctl enable <%=enableServices[i]%>\n<%   \} %>\n<% \} %>\n\n# Disable Services\n<% if (typeof disableServices !== \'undefined\') \{ %>\n<%   for (var i = 0, len = disableServices.length; i < len; i++) \{ %>\nsystemctl disable <%=disableServices[i]%>\n<%   \} %>\n<% \} %>\n\n#signify ORA the installation completed\nfor retry in $(seq 1 5);\ndo\n    /usr/bin/curl -X POST -H ''Content-Type:application/json'' http://<%=server%>:<%=port%>/api/current/notification?nodeId=<%=nodeId%>\n    if [ $? -eq 0 ]; then\n        echo \"Post Notification succeeded\"\n        break\n    else\n        echo \"Post Notification failed\"\n        sleep 1\n    fi\ndone;\n\n) 2>&1 >>/root/install-post-sh.log\nEOF\n%end\n\n# RackShift Custom Post-InstallScript\n%post --log=/root/rackshift-post-install.log\n<% if( typeof postInstallCommands !== \'undefined\' ) \{ %>\n  <% postInstallCommands.forEach(function(n) \{ %>\n    <%-n%>\n  <% \}); %>\n<% \} %>\t\n%end\n' where name = 'centos-ks';