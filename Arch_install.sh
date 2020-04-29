#!/bin/bash
#======================================================================================
# Author  : Frank  at 2020-04-29
# for : VM install arch linux 
# Hard Disk	20GB
# RAM         	1GB
#======================================================================================


print_line() {
	printf "%$(tput cols)s\n"|tr ' ' '-'
}

print_title() {
	clear
	print_line
	echo -e "# ${Bold}$1${Reset}"
	print_line
	echo ""
}
arch_chroot() {
	arch-chroot /mnt /bin/bash -c "${1}"
}

#替換mirrorlist
update_mirrorlist(){
	print_title "update_mirrorlist"
	tmpfile=$(mktemp --suffix=-mirrorlist)	
	url="https://www.archlinux.org/mirrorlist/?country=CN&protocol=http&protocol=https&ip_version=4"
	curl -so ${tmpfile} ${url} 
	sed -i 's/^#Server/Server/g' ${tmpfile}
	mv -f ${tmpfile} /etc/pacman.d/mirrorlist;
        #pacman -Syy --noconfirm
}
#磁碟分區 MSDOS 執行前須check
create_partitions(){
	print_title "create_partitions"
	parted -s /dev/sda mklabel msdos
	parted -s /dev/sda mkpart primary ext4 1M 525M
	parted -s /dev/sda mkpart primary linux-swap 525M 4800M
	parted -s /dev/sda mkpart primary ext4 4800M 100%
	parted -s /dev/sda set 1 boot on
	parted -s /dev/sda print
}
#磁區格式化
format_partitions(){
	print_title "format_partitions"
	mkfs.vfat -F32 /dev/sda1 
	mkswap /dev/sda2 
	mkfs.ext4 /dev/sda3 
}
#掛載分區
mount_partitions(){
	print_title "mount_partitions"
	mount /dev/sda3 /mnt
	swapon /dev/sda2
        mkdir /mnt/boot
	mount /dev/sda1 /mnt/boot
	lsblk
}
#基礎安裝
install_baseSystem(){
	print_title "install_baseSystem"
        pacstrap /mnt base base-devel linux-lts linux-lts-headers linux-firmware wqy-zenhei ttf-dejavu wqy-microhei adobe-source-code-pro-fonts   
}

#產生開機掛載fstab
generate_fstab(){
	print_title "generate_fstab"
	genfstab -U /mnt >> /mnt/etc/fstab
}

#設定系統參數 時間
configure_system(){
	print_title "configure_system"
	arch_chroot "ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime"
	arch_chroot "hwclock --systohc --utc"
	arch_chroot "mkinitcpio -p linux"
	echo "en_US.UTF-8 UTF-8" >> /mnt/etc/locale.gen
	echo "zh_CN.UTF-8 UTF-8" >> /mnt/etc/locale.gen
	arch_chroot "locale-gen"
	echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
}

#安裝驅動 
configrue_drive(){
	print_title "configrue_drive"
        arch_chroot "pacman -S --noconfirm xorg-server xorg-twm xorg-xclock xorg-server -y"
	arch_chroot "pacman -S --noconfirm bumblebee -y"
        arch_chroot "systemctl enable bumblebeed"
        arch_chroot "pacman -S --noconfirm nvidia-dkms nvidia-utils nvidia-settings xf86-input-synaptics -y"        
        arch_chroot "intel-ucode -y"
        # arch_chroot "amd-ucode -y"
}

#安裝網路相關套件
configrue_networkmanager(){
       print_title "configrue_networkmanager"
       arch_chroot "pacman -S --noconfirm iw wireless_tools wpa_supplicant dialog netctl networkmanager networkmanager-openconnect rp-pppoe network-manager-applet net-tools -y"
       arch_chroot "systemctl enable NetworkManager.service"      
}

#安裝開機引導（如為efi須將grub改為grub-efi-x86_64 efibootmgr）
configrue_bootloader(){
       print_title "configrue_bootloader"
       arch_chroot "pacman -S --noconfirm grub -y"
       arch_chroot "grub-install --target=i386-pc /dev/sda"
       #arch_chroot "grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=boot" (efi引导)
       arch_chroot "grub-mkconfig -o /boot/grub/grub.cfg" 
}


#更新本機域名
configure_hostname(){
	print_title "configure_hostname"
	read -p "Hostname [ex: archlinux]: " host_name
	echo "$host_name" > /mnt/etc/hostname
	if [[ ! -f /mnt/etc/hosts.aui ]]; then
	cp /mnt/etc/hosts /mnt/etc/hosts.aui
	else
	cp /mnt/etc/hosts.aui /mnt/etc/hosts
	fi
	arch_chroot "sed -i '/127.0.0.1/s/$/ '${host_name}'/' /etc/hosts"
	arch_chroot "sed -i '/::1/s/$/ '${host_name}'/' /etc/hosts"
	arch_chroot "passwd"
  }
  
#更新使用者名稱與密碼
configure_username(){
        print_title "configure_username"
        read -p "Username [ex: archlinux]: " User
        arch_chroot "pacman -S --noconfirm sudo zsh -y"
        arch_chroot "useradd -m -g users -G wheel -s /bin/zsh $User"
        arch_chroot "passwd $User"
        arch_chroot "sed -i 's/\# \%wheel ALL=(ALL) ALL/\%wheel ALL=(ALL) ALL/g' /etc/sudoers"
	arch_chroot "sed -i 's/\# \%wheel ALL=(ALL) NOPASSWD: ALL/\%wheel ALL=(ALL) NOPASSWD: ALL/g' /etc/sudoers"
        umount -R /mnt
	clear
	print_title "install has been.please reboot ."
}



update_mirrorlist
create_partitions
format_partitions
mount_partitions
install_baseSystem
generate_fstab
configure_system
#  configrue_drive
configrue_networkmanager
configrue_bootloader
configure_hostname
configure_username