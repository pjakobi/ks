#!/bin/sh
echo "Spawn"
pkispawn -f /root/dogtag.inf -s CA
mkdir ###KEYBASE###
echo ###PASSWD### > /root/passwd.txt

# Root certificate
openssl genrsa -out ###KEYFILE### 2048
openssl req -new -x509 -key ###KEYFILE### -out ###CERTF### -config /root/###DC###.cnf -days 365 -set_serial 1
openssl pkcs12 -export -in ###CERTF### -inkey ###KEYFILE### -out ###P12FILE### -name "external" -passout pass:###PASSWD###
pk12util -d ###NSSDB### -i ###P12FILE### -W ###PASSWD### -K ###PASSWD###
certutil -d ###NSSDB### -M -n "external" -t "CT,C,C" -f /root/passwd.txt

# (subordinate) CA signing certificate
openssl req -newkey rsa:2048 -nodes -keyout ###CASGNKEY### -new -subj "/C=FR/O=###DC###/CN=CA Signing Certificate/" -out ###CACSR### -config /root/###DC###.cnf -days 365 -set_serial 2
openssl x509 -req -in ###CACSR### -CA  ###CERTF### -CAkey ###KEYFILE### -CAcreateserial -out ###KEYBASE###/###DC###_ca_signing.crt
openssl pkcs12 -export -in ###KEYBASE###/###DC###_ca_signing.crt -inkey ###CASGNKEY### -out ###KEYBASE###/###DC###_ca_signing.p12 -name "ca_signing" -passout pass:###PASSWD###
pk12util -d ###NSSDB### -i ###KEYBASE###/###DC###_ca_signing.p12 -W ###PASSWD### -K ###PASSWD###
certutil -d ###NSSDB### -M -n "ca_signing" -t "CTu,Cu,Cu" -f /root/passwd.txt

# Finish CA installation
rm -f /root/passwd.txt
sed -i '/pki_external_step_two/s/=.*$/=True/' /root/dogtag.inf
sed -i 's/###STEP2###//g' /root/dogtag.inf
pkispawn -f /root/dogtag.inf -s CA

pkispawn -v -f /root/ocsp.inf -s OCSP
sed -i '/^SECURITY_MANAGER=/s/true/false/' /etc/sysconfig/pki-tomcat /etc/pki/pki-tomcat/tomcat.conf
systemctl enable pki-tomcatd@pki-tomcat.service
systemctl restart pki-tomcatd@pki-tomcat.service
systemctl disable dogtag_init
