# rdesktop access on Unraid using a Jump Desktop RDC with a ssh-tunnel over Tailscale

Them aim is to create a "localhost-only Linux Desktop in a container on Unraid accessed over a non-root ssh tunnel and adding Tailscale to add a Zero Conf VPN over Wireguard" :)

## Considerations

It would have been simple to simply enable Tailscale and `rdesktop` and connect to the RDP port without the ssh tunnel but this was an exercise to remove the exposure of a sensitive service on a non encrypted port from being accessible even to the LAN.

## Tools listed

- [Unraid.net](https://unraid.net/) 
    - Plugin: [docgyver's SSH Config Tool](https://forums.unraid.net/topic/45586-ssh-and-denyhosts-updated-for-v61/)
    - Plugin: [daesmi's unraid-tailscale](https://github.com/deasmi/unraid-tailscale)
    - Container: [linuxserver.io docker-rdesktop](https://github.com/linuxserver/docker-rdesktop)
- [Tailscale.com](https://tailscale.com/)
- [JumpDesktop.com](https://www.jumpdesktop.com/)
- 

## Notes

During the intiial setup, With `DocGyver`'s `SSH Config Tool` installed, make sure to allow enough `Max Auth Retries` for `ssh` to try all your keys before the password is finally prompted for.

We will require some `ssh` keys:
- The following expect some`ssh-keygen` experience to build them (https://www.ssh.com/academy/ssh/keygen).
- We recommend different keys for `root` and the local user.
- We also recommend to add a passphrase to each key.
- Make sure the file permissions in your `~/.ssh` directory are correct, they are often the source of connections errors.

In the following, adapt `unraid_id` with your unraid server IP.
In this setup, the server is NOT accessible on the Internet, only for LAN access, and using encrypted Wireguard tunnel over Tailscale.

## Unraid: key-based ssh setup

### root user

With an `unraid_root` and `unraid_root.pub` `ssh` keys in your `~/.ssh` directory 

`scp` the `root` public key as `authorized_keys` to Unraid's `root`:
```
scp ~/.ssh/unraid_root.pub root@unraid_ip:/root/.ssh/authorized_keys
```
In the above you will be prompted for your password.

Test it, it should be key-based (password-less) now:
```
ssh -i ~/.ssh/unraid_root root@unraid_ip
```

### local user

On the Unraid UI, in `Settings -> Users` add a non `root` (regular) user; for example `luser` and remember its password.
This user will have any special privileges on the host which is the desired state.

With an `unraid_luser` and `unraid_luser.pub` `ssh` keys in your `~/.ssh` directory 

`scp` the `luser` public key `authorized_eys` to Unraid's `luser`:
```
scp ~/.ssh/unraid_luser.pub luser@unraid_ip:.ssh/authorized_keys
```
You will be prompted for the `luser` password.

Test it, it too shall be key-based (and password-less) now:
```
ssh -i ~/.ssh/unraid_luser luser@unraid_ip
```

### Persisting ssh keys over reboot (root only)

As `root` on the Unraid server, copy the `authorized_keys` files with the name of the user (for the `%u` step later to work), then adapt an `sshd_config` to use those files.

```
ssh -i ~/.ssh/unraid_root root@unraid_ip

cp /root/.ssh/authorized_keys /boot/config/ssh/root.pubkeys
cp /home/luser/.ssh/authorized_keys /boot/config/ssh/luser.pubkeys

cp /etc/ssh/sshd_config /boot/config/ssh/
nano /boot/config/ssh/sshd_config
```
Modify the `AuthorizedKeysFile` line to enable both the user directory and `/etc/ssh` keys locations:
```
AuthorizedKeysFile .ssh/authorized_keys /etc/ssh/%u.pubkeys
```

This will force the server to use the username key placed in `/etc/ssh` when a given user logs in.
This will work for `root`, but not for `luser` because this user can not read the file in `/etc/ssh` with its permissions (passed to the ssh process when user attempts to login), which is why we are still allowing the user directory option.

Note that this requires any ssh keys replacement to be placed in `/etc/ssh` (not `~/.ssh`) going forward.

Restart the `sshd` service:
```
/etc/rc.d/rc.sshd restart
```

#### TCP Forwarding

While we are doing this, for ssh tunneling to be enabled for our later setup, please `nano /boot/config/ssh/sshd_config`, uncomment the `AllowTcpForwarding yes` line (and comment its `no` counterpart) before an `/etc/rc.d/rc.sshd restart`. 

#### Post reboot: re-allow luser access

The `luser` user will be recreated after reboot, so its `.ssh` directory will need to have its key re-added to it, luckily it is in the `/etc/ssh` directory:
```
ssh -i ~/.ssh/unraid_root root@unraid_ip
cp /etc/ssh/luser.pubkeys /home/luser/.ssh/authorized_keys
```

## Unraid rdesktop with Jump Desktop access

We will be installing this https://hub.docker.com/r/linuxserver/rdesktop container (`rdesktop` in the `Community Applications`)

We will be using [Jump Desktop](https://www.jumpdesktop.com/) to access it, but other remote access clients would work as long as they can configured to use RDP over an `ssh` tunnel.

Note that you might get invalid certificate errors when you connect, it is okay to accept those (either self-signed or host mismatch -- unraid.net certifcates with a different IP).

### rdesktop: Install

In Unraid's UI, select `Apps` and search for the `rdesktop` (from `linuxserver`'s Repository) container.
Install it in `Bridge` `Network Type` and set up the other parameters as you prefer them; chose your prefered `branch` (I am using `mate-focal` for my setup).

Notice during the creation step that the command uses `-p '3389:3389/tcp'` as an argument, ie listen on all interfaces on port 3389 (if you are using the default port).

Configure Jump Desktop to access the running RDP server on the unraid_ip, and test it.
The default username and password are `abc` for both, you can change it from a `root` terminal on the unraid server using `docker exec -it rdesktop passwd abc`

From the `Docker` tab in Unraid, `Stop` the container

### rdekstop: Listen on localhost only

To disable `rdesktop` from answering requests on the unraid_ip, on the `Docker` tab, `Edit` the container. 

In the `Update Container` page, with `Advanced View` enabled:
- `REMOVE` the `WebUI` parameter; this will remove the `-p 3389:3389` command line option that exposes it on your unraid_ip
- Add `-p 127.0.0.1:3389:3389/tcp` in the `Extra Parameters` for the container, this will only allow localhost access
- Click `Apply`; you will see the new `-p` option enabled in this container.

In the `Docker` tab, start the container.

If you now try to connect using Jump Desktop, you will get "Connection Refused".

### Connect using a ssh tunnel

In the Jump Desktop configuration for your host, create a `SSH Tunnel` configuration with unraid_ip and `luser` in the parameters for this `SSH Server` setup; keep `Password` authentication for testing purpose.

In the `Address` section use `127.0.0.1:3389` instead of `unraid_ip:3389`, the ssh tunnel is the way to get into the host and `rdesktop` is now only answering requests on `127.0.0.1`.

Once confirmed functional, you ca edit Jump Desktop's `SSH Server` to add the `Public Key` Authentication.

### Adding Tailscale to your ssh access localhost only rdesktop setup

With your Unraid already configured with the Tailscale container ( https://github.com/deasmi/unraid-tailscale ), obtain the IP of your Unraid box and `Duplicate` your host configuration in Jump Desktop.

`Edit` the new configuration and create a new `SSH Server` with the Unraid box's Tailscale IP. 

Congratulations, you now have a "localhost-only Linux Desktop in a container on Unraid accessed over a non-root ssh tunnel and adding Tailscale to add a Zero Conf VN over Wireguard" :)

## References

- Persistent ssh key access
https://blog.edwinclement08.com/post/unraid-server-adding-password-less-login/
