#!/system/bin/sh
# Replace existing animation files with temporary bind mounts before bootanim starts.
# Never remount or write to a system partition.
MODDIR="${0%/*}"
SRC="$MODDIR/files"
LOG="$MODDIR/mount.log"
mounted=false

[ -f "$SRC/bootanimation.zip" ] || exit 0
exec >"$LOG" 2>&1

TARGETS="/product/media /system/media"
[ ! -f "$MODDIR/mount-targets.txt" ] || TARGETS="$(cat "$MODDIR/mount-targets.txt")"

for dir in $TARGETS; do
    for name in bootanimation.zip bootanimation-dark.zip; do
        source="$SRC/$name"
        target="$dir/$name"
        [ -f "$source" ] && [ -f "$target" ] || continue
        # Resolve symlinks so the symlink itself and its original file stay intact.
        target="$(readlink -f "$target")" || continue
        [ -f "$target" ] || continue
        # Skip files already exposed through magic mount or an earlier bind.
        [ "$source" -ef "$target" ] && continue
        chcon u:object_r:system_file:s0 "$source" || continue
        if mount -o bind "$source" "$target"; then
            mount -o remount,bind,ro "$source" "$target" || {
                echo "Could not make bind read-only: $target"
                umount "$target"
                continue
            }
            mounted=true
            echo "Mounted $name over $target"
        else
            echo "Could not bind $source over $target"
        fi
    done
 done

# Some builds preload bootanim before KernelSU reaches post-fs-data. A mount
# cannot replace an already mmap'ed ZIP. Restart only an active boot animation,
# never after boot completion or after SurfaceFlinger has requested its exit.
if [ "$mounted" = true ] &&
   [ "$(getprop init.svc.bootanim)" = running ] &&
   [ "$(getprop service.bootanim.exit)" != 1 ] &&
   [ "$(getprop sys.boot_completed)" != 1 ]; then
    echo "Restarting active boot animation to reload mounted ZIPs"
    # Keep post-fs-data nonblocking while init handles the control property.
    /system/bin/setprop ctl.restart bootanim &
fi
