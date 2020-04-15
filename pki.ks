# configure installation settings
install

url --mirrorlist="https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-31&arch=x86_64"
repo --name=fedora-updates --mirrorlist="https://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f31&arch=x86_64" --cost=0

# Change me
user --name=pascal --password=thales --plaintext
network --device=wlp2s0 --bootproto=dhcp --essid=jakobi --wepkey=9876543210 --onboot=yes

lang en_US.UTF-8
xconfig --startxonboot

keyboard fr
timezone Europe/Paris
text
reboot
install 

# Clear the Master Boot Record
zerombr
# Partition clearing information
clearpart --all --initlabel
autopart --type=plain --fstype=ext4


firewall --disabled
selinux --disabled
# Change me
rootpw thales

#
# Change me
#
# configure system settings
#
auth --enableshadow --passalgo=sha512 --kickstart

%packages 
@core
@standard
@hardware-support
@base-x
#@firefox
#@fonts
#@libreoffice
#@multimedia
#@networkmanager-submodules
@printing
@mate-desktop
#@development-tools

#gdm
net-tools
bind-utils
wget
pciutils
deltarpm
yum-utils
mlocate

nmap
dogtag-pki
elinks
sshpass

389-ds-base
openldap-servers
openldap-clients

tomcat-admin-webapps
%end



%post
echo
echo " ============================================ "
echo "         Post install (chroot) - start "
echo " logs stored in /var/log/anaconda/program.log "
echo " ============================================ "

# Change me
USER=pascal
USERBASENAME=/home/${USER}/${USER}
PASSWD=thales
SUFFIX=dc=thales,dc=com
X509SUBJ=/C=FR/O=Thales/CN=${USER}/
KS_SERVER=10.0.1.3
BASE=/pub/ks/pki
DC=thales
DCCAP=`echo $DC | tr '[:lower:]' '[:upper:]'`
DSPASSWD=thales78

NSSDB=/etc/pki/pki-tomcat/alias
KEYBASE=/etc/pki/pki-tomcat/crypto
KEYFILE=${KEYBASE}/${DC}_root.key
CASGNKEY=${KEYBASE}/${DC}_ca.key
CERTF=${KEYBASE}/${DC}_root.crt
CAFILE=${KEYBASE}/${DC}_ca.crt
CACSR=${KEYBASE}/${DC}_ca_signing.csr
P12FILE=${KEYBASE}/${DC}_root.p12

### Set environment variables to their actual value
set_parms()
{
	sed -i "s/###PASSWD###/$PASSWD/g" $1
	sed -i "s/###DSPASSWD###/$DSPASSWD/g" $1
	sed -i "s/###SUFFIX###/$SUFFIX/g" $1
	sed -i "s/###DC###/$DC/g" $1
	sed -i "s/###DCCAP###/$DCCAP/g" $1
	sed -i "s:###CERTF###:$CERTF:g" $1
	sed -i "s:###CAFILE###:$CAFILE:g" $1
	sed -i "s:###P12FILE###:$P12FILE:g" $1
	sed -i "s:###KEYFILE###:$KEYFILE:g" $1
	sed -i "s:###CASGNKEY###:$CASGNKEY:g" $1
	sed -i "s:###CACSR###:$CACSR:g" $1
	sed -i "s:###KEYBASE###:$KEYBASE:g" $1
	sed -i "s:###NSSDB###:$NSSDB:g" $1
	sed -i "s:###USER###:$USER:g" $1
	sed -i "s:###USERBASENAME###:$USERBASENAME:g" $1
	sed -i "s:###X509SUBJ###:$X509SUBJ:g" $1
}

echo ""
echo "$USER  ALL=(root)      NOPASSWD: ALL" > /etc/sudoers.d/$USER
sed  -i '/PermitRootLogin/a PermitRootLogin=yes' /etc/ssh/sshd_config

# Disable IPv6
cat <<EOF >> /etc/sysctl.conf
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF

echo
echo "MATE"
echo "-----"
dnf -qy install gdm
systemctl disable lightdm
systemctl enable gdm
sed  -i '/\[daemon\]/a AutomaticLoginEnable=True' /etc/gdm/custom.conf
sed  -i '/\[daemon\]/a AutomaticLogin=pascal' /etc/gdm/custom.conf
gsettings set org.gnome.desktop.screensaver lock-enabled "false"

echo
echo "Openldap initialization"
echo "-----------------------"
echo "Building database $SUFFIX"
cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
wget -q -O /etc/openldap/$DC.conf http://$KS_SERVER/$BASE/slapd.conf
set_parms /etc/openldap/$DC.conf 
echo "slaptest $SUFFIX"
rm -fr /etc/openldap/slapd.d
mkdir /etc/openldap/slapd.d /var/lib/ldap/$DC
chown -R ldap: /etc/openldap/slapd.d /var/lib/ldap/$DC
slaptest -f /etc/openldap/$DC.conf -F /etc/openldap/slapd.d
chown -R ldap: /etc/openldap/slapd.d

echo "Starting openldap"
/usr/sbin/slapd -u ldap -h "ldap:/// ldaps:/// ldapi:///" -F /etc/openldap/slapd.d

echo "Openldap init load"
wget -q -O /etc/openldap/init.ldif http://$KS_SERVER/$BASE/init.ldif
set_parms /etc/openldap/init.ldif 
ldapadd -x -D cn=Manager,$SUFFIX -w $PASSWD -f /etc/openldap/init.ldif
systemctl enable slapd

echo
echo "openssl setup"
echo "-------------"
wget -q -O /root/$DC.cnf http://$KS_SERVER/$BASE/openssl.cnf
set_parms /root/$DC.cnf 
wget -q -O /root/client.cnf http://$KS_SERVER/$BASE/openssl.cnf
set_parms /root/client.cnf 

echo
echo "389ds initialization"
echo "--------------------"
wget -q -O /etc/dirsrv/config/$DC.inf http://$KS_SERVER/$BASE/389ds.inf
set_parms /etc/dirsrv/config/$DC.inf 

echo
echo "CA setup"
echo "--------"
wget -q -O /root/ca.inf http://$KS_SERVER/$BASE/ca.inf
set_parms /root/ca.inf 
wget -q -O /usr/sbin/dogtag_init.sh http://$KS_SERVER/$BASE/dogtag_init.sh
set_parms /usr/sbin/dogtag_init.sh 
chmod 700 /usr/sbin/dogtag_init.sh
systemctl enable pki-tomcatd@pki-tomcat.service

echo
echo "Dogtag init (runs at next boot as a service)"
echo "--------------------------------------------"
wget -q -O /etc/systemd/system/dogtag_init.service http://$KS_SERVER/$BASE/dogtag_init.service
set_parms /etc/systemd/system/dogtag_init.service
systemctl enable dogtag_init

echo
echo "OCSP setup"
echo "----------"
wget -q -O /root/ocsp.inf http://$KS_SERVER/$BASE/ocsp.inf
set_parms /root/ocsp.inf 

dnf -qy update
wget wget -q -O /root/keycloak-9.0.2.tar.gz http://$KS_SERVER/keycloak-9.0.2.tar.gz

echo 
echo " ================== "
echo " Post install - end "
echo " ================== "

%end
