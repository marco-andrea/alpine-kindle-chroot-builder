#!/bin/sh
MNT_PATH="/tmp/alpine"

kindle_services(){
  action="$1"
  services="statusbar framework cmd webreader otaupd otav3 ttsorchestrator lab126_gui x todo btmanagerd acsbtfd playermgr appmgrd dpmd rcm demd printklogs syslog iohwlogs playermgr_limit wifis wifid"

  # reverse services order when starting
  if [ "$action" = "start" ]; then
    services=$(echo $services | tr ' ' '\n' | tac | tr '\n' ' ')
  fi

  for service in $services; do
    initctl "$action" "$service" 2>&1
  done
}

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
  #mount -o bind /dev $MNT_PATH/dev
  
  mount -n -t devtmpfs dev $MNT_PATH/dev # to make udev happy
  mkdir -p $MNT_PATH/dev/pts  
  
  mount -o bind /dev/pts $MNT_PATH/dev/pts
}

setup_resolv() {
  cp -f /etc/resolv.conf $MNT_PATH/etc/resolv.conf
  # cp -f /etc/network/interfaces	$MNT_PATH/etc/network/interfaces
}

unmount_kindle_system() {
  umount $MNT_PATH/sys/fs/pstore
  sleep 1
  umount $MNT_PATH/sys/fs/selinux
  sleep 1
  umount $MNT_PATH/sys/fs/fuse/connections
  sleep 1
  umount $MNT_PATH/sys/kernel/config
  sleep 1
  umount $MNT_PATH/sys/kernel/debug/tracing
  sleep 1
  umount $MNT_PATH/sys/kernel/debug
  sleep 1
  umount $MNT_PATH/dev/shm
  sleep 1

  umount $MNT_PATH/dev/pts
  sleep 1
  umount $MNT_PATH/dev
  sleep 1
  umount $MNT_PATH/sys
  sleep 1
  umount $MNT_PATH/proc
  sleep 1

  umount $MNT_PATH/run
  sleep 1
  umount $MNT_PATH/var/log
  sleep 1
  umount $MNT_PATH/var/cache
  sleep 1

  umount $MNT_PATH/tmp
  sleep 1
  sync
}

unmount_alpine_mount() {
  LOOPDEV="$(mount | grep loop | grep $MNT_PATH | cut -d" " -f1)"
  umount $MNT_PATH
  losetup -d $LOOPDEV
}

_mount() {
  kindle_services stop
  create_mountpoint
  mount_fs
  mount_kindle_system
  setup_resolv
  chroot $MNT_PATH /sbin/openrc sysinit
}

_unmount() {
  chroot $MNT_PATH /sbin/openrc shutdown
  kill -9 $(lsof -t +D $MNT_PATH)
  unmount_kindle_system
  unmount_alpine_mount
  kindle_services start
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
