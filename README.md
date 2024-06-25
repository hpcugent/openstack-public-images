# openstack-public-images
Scripts to publish public OS images for VSC Tier-1 Cloud infrastructure

## Usage

To update the images, run `./update_images.sh`.
See `./update_images.sh -h` for more info.

You can edit the `images.json` file to change which images are updated, or supply a custom file with `-f myfile.json`
**Warning:** Only the listed distros are supported, but it should work for all _versions_ of that distro.

### Cleaning up backups
The script will create backups of each image and deactivate them, unless it cannot find an existing image to back up.

You can clean these backups (or any deactivated images) with `./image_cleanup.sh`.

## How it works
`./update_images` will call `./update_generic.sh` with the required environment variables in a loop, once per `images.json` entry.

It will then use known URL patterns for the various distros (see the `download_iso` function) to download the ISO.

It will then install `python3-distro` and `chrony` and configure it specific to the distro type. 

Finally it will upload the new image and make a backup of the old one.

## Components

* `update_images.sh`:   Wrapper and `.json` parser for `update_generic.sh`.
* `update_generic.sh`:  Script to update a single image based on env variables.
* `image_cleanup.sh`:   Script to cleanup deactivated openstack images.
* `common.sh`:          Library for common functions.