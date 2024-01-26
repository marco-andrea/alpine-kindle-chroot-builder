#!/bin/sh
MNT_PATH="/tmp/alpine"

create_mountpoint() {
  mkdir -p $MNT_PATH
}
mount_fs() {
  mount -o loop,noatime /mnt/us/alpine-chroot/alpine.ext3 $MNT_PATH
}

mount_kindle_system() {
  mount -o mode=1777,nosuid,nodev -t tmpfs tmp $MNT_PATH/tmp
  #mount -o mode=0755,nosuid,nodev -t tmpfs run $MNT_PATH/run

  mount -o bind $MNT_PATH/tmp $MNT_PATH/var/cache
  mount -o bind $MNT_PATH/tmp $MNT_PATH/var/log
  mount -o bind $MNT_PATH/tmp $MNT_PATH/run

  mount -o bind /proc $MNT_PATH/proc
  mount -o bind /sys $MNT_PATH/sys
  mount -o bind /dev $MNT_PATH/dev
  mount -o bind /dev/pts $MNT_PATH/dev/pts
}

setup_resolv() {
  cp -f /etc/resolv.conf $MNT_PATH/etc/resolv.conf
  cp -f /etc/network/interfaces	$MNT_PATH/etc/network/interfaces
}

unmount_kindle_system() {
  umount $MNT_PATH/sys/kernel/debug/tracing
  umount $MNT_PATH/sys/kernel/debug
  umount $MNT_PATH/sys/kernel/config
  umount $MNT_PATH/sys/fs/fuse/connections
  umount $MNT_PATH/sys/fs/selinux
  umount $MNT_PATH/sys/fs/pstore
  umount $MNT_PATH/dev/shm
  
  umount $MNT_PATH/dev/pts/ 
  umount $MNT_PATH/dev 
  umount $MNT_PATH/sys 
  umount $MNT_PATH/proc

  umount $MNT_PATH/tmp
}

unmount_alpine_mount() {
  LOOPDEV="$(mount | grep loop | grep $MNT_PATH | cut -d" " -f1)"
  umount $MNT_PATH
  losetup -d $LOOPDEV
}

_mount() {
  create_mountpoint
  mount_fs
  mount_kindle_system
  setup_resolv
}

_unmount() {
  kill -9 $(lsof -t +D $MNT_PATH)
  unmount_kindle_system
  unmount_alpine_mount
}

case $1 in
  start)
    _mount
    ;;
  stop)
    _unmount
    ;;
  enter)
    chroot $MNT_PATH /bin/ash
    ;;
  *)
    exit 1
    ;;
esac
