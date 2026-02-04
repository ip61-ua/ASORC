#!/bin/bash

pkg update
pkg install -y xfce xfce4-goodies xf86-input-mouse xorg emulators/virtualbox-ose-additions nano lightdm lightdm-gtk-greeter slim slim-themes firefox tigervnc-server samba416 xrdp cups cups-pdf cups-filters isc-dhcp44-server bind918 bind-tools git mariadb1011-server php83-mbstring php83-intl php83-gd php83-zip php83-bz2 php83-pdo php83-pdo_mysql php83-fileinfo php83-exif php83-sodium php83-sysvsem php83-bcmath php83-gmp php83-posix php83-dom php83-zlib php83-xml php83-xmlreader php83-xmlwriter php83-simplexml php83-opcache php83-pecl-imagick php83-curl php83-soap php83-pecl-redis php83-pecl-json_post php83-pecl-APCu php83-composer redis unzip sudo postgresql17-server apache24 openldap26-server phpldapadmin-php85 avahi print/gutenprint print/ghostscript10 php83-pgsql php83-mysqli php83-pear php83-session php83-enchant php83-ftp php83-tokenizer hunspell wget

echo 'hostname="bsd.asorc.org"
keymap="es.kbd"
ifconfig_em0="DHCP"
ifconfig_em1="inet 192.168.25.11 netmask 255.255.255.0"
sshd_enable="YES"
ntpd_enable="YES"
ntpd_sync_on_start="YES"
dumpdev="NO"
vboxguest_enable="YES"
vboxservice_enable="YES"
dbus_enable="YES"
hald_enable="YES"
slim_enable="YES"' > /etc/rc.conf

echo '# Device        Mountpoint      FStype  Options Dump    Pass#
/dev/ada0s1a    /               ufs     rw      1       1
/dev/ada0s1d    /var            ufs     rw      2       2
/dev/ada0s1b    none            swap    sw      0       0
proc            /proc           procfs  rw      0       0' > /etc/fstab

echo 'exec startxfce4' > /home/ivan/.xinitrc
echo 'exec startxfce4' > /root/.xinitrc

echo 'default_path        /sbin:/bin:/usr/sbin:/usr/bin:/usr/games:/usr/local/sbin:/usr/local/bin
default_xserver     /usr/local/bin/X
xserver_arguments   -nolisten tcp vt09
halt_cmd            /sbin/shutdown -p now
reboot_cmd          /sbin/shutdown -r now
console_cmd         /usr/local/bin/xterm -C -fg white -bg black +sb -T "Console login" -e /bin/sh -c "/bin/cat /etc/motd; exec /usr/bin/login"
suspend_cmd        /usr/sbin/acpiconf -s 3
xauth_path         /usr/local/bin/xauth
authfile           /var/run/slim.auth
login_cmd           exec /bin/sh -l -c "exec startxfce4"
sessiondir              /usr/local/share/xsessions
screenshot_cmd      import -window root /slim.png
welcome_msg         Welcome to %host
shutdown_msg       The system is powering down...
reboot_msg         The system is rebooting...
current_theme       default
lockfile            /var/run/slim.pid
logfile             /var/log/slim.log' > /usr/local/etc/slim.conf

echo '#
#       This file is required by the ISC DHCP client.
#       See ``man 5 dhclient.conf'' for details.
#
#       In most cases an empty file is sufficient for most people as the
#       defaults are usually fine.
#
interface "em0" {
        prepend domain-name-servers 1.1.1.1, 8.8.8.8;
}' > /etc/dhclient.conf

echo '::1                     localhost localhost.my.domain
127.0.0.1               localhost localhost.my.domain nextbsd.org dbbsd.org web1bsd.org web2bsd.org bsd.bsd.asorc.org bsd.asorc.org' > /etc/hosts

reboot