# Convert an overcloud-full.qcow2 into an image to boot an undercloud from

The `convert-image` role transforms an overcloud-full image into one which an
undercloud can be booted from in order to save time on package installs, while
not needing to maintain/host a specific undercloud image.

## Variables

* `convert_image_working_dir`: -- directory to be used for image conversion
* `convert_image_template`: jinja template for the script which does the
  conversion
* `convert_image_update`: Boolean controlling whether to run an update as part
  of the image conversion
* `convert_image_remove_pkgs`: List of packages that need to be removed from
  the overcloud image
* `convert_image_install_pkgs`: List of packages that need to be installed on
  the overcloud image
* `convert_image_tempest_plugins`: List of tempest plugins to install (This is
  separate from the install list so that it can be allowed to fail without
  failing the conversion)
* `overcloud_full_root_pwd`: If set the defined password will
  set for the root user on the overcloud-full image.  The
  resulting overcloud and undercloud instances will have
  the password set.
