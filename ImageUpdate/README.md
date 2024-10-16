# openstack-public-images
Scripts to publish public OS images for VSC Tier-1 Cloud infrastructure

## Usage

To update the images, run `./update_images.sh`.
Run it with `-y` to skip confirmation prompts.
See `./update_images.sh -h` for more info.

You can edit the `urls.json` to change the default download URL template for each distro.

### Custom image list
You can edit the `images.json` file to change which images are updated, or supply a custom file with `-f myfile.json`

The file has this format:
```json
    {
      "distro": "fedora",
      "version_name": "cloud",
      "version_number": "40",
      "url":"https://download.fedoraproject.org/pub/fedora/linux/releases/40/Cloud/x86_64/images/Fedora-Cloud-Base-Generic.x86_64-40-1.14.qcow2"
    },
```
**Notes:**
* `url` is optional if `urls.json` contains a template for `distro`
* The script will fail for `distro`s that aren't currently in `urls.json` unless you update `update.generic.sh` to support them


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
* `test_all.sh`:        Script to test all _existing, public_ images.
* `common.sh`:          Library for common functions.