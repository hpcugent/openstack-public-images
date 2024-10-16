# Network orphan cleaning
Scripts to clean orphans (ports, security groups) in an openstack project.

## Pitfalls

### Cache
Some of these scripts use the `ports/` folder as a cache. The default expiration is 60 seconds.
Output will warn you if it is cached or not.

The cache time in seconds can be set with `-t` in most scripts. The cache does not self-invalidate so if you run into "file not found" errors, just delete `ports/` or run with `-t 1`.

This also means that it will not reflect recent changes you've made yourself so it is recommended to delete the cache after deleting ports/secgroups

### Projects
By default the scripts will use the first project listed in `openstack project list --my-projects`. You can set the project to use with `-p`.

## Scripts
### getorphanports.sh
Shows a list of ports that are DOWN and not associated with a VM.
Association with a vm is based on matching IP address.

Use `-s` to see (non-cached) details of the ports.

### getorphansecgroups.sh
Shows a list of secgroups that don't belong to any ports.

### getvmofport.sh
Shows you which vm is attached to a given port.

### getportsofsecgroup.sh
Shows a list of ports that use a given secgroup.

## Recommended usage
This workflow relies on DOWN ports, since those can only be the cause of a missing or SHUTDOWN VM.
Still, it's a good idea to verify you're not deleting anything important.

### Get orphaned ports
Get the orphaned ports and their details:
```bash
./getorphanports.sh -s
```
*If there are any hidden ports due to matching VMs, it might be wise to check those as well with `-o`.*

Delete the ports you feel safe deleting with `openstack port delete <port>`.
### Get orphaned groups
Now that you've deleted orphaned ports, there should be security groups that are no longer attached to ports:
`./getorphansecgroups -s`

Now you can delete them with `openstack security group delete <group>`

### Double check
Check `openstack security group list` again and check if there's any more suspicious groups. 
If there's any, use `./getportsofsecgroup.sh <group>` to see what ports are still associated. 

You can also use `./getvmofport <port>` to check out the VMs keeping them `"ACTIVE"`.