
# === ThinkPad X220 Minimalist Rice Installer ===

# Colors and UI helpers

# === Advanced UI Setup ===

# === GUI Setup using Zenity ===


ensure_zenity_or_fallback() {
  if ! command -v zenity >/dev/null 2>&1; then
    echo -e "[1;33mZenity not found. Installing...[0m"
    sudo pacman -S --noconfirm zenity || true
  fi

  if command -v zenity >/dev/null 2>&1; then
    choose_theme_gui
  else
    echo -e "[1;33mZenity not working. Falling back to terminal selection.[0m"
    choose_theme
  fi
}


choose_theme_gui() {
  if command -v zenity >/dev/null 2>&1; then
    theme_choice=$(zenity --list --title="Choose Theme" --radiolist \
      --column="Select" --column="Theme" \
      TRUE "Dark" FALSE "Light")

    if [ "$theme_choice" = "Light" ]; then
      THEME_BG="#ffffff"
      THEME_FG="#000000"
    else
      THEME_BG="#000000"
      THEME_FG="#ffffff"
    fi
  else
    echo -e "\033[1;31mZenity not found, falling back to terminal theme selection.\033[0m"
    choose_theme
  fi
}


# Theme selection
choose_theme() {
  echo -e "\n\033[1;36m🎨 Choose a color theme:\033[0m"
  echo "1) Dark (default)"
  echo "2) Light"
  read -rp "Enter choice [1-2]: " theme_choice
  case "$theme_choice" in
    2)
      THEME_BG="$THEME_FG"
      THEME_FG="$THEME_BG"
      ;;
    *)
      THEME_BG="$THEME_BG"
      THEME_FG="$THEME_FG"
      ;;
  esac
  echo -e "\nTheme selected: Background: $THEME_BG, Foreground: $THEME_FG"
}

# Simple progress function
progress_bar() {
  local msg=$1
  echo -ne "\033[1;33m$msg...\033[0m"
  for i in {1..10}; do
    echo -n "."
    sleep 0.1
  done
  echo -e " \033[1;32m✔\033[0m"
}

header() {
  echo -e "\n\033[1;35m──────────────────────────────────────────────"
  echo -e "🧠  ThinkPad X220 Rice Installer (v1.0)"
  echo -e "──────────────────────────────────────────────\033[0m\n"
}

step() {
  echo -e "\033[1;34m🔧 $1...\033[0m"
}

success() {
  echo -e "\033[1;32m[✔] $1\033[0m"
}

fail() {
  echo -e "\033[1;31m[❌] $1\033[0m"
}

header
ensure_zenity_or_fallback

#!/bin/bash

set -e

# === minimalist rice for ThinkPad X220 (Arch Linux) ===

# 1. Update system and install core packages
step "Updating system"
sudo pacman -Syu --noconfirm || fail "System update failed"
success "System updated"
step "Installing core packages"
sudo pacman -S --needed --noconfirm base-devel git bspwm sxhkd alacritty xorg xorg-xinit polybar thunar   zsh feh dmenu lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings   ttf-jetbrains-mono ttf-font-awesome unzip   networkmanager nm-connection-editor pipewire pipewire-audio   alsa-utils brightnessctl acpi wireplumber libnotify dunst xdotool   maim neofetch lxappearance qt5ct gtk-engine-murrine acpi

# 2. Enable services
step "Enabling NetworkManager"
sudo systemctl enable NetworkManager
success "NetworkManager enabled"
step "Enabling LightDM"
sudo systemctl enable lightdm
success "LightDM enabled"

# === Optional laptop enhancements ===
step "Installing laptop enhancements"

# Power saving with TLP
sudo pacman -S --noconfirm tlp tlp-rdw
sudo systemctl enable tlp

# Redshift for night lighting
sudo pacman -S --noconfirm redshift

# xdg user dirs
sudo pacman -S --noconfirm xdg-user-dirs
xdg-user-dirs-update

# Trash CLI for safe file deletion
sudo pacman -S --noconfirm trash-cli
echo "alias rm='trash'" >> ~/.zshrc

# Bluetooth support
sudo pacman -S --noconfirm blueman bluez
sudo systemctl enable bluetooth

# Optional ThinkPad battery control
if ! command -v tpacpi-bat >/dev/null 2>&1; then
  yay -S --noconfirm tpacpi-bat
  sudo tpacpi-bat -s 1 80 || true
fi

success "Enhancements installed"

# === Configure ThinkPad fan control (AUR safe) ===
step "Setting up fan control with ThinkFan (AUR)"

# Install lm_sensors
sudo pacman -S --noconfirm lm_sensors
yes | sudo sensors-detect --auto

# Load needed modules
sudo modprobe thinkpad_acpi
sudo modprobe coretemp

# Enable fan control option
echo "options thinkpad_acpi fan_control=1" | sudo tee /etc/modprobe.d/thinkfan.conf
echo "thinkpad_acpi" | sudo tee /etc/modules-load.d/thinkfan.conf

# Install thinkfan from AUR if pacman version fails
if ! pacman -Q thinkfan &>/dev/null; then
  yay -S --noconfirm thinkfan
fi

# Configure using automatic sensor detection
sudo tee /etc/thinkfan.conf >/dev/null << EOF
sensor auto

(0,     0,      55)
(1,     50,     60)
(2,     58,     65)
(3,     63,     70)
(4,     68,     75)
(5,     73,     80)
(7,     78,     32767)
EOF

# Enable and restart thinkfan (ignore failure at this stage)
sudo systemctl enable thinkfan || true
sudo systemctl restart thinkfan || true

success "ThinkFan configured"






# === Setup lockscreen with lid close ===
step "Setting up lock screen"

# Ensure i3lock and xautolock are installed
sudo pacman -S --noconfirm i3lock xautolock

# Generate lockscreen background
betterlockscreen -u ~/Pictures/wallpaper.png

# Autolock after 10 min idle
mkdir -p ~/.config/bspwm
touch ~/.config/bspwm/bspwmrc
grep -q 'xautolock' ~/.config/bspwm/bspwmrc || echo 'xautolock -time 10 -locker "betterlockscreen -l" &' >> ~/.config/bspwm/bspwmrc

# Handle lid close with systemd (lock on suspend)
step "Configuring lid close action"
sudo sed -i 's/^#HandleLidSwitch=.*/HandleLidSwitch=suspend/' /etc/systemd/logind.conf
sudo sed -i 's/^#HandleLidSwitchDocked=.*/HandleLidSwitchDocked=suspend/' /etc/systemd/logind.conf
sudo systemctl restart systemd-logind

success "Lockscreen with lid close configured"


# 3. Install yay and AUR packages
if ! command -v yay &>/dev/null; then
  step "Installing yay AUR helper"
git clone https://aur.archlinux.org/yay.git ~/yay
  cd ~/yay && makepkg -si --noconfirm
  cd .. && rm -rf ~/yay
fi
yay -S --needed --noconfirm nmcli-dmenu-git betterlockscreen

# 4. Create necessary directories
step "Creating configuration directories"
mkdir -p ~/.config/{bspwm,sxhkd,alacritty,polybar,picom,dunst}
mkdir -p ~/Pictures/screenshots

# 5. Wallpaper
step "Downloading wallpaper"
curl -L -o ~/Pictures/wallpaper.png https://i.imgur.com/cKr62pe.png

# 6. BSPWM config
step "Setting up BSPWM config"
cat > ~/.config/bspwm/bspwmrc << 'EOF'
#!/bin/bash
setxkbmap pl
sxhkd &
picom --config ~/.config/picom/picom.conf &
dunst &
feh --bg-scale ~/Pictures/wallpaper.png &
~/.config/polybar/launch.sh &
bspc monitor -d I II III IV V VI VII VIII IX X
EOF
chmod +x ~/.config/bspwm/bspwmrc

# 7. SXHKD config
cat > ~/.config/sxhkd/sxhkdrc << 'EOF'
super + Return
  alacritty
super + d
  dmenu_run -fn "JetBrainsMono-10" -nb "$THEME_BG" -nf "$THEME_FG" -sb "$THEME_FG" -sf "$THEME_BG" -h 24
super + w
  ~/.config/polybar/wifimenu.sh
super + v
  ~/.config/polybar/volumemenu.sh
super + BackSpace
  ~/.config/polybar/powermenu.sh
super + shift + l
  betterlockscreen -l
Print
  ~/.config/polybar/screenshotmenu.sh
super + {h,j,k,l}
  bspc node -f {west,south,north,east}
super + {1-9}
  bspc desktop -f ^{1-9}
super + q
  bspc node -c
super + shift + {h,j,k,l}
  bspc node -s {west,south,north,east}
XF86AudioRaiseVolume
  wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ && notify-send 'volume up'
XF86AudioLowerVolume
  wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && notify-send 'volume down'
XF86AudioMute
  wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && notify-send 'mute toggle'
XF86MonBrightnessUp
  brightnessctl set +10% && notify-send 'brightness up'
XF86MonBrightnessDown
  brightnessctl set 10%- && notify-send 'brightness down'
EOF

# 8. Polybar scripts and configs

# launch.sh
cat > ~/.config/polybar/launch.sh << 'EOF'
#!/bin/bash
killall -q polybar
while pgrep -x polybar >/dev/null; do sleep 1; done
polybar top &
EOF
chmod +x ~/.config/polybar/launch.sh

# powermenu.sh
cat > ~/.config/polybar/powermenu.sh << 'EOF'
#!/bin/bash
choice=$(printf "suspend
poweroff
reboot
logout
restart bspwm" | dmenu -i -p "power menu" -fn "JetBrainsMono-10" -nb "$THEME_BG" -nf "$THEME_FG" -sb "$THEME_FG" -sf "$THEME_BG" -h 24)
case "$choice" in
  suspend) systemctl suspend ;;
  poweroff) systemctl poweroff ;;
  reboot) systemctl reboot ;;
  logout) pkill -KILL -u $USER ;;
  restart\ bspwm) bspc wm -r ;;
esac
EOF
chmod +x ~/.config/polybar/powermenu.sh

# volumemenu.sh
cat > ~/.config/polybar/volumemenu.sh << 'EOF'
#!/bin/bash
choice=$(printf "volume up
volume down
mute toggle
open mixer" | dmenu -i -p "volume" -fn "JetBrainsMono-10" -nb "$THEME_BG" -nf "$THEME_FG" -sb "$THEME_FG" -sf "$THEME_BG" -h 24)
case "$choice" in
  "volume up") wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ && notify-send "🔊 Volume up" ;;
  "volume down") wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && notify-send "🔉 Volume down" ;;
  "mute toggle") wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && notify-send "🔇 Mute toggled" ;;
  "open mixer") alacritty -e alsamixer ;;
esac
EOF
chmod +x ~/.config/polybar/volumemenu.sh

# wifimenu.sh
cat > ~/.config/polybar/wifimenu.sh << 'EOF'
#!/bin/bash
SSID=$(nmcli -t -f SSID dev wifi list | sed '/^$/d' | sort -u | dmenu -i -p "WiFi SSID" -fn "JetBrainsMono-10" -nb "$THEME_BG" -nf "$THEME_FG" -sb "$THEME_FG" -sf "$THEME_BG" -h 24)
[ -z "$SSID" ] && exit
if nmcli -t -f NAME connection show | grep -q "^$SSID$"; then
  nmcli connection up "$SSID"
else
  PASSWORD=$(dmenu -p "Password for $SSID:" -P -fn "JetBrainsMono-10" -nb "$THEME_BG" -nf "$THEME_FG" -sb "$THEME_FG" -sf "$THEME_BG" -h 24)
  nmcli dev wifi connect "$SSID" password "$PASSWORD"
fi
[ $? -eq 0 ] && notify-send "✅ Connected to $SSID" || notify-send "❌ Failed to connect to $SSID"
EOF
chmod +x ~/.config/polybar/wifimenu.sh

# battery.sh
cat > ~/.config/polybar/battery.sh << 'EOF'
#!/bin/bash
BAT=$(acpi -b)
if [[ $BAT == *"Charging"* ]]; then ICON="🔌"
elif [[ $BAT == *"Discharging"* ]]; then ICON="🔋"
elif [[ $BAT == *"Full"* ]]; then ICON="⚡"
else ICON="❓"; fi
PERCENT=$(echo "$BAT" | grep -o '[0-9]\+%' | head -n1)
echo "$ICON $PERCENT"
EOF
chmod +x ~/.config/polybar/battery.sh

# activewindow.sh
cat > ~/.config/polybar/activewindow.sh << 'EOF'
#!/bin/bash
while true; do
  win_id=$(xdotool getactivewindow 2>/dev/null)
  [ -n "$win_id" ] && title=$(xprop -id "$win_id" WM_NAME | cut -d '"' -f 2) && echo "${title:0:60}" || echo ""
  sleep 1
done
EOF
chmod +x ~/.config/polybar/activewindow.sh

# config.ini
step "Writing Polybar config"
cat > ~/.config/polybar/config.ini << 'EOF'
[bar/top]
width = 100%
height = 24
background = $THEME_BG
foreground = $THEME_FG
font-0 = JetBrainsMono:size=10;1
modules-left = bspwm
modules-center = activewindow
modules-right = battery volume wlan date

[module/bspwm]
type = internal/bspwm
label-focused = %name%
label-focused-background = $THEME_FG
label-focused-foreground = $THEME_BG
label-occupied = %name%
label-occupied-foreground = #aaaaaa
label-empty = %name%
label-empty-foreground = #555555

[module/activewindow]
type = custom/script
exec = ~/.config/polybar/activewindow.sh
tail = true

[module/volume]
type = internal/pulseaudio
format-volume = 🔊 %percentage%%
format-muted = 🔇 muted
click-left = ~/.config/polybar/volumemenu.sh

[module/wlan]
type = internal/network
interface = wlan0
format-connected = 📶 %essid% (%signal%%)
format-disconnected = ⚠️ no wifi
click-left = ~/.config/polybar/wifimenu.sh

[module/battery]
type = custom/script
exec = ~/.config/polybar/battery.sh
interval = 30

[module/bluetooth]

[module/bluetooth]
type = custom/script
exec = ~/.config/polybar/bluetooth.sh
interval = 10
click-left = ~/.config/polybar/bluetoothmenu.sh


[module/temp]

[module/temp]
type = custom/script
exec = ~/.config/polybar/temperature.sh
interval = 15


[module/date]
type = internal/date
interval = 5
format = 🕒 %H:%M %d/%m
EOF

# === Bluetooth Polybar Scripts ===
cat > ~/.config/polybar/bluetooth.sh << 'EOF'
#!/bin/bash
if bluetoothctl show | grep -q 'Powered: yes'; then
  echo " on"
else
  echo " off"
fi
EOF
chmod +x ~/.config/polybar/bluetooth.sh

cat > ~/.config/polybar/bluetoothmenu.sh << 'EOF'
#!/bin/bash
choice=$(printf "enable bluetooth
disable bluetooth
open manager" | dmenu -i -p "bluetooth" -fn "JetBrainsMono-10" -nb "$THEME_BG" -nf "$THEME_FG" -sb "$THEME_FG" -sf "$THEME_BG" -h 24)
case "$choice" in
  "enable bluetooth") bluetoothctl power on && notify-send "Bluetooth enabled" ;;
  "disable bluetooth") bluetoothctl power off && notify-send "Bluetooth disabled" ;;
  "open manager") blueman-manager ;;
esac
EOF
chmod +x ~/.config/polybar/bluetoothmenu.sh

# === Temperature Script ===
cat > ~/.config/polybar/temperature.sh << 'EOF'
#!/bin/bash
TEMP=$(sensors | grep -m 1 'Core 0' | grep -o '+[0-9]\+.[0-9]°C')
[ -n "$TEMP" ] && echo "🌡 $TEMP" || echo "🌡 N/A"
EOF
chmod +x ~/.config/polybar/temperature.sh
