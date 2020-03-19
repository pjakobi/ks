#!/bin/sh
pki -c ###PASSWD### client-init
pki pkcs12-cert-mod --pkcs12-file /etc/pki/CA/certs/###DC###_root.p12 "###DC### CA Certificate" --pkcs12-password ###PASSWD### --trust-flags "CTu,Cu,Cu"
sleep 10
echo "Spawn CA"
pkispawn -v -f /root/dogtag.inf -s CA
echo "Spawn OCSP"
pkispawn -v -f /root/ocsp.inf -s OCSP
sed -i '/^SECURITY_MANAGER=/s/true/false/' /etc/sysconfig/pki-tomcat /etc/pki/pki-tomcat/tomcat.conf
echo "Restart PKI"
systemctl restart pki-tomcatd@pki-tomcat.service
systemctl disable dogtag_init
