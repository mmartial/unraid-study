# Things I wished I had READ before my first Unraid Install... and more

First, check out https://wiki.unraid.net/Manual/Overview it will answer a lot about the hypervisor.
Then https://wiki.unraid.net/Articles/Getting_Started to get a simple idea bout how to set "what up".

Having enough CPUs to run all: base OS + VMs (with pinned CPUs) and Containers (sharing all the remaining server) helps.

Array drives should be initialized with Zeros to speed up Parity, see https://wiki.unraid.net/Parity and the "Unassigned Devices Preclear" App helps with that.
The "Array" part should only have spinning drives + parity drive(s). See https://wiki.unraid.net/Manual/Storage_Management .
Run a parity check once in a while (every month? it is a long process).

Anything that needs to be accessed quickly should be in "pools" on SSD/NVMe (you can create as many pools as you need). See https://wiki.unraid.net/Cache_disk .

When you create a new "Share", "Prefer" it to one of your "cache" (ie pool) drive. See https://wiki.unraid.net/Cache_disk and https://wiki.unraid.net/Manual/Shares .
New shares are automatically shared to your subnet, if that is not what you want, change that in the share's setting.
You can back its content to your array using "luckyBackup" App.
Shares can be open or "user" accessible, create users accordingly.

Community Apps (CA) is a great place to find tons of cool tech https://forums.unraid.net/topic/38582-plug-in-community-applications/ .
A lot of those will require Docker, so make sure to enable it (maybe both the docker directory and the container's appdata to a cache drive, no need to use a disk image, prefer a directory, less constraints on space). See https://wiki.unraid.net/Manual/Docker_Management .
For Docker, if you have a GPU setup you can access it by adding "--gpus all" to the container's Template's "Extra Parameters"; if you only have one GPU otherwise, see https://forums.unraid.net/topic/98978-plugin-nvidia-driver/ .

Network mounts (NFS, SMB, ...) is fairly uncomplicated.
Mounting exFAT, HFS+, ... is easier thanks to "Unassigned Devices" and "Unassigned Devices Plus" (in CA).

Unraid support VMs and hardware passthrough, see https://wiki.unraid.net/Manual/VM_Management and https://wiki.unraid.net/Manual/VM_Guest_Support .
GPU passthrough for VMs is possible but only if you do not install the GPU driver for Container usage (or have multiple GPUs to assign). 
For Windows VM, SeaBIOS worked with screen resizing.
Setting up a Mac VM can be done using MacInABox (in CA).

Do not expose your Unraid server to the world, use TailScale.com (there is a CA for that, remember to "disable key expiry" in your "machines" list on your TS dashboard) or another VPN setup to access your host securely.
Some considerations can be read here https://wiki.unraid.net/Manual/Security .
If you have Firewalla hardware, see https://firewalla.com/pages/vpn-service .

Check the forums, people have likely had your problems before. 
For CA, that often is the "Support Thread".

Take a look at those plugins, some might make your life a lot easier :)
- Required: Community Applications
    - CA Auto Update Applications
    - CA Backup / Restore Appdata
    - CA Config Editor
- Must have: Fix Common Problems
- Unassigned Devices + Unassigned Devices Plus + Unassigned Devices Preclear
- If SSD: Dynamix SSD TRIM
- If Nvidia GPU: Nvidia Driver + NVTOP + GPU Statistics
- If VMs: VM Backup
- unBALANCE will help you move data from drive to drive if the terminal is not any option (it uess a rsync -X command) 
- Useful: Dynamix Active Streams + Dynamix System Statistics + Dynamix System Information + File Activity + Open Files
- User Scripts + Nerd Tools + ssh Plugin + Tips and Tweaks

Docker containers, from CA:
- Remote access: Tailscale
- VM manager: Virt-Manager
- Docker management: Portainer-CE + Dozzle
- File manager: Krusader_non-root
- Remote access over tailscale (or just like https everything): Nginx-Proxy-Manager-Official
- Main page for sub services (see above): heimdall
- Custom backup from pools to array: luckyBackup
- if you have a friend of a second host running one: syncthing
- Wanna do data science in a box? :) Jupyter-TensorFlow_OpenCV for CPU, and if you have a GPU Jupyter-CuDNN_TensorFlow_OpenCV; both can run concurrently and share the same directory so you test if you code runs on CPU and GPU
- Containerized Steam box (Linux, with GPU access if "--gpus all", not a VM): steam-headless
- Containerized Linux desktop (Linux, with GPU access if "--gpus all", not a VM): rdesktop

VM setup:
- Linux, pretty straightforward (no sound passthrough over noVNC --that I could find). 
- Mac: see CA for Macinabox
- Windows: prefer SeaBIOS
