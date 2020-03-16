#!/bin/sh
sed '/^SECURITY_MANAGER=/s/true/false/' /etc/sysconfig/pki-tomcat /etc/pki/pki-tomcat/tomcat.conf
pki -c ###PASSWD### client-init
pki pkcs12-cert-mod --pkcs12-file /etc/pki/CA/certs/###DC###_root.p12 "###DC### CA Certificate" --pkcs12-password-file /root/password.txt --trust-flags "CTu,Cu,Cu"
sleep 10
pkispawn -v -f /root/dogtag.inf -s CA
