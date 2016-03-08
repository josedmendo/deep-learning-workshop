#!/bin/bash -

set -e
set -x

## See : https://developer.fedoraproject.org/tools/virt-builder/about.html

## Required for virt-builder ::
# dnf install libguestfs libguestfs-tools
# ->> libguestfs-1.30.6-2.fc22.x86_64 ...

## Running this script the first time takes an extra ~10mins to download 
##   http://libguestfs.org/download/builder/fedora-23.xz

# virt-builder: error: images cannot be shrunk, the output size is too small 
# for this image.  Requested size = 4.0G, minimum size = 6.0G

# virt-builder: error: libguestfs error: bridge 'virbr0' not found.  Try 
# running:  brctl show

# If libvirt is being used then the appliance will connect to "virbr0"
#  (can be overridden by setting "LIBGUESTFS_BACKEND_SETTINGS=network_bridge=<some_bridge>").  
#  This enables full-featured network connections, with working ICMP, ping and so on.
#     ->> suggests that libvirt is not cooperating, somehow

# Try : LIBGUESTFS_BACKEND=direct

# LIBGUESTFS_BACKEND=direct; export LIBGUESTFS_BACKEND

#[  25.1] Writing: /home/user/configure-vm.conf
# virt-builder: error: libguestfs error: internal_write: open: 
# /home/user/configure-vm.conf: No such file or directory

# This worked, apparently


# target location :: <REPO>/vm-images/


# This is the Fedora platform we want to build on.
guest_type=fedora-23


# The build script.
#build_script=/tmp/build-it.sh
# Because virt-builder copies the build script permissions too.
#chmod +x $build_script


#image_file=/tmp/$guest_type.img
image_file=./vm-images/$guest_type.img

port=8080

# How much guest memory we need for the build:
export LIBGUESTFS_MEMSIZE=4096

# Run virt-builder.
# Use a long build path to work around RHBZ#757089.
# $d/run $d/builder/virt-builder 

#virt-builder 

virt-builder -v -x \
  $guest_type \
  --size 7G \
  --output $image_file \
  --commands-from-file vm-config/0-init \
  --commands-from-file vm-config/1-user \
  --write "/home/user/configure-vm.conf:port=$port" \
  --commands-from-file vm-config/3-packages \
  --firstboot-command 'poweroff'

#  --install /usr/bin/yum-builddep,/usr/bin/rpmbuild,@buildsys-build,@development-tools 
#  --run-command "yum-builddep -y /home/build/$srpm" 

# Run qemu directly.  Could also use virt-install --import here.
qemu-system-x86_64 \
  -nodefconfig \
  -nodefaults \
  -nographic \
  -machine accel=kvm:tcg \
  -cpu host \
  -m 2048 \
  -smp 4 \
  -net user \
  -serial stdio \
  -drive file=$image_file,format=raw,if=virtio,cache=unsafe

# The build ran OK if this contains the magic string (see $build_script).
#virt-cat -a /tmp/$guest_type.img /root/virt-sysprep-firstboot.log

# Copy out the SRPMs & RPMs.
#rm -rf /tmp/result
#mkdir /tmp/result
#virt-copy-out -a /tmp/$guest_type.img /home/build/RPMS /home/build/SRPMS /tmp/result

# Leave the guest around so you can examine the /home/build dir if you want.
# Or you could delete it.
#rm /tmp/$guest_type.img
