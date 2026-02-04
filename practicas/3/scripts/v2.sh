su -

mkdir -p /etc/vbox
echo "* 10.0.0.0/8 192.168.0.0/16" | sudo tee /etc/vbox/networks.conf
systemctl reload vboxdrv
systemctl restart vboxdrv
VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.25.1 --netmask 255.255.255.0