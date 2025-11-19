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
network --bootproto=dhcp --activate --hostname=feltlineok

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
# -----------------------------------------------------------------------------
# Hyprland COPR repository (since Fedora 43 repo is missing it)
# -----------------------------------------------------------------------------
repo --name=hyprland-copr --baseurl=https://download.copr.fedorainfracloud.org/results/solopasha/hyprland/fedora-43-x86_64/

%packages
@core

# CLI essentials
bash-completion
vim-enhanced
git
curl
wget
htop
tmux
tar
zip
unzip
which
bind-utils
tree

# Networking & SSH
openssh-clients
openssh-server
NetworkManager-tui

# Hyprland + Wayland stack
hyprland
xdg-desktop-portal
xdg-desktop-portal-wlr
xdg-user-dirs
xdg-utils

# Terminal + launcher
kitty
wofi

# Bar + notifications
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

# Utilities
brightnessctl
pavucontrol
seatd
swaylock

# Productivity
chromium
%end

# -----------------------------------------------------------------------------
# Post-install: basic enablement
# No dotfiles, no theming. Just make sure the system boots
# and you can start Hyprland from TTY.
# -----------------------------------------------------------------------------
%post
set -e

# -----------------------------------------------------------------------------
# 1. Basic system setup
# -----------------------------------------------------------------------------

# Enable SSH
systemctl enable sshd

# Stay in text mode; you'll start Hyprland from TTY
systemctl set-default multi-user.target

# -----------------------------------------------------------------------------
# 2. Pull Feltline repo into the installed system
# -----------------------------------------------------------------------------

# Clone into /opt so it's not cluttering /home by default
git clone https://github.com/ipdelete/feltline /opt/feltline || {
    echo "Failed to clone feltline repo" >&2
    exit 1
}

# -----------------------------------------------------------------------------
# 3. Install Hyprland & Waybar configs for user 'ian'
# -----------------------------------------------------------------------------

USER_NAME=ian
USER_HOME=/home/$USER_NAME

# Make sure the home dir exists (should already from user --name, but be safe)
if [ ! -d "$USER_HOME" ]; then
    mkdir -p "$USER_HOME"
    chown "$USER_NAME:$USER_NAME" "$USER_HOME"
fi

# Create config directories
mkdir -p "$USER_HOME/.config/hypr"
mkdir -p "$USER_HOME/.config/waybar"

# Copy configs from repo → user's config dirs
cp /opt/feltline/configs/hypr/hyprland.conf \
   "$USER_HOME/.config/hypr/"

cp /opt/feltline/configs/waybar/config.jsonc \
   /opt/feltline/configs/waybar/style.css \
   "$USER_HOME/.config/waybar/"

# Fix ownership so ian actually owns their own dotfiles
chown -R "$USER_NAME:$USER_NAME" "$USER_HOME/.config"

# -----------------------------------------------------------------------------
# 4. XDG user dirs
# -----------------------------------------------------------------------------

# Run as ian so the dirs are created with the right owner
runuser -l ian -c 'xdg-user-dirs-update || true'

# -----------------------------------------------------------------------------
# 5. GitHub CLI repo + install
# -----------------------------------------------------------------------------

# Write the official repo file
cat > /etc/yum.repos.d/gh-cli.repo << 'EOF'
[gh-cli]
name=packages for the GitHub CLI
baseurl=https://cli.github.com/packages/rpm
enabled=1
gpgcheck=1
gpgkey=https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x23F3D4EA75716059
EOF

# Import the GPG key
rpm --import https://cli.github.com/packages/rpm/gh-cli.repo.gpg

# Install gh
dnf install -y gh

%end
