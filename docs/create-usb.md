sudo wipefs -a /dev/sda

Finally. The ISO façade is gone, the fake DVD partition table is gone, the PMBR is gone… the stick is now a blank, obedient slab of silicon. Perfect.

Let’s rebuild this thing properly before something auto-mounts it again out of spite.

⸻

STEP 1 — Create a clean GPT

sudo parted /dev/sda --script mklabel gpt

STEP 2 — Make one big FAT32 partition

Installer + EFI + Kickstart all in one.

sudo parted /dev/sda --script mkpart primary fat32 1MiB 100%
sudo parted /dev/sda --script set 1 boot on

STEP 3 — Format the new partition

Give it the label we’ll reference from GRUB:

sudo mkfs.vfat -n FELTLINE /dev/sda1

Run lsblk -f again and you should see:

sda1  vfat  FELTLINE  UUID=...

If that looks right, we continue.

⸻

STEP 4 — Mount the USB

sudo mount /dev/sda1 /mnt

STEP 5 — Mount the Fedora ISO

Pick the ISO you used earlier:

sudo mkdir -p /tmp/iso
sudo mount -o loop ~/Downloads/Fedora-Server-dvd-x86_64-43*.iso /tmp/iso

(Adjust the filename if needed.)

STEP 6 — Copy ISO contents (now writable)

This is the big one:

sudo cp -r /tmp/iso/* /mnt/
sync

When this finishes, /mnt contains a full Fedora installer, but writable this time.

⸻

STEP 7 — Add your Kickstart

sudo cp /home/ian/feltline/kickstart/feltline-minimal.ks /mnt/ks.cfg

Verify:

ls -l /mnt/ks.cfg


⸻

STEP 8 — Patch the USB’s GRUB

Edit:

sudo nano /mnt/EFI/BOOT/grub.cfg

Find the installer entry, the line that begins:

linuxefi /images/pxeboot/vmlinuz

Or:

linux /images/pxeboot/vmlinuz

Append this to the end:

inst.ks=hd:LABEL=FELTLINE:/ks.cfg

Example:

linuxe /images/pxeboot/vmlinuz inst.stage2=hd:LABEL=FELTLINE quiet inst.ks=hd:LABEL=FELTLINE:/ks.cfg

Save and exit.

⸻

STEP 9 — Unmount everything

sudo umount /mnt
sudo umount /tmp/iso


⸻

STEP 10 — Boot from USB

It should automatically:
	•	start the Fedora installer
	•	detect your Kickstart
	•	run the install without you typing a single boot arg
