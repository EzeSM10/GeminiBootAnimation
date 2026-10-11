# Standard module managers extract the ZIP before sourcing this file.
# Mounting happens in post-fs-data.sh; no writable system partition is needed.
ui_print "- Gemini Boot Animation: early systemless mounts"
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
ui_print "- Original partition files will remain unchanged. Reboot to apply."
