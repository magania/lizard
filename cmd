wget http://distfiles.gentoo.org/releases/amd64/autobuilds/latest-stage3-amd64-hardened+nomultilib.txt
wget http://distfiles.gentoo.org/releases/amd64/autobuilds/`tail -n1 latest-stage3*.txt`
wget http://mirror.mcs.anl.gov/pub/gentoo/snapshots/portage-latest.tar.bz2
mkdir lizard
cd lizard/
tar xjf ../stage3*.tar.bz2
cd usr/
tar xjf ../../portage-latest.tar.bz2
cd ../..

cp config/make.conf lizard/etc/make.conf
mkdir lizard/etc/portage/
cp config/package.keywords lizard/etc/portage/
cp config/package.use lizard/etc/portage/


mount -t proc none lizard/proc
mount -o bind /dev lizard/dev
cp /etc/resolv.conf lizard/etc/resolv.conf
chroot lizard
#
source /etc/profile
env-update 


cp /usr/share/zoneinfo/America/Mexico_City /etc/localtime
echo "127.0.0.1 tetera localhost" > /etc/hosts
sed -i -e 's/HOSTNAME.*/HOSTNAME="tetera"/' /etc/conf.d/hostname

emerge -av genkernel gentoo-sources iwl6000-ucode wireless-tools dhcpcd xf86-video-intel xorg-drivers xorg-server lxde-meta x11-apps/setxkbmap app-editors/vim #chromium

paperconfig -p letter
echo XSESSION="lxde" > /etc/env.d/90xsession
echo "EDITOR=vim" > /etc/env.d/99editor
echo "LANG=en_US.utf8" > /etc/env.d/02locale
#change in /etc/rc.conf   unicode=yes

#    kernel
genkernel --splash --menuconfig all
# Device dirvers
#   Graphics support
#     * Intel 830M, 845G ...
#     * Enable modesetting on Intel

# set root password
passwd

emerge --unmerge nano gentoo-sources 
#rm -r /usr/src/linux-*
#rm -r /var/cache/genkernel
#rm -r /var/tmp/genkernel
#rm -r /usr/share/doc
#rm -r /usr/portage/distfiles
#rm -r /usr/portage

exit
umount lizard/dev
umount lizard/proc



# --- extlinux
mkfs.ext3 -L gentoo /dev/sdb1
dd if=/usr/share/syslinux/mbr.bin of=/dev/sdb bs=512 count=1
mount /dev/sdb1 /mnt/gentoo
extlinux --install /mnt/gentoo
cp config/syslinux.cfg /mnt/gentoo

mv lizard/boot/kernel* /mnt/gentoo/kernel
mv lizard/boot/System.map* /mnt/gentoo/System.map
mv lizard/boot/initramfs* initramfs.gz    

gunzip initramfs.gz 
mkdir init
cd init
cpio -i < ../initramfs 
cp ../config/init_lizard init 

find .  | cpio -H newc -o > /tmp/init.cpio
cat /tmp/init.cpio | gzip  > /mnt/gentoo/initramfs
rm /tmp/init.cpio
cd ..

rm lizard/usr/portage/distfiles/*
mv lizard/usr/src/linux-3.1.6-gentoo/ .

cd lizard
tar czf /mnt/gentoo/lizard.tgz *
umount /mnt/gentoo

