#version=DEVEL
# Fedora minimal + Hyprland base for Feltline

# -----------------------------------------------------------------------------
# Install source & language
# -----------------------------------------------------------------------------
url --url="https://download.fedoraproject.org/pub/fedora/linux/releases/43/Everything/x86_64/os/"

lang en_US.UTF-8
keyboard us
timezone America/New_York

# -----------------------------------------------------------------------------
# Networking & hostname
# -----------------------------------------------------------------------------
network --bootproto=dhcp --device=link --activate
network --hostname=feltline

# -----------------------------------------------------------------------------
# Bootloader & storage (simple single-disk layout)
# WARNING: this wipes the first disk. Adjust for your setup.
# -----------------------------------------------------------------------------
bootloader --location=mbr --timeout=3 --append="rhgb quiet"

zerombr
clearpart --all --initlabel
autopart --type=lvm

# -----------------------------------------------------------------------------
# SELinux, firewall, services
# -----------------------------------------------------------------------------
selinux --enforcing
firewall --enabled --service=ssh

services --enabled=sshd,NetworkManager,systemd-resolved

# -----------------------------------------------------------------------------
# Users & auth
# Root password is locked; use your user with sudo.
# Set your own password hash for real usage.
# -----------------------------------------------------------------------------
rootpw --lock
user --name=ian --groups=wheel --homedir=/home/ian --shell=/bin/bash --plaintext --password="changeme"
authselect --useshadow --passalgo=sha512

# -----------------------------------------------------------------------------
# System options
# -----------------------------------------------------------------------------
cmdline
skipx
reboot

# -----------------------------------------------------------------------------
# Package selection
# Start from core, then add exactly what we need for:
# - Basic CLI usage
# - Hyprland Wayland session
# - Networking, SSH, fonts, key utils
# -----------------------------------------------------------------------------
%packages
@^minimal-environment
@core

# CLI essentials
bash-completion
vim-enhanced
git
curl
wget
htop
tmux
which
tar
zip
unzip
bind-utils

# Networking & SSH
openssh-clients
openssh-server
NetworkManager-tui

# Wayland / Hyprland stack (package names may evolve, adjust as needed)
# Hyprland itself
hyprland

# Wayland utilities & basics
xdg-desktop-portal
xdg-desktop-portal-wlr
xdg-user-dirs
xdg-utils

# Terminal & launcher (swap later if you want different ones)
kitty
wofi

# Status bar / notifications (placeholder; refine in later epics)
waybar
mako

# Fonts
google-noto-sans-fonts
google-noto-mono-fonts
jetbrains-mono-fonts

# Audio
pipewire
pipewire-alsa
pipewire-pulseaudio
pipewire-jack-audio-connection-kit
wireplumber

# Power / misc utilities
brightnessctl
pavucontrol

# Login/session helpers (no full display manager yet)
seatd
swaylock

# Keep it lean: no full GNOME, KDE, etc.
# No @workstation-product-environment, no @gnome-desktop
%end

# -----------------------------------------------------------------------------
# Post-install: basic enablement
# No dotfiles, no theming. Just make sure the system boots
# and you can start Hyprland from TTY.
# -----------------------------------------------------------------------------
%post
set -e

# Enable SSH
systemctl enable sshd

# Ensure graphical.target isn't forced yet; we stay in multi-user and start Hyprland manually.
systemctl set-default multi-user.target

# Create XDG user dirs for the user
runuser -l ian -c 'xdg-user-dirs-update || true'

%end