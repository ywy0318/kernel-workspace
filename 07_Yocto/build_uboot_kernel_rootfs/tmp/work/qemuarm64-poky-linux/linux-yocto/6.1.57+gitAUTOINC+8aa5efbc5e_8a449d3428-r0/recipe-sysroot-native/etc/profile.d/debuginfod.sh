# $HOME/.profile* or similar files may first set $DEBUGINFOD_URLS.
# If $DEBUGINFOD_URLS is not set there, we set it from system *.url files.
# $HOME/.*rc or similar files may then amend $DEBUGINFOD_URLS.
# See also [man debuginfod-client-config] for other environment variables
# such as $DEBUGINFOD_MAXSIZE, $DEBUGINFOD_MAXTIME, $DEBUGINFOD_PROGRESS.

if [ -z "$DEBUGINFOD_URLS" ]; then
    prefix="/home/ubuntu/workspace/07_Yocto/build_uboot_kernel_rootfs/tmp/work/qemuarm64-poky-linux/linux-yocto/6.1.57+gitAUTOINC+8aa5efbc5e_8a449d3428-r0/recipe-sysroot-native/usr"
    DEBUGINFOD_URLS=$(cat /dev/null "/home/ubuntu/workspace/07_Yocto/build_uboot_kernel_rootfs/tmp/work/qemuarm64-poky-linux/linux-yocto/6.1.57+gitAUTOINC+8aa5efbc5e_8a449d3428-r0/recipe-sysroot-native/etc/debuginfod"/*.urls 2>/dev/null | tr '\n' ' ')
    [ -n "$DEBUGINFOD_URLS" ] && export DEBUGINFOD_URLS || unset DEBUGINFOD_URLS
    unset prefix
fi
