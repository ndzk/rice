#!/bin/bash

set -e

# === minimalist rice for thinkpad x220 ===
# bspwm + polybar + dmenu + nmcli + pipewire + full keybindings and menus + notifications + greeter theme

# 1. install core packages
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm base-devel git bspwm sxhkd alacritty xorg xorg-xinit \
  zsh feh dmenu lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings \
  ttf-jetbrains-mono ttf-font-awesome unzip \
  networkmanager nm-connection-editor pipewire pipewire-audio \
  alsa-utils brightnessctl acpi wireplumber libnotify dunst xdotool \
  maim neofetch lxappearance qt5ct gtk-engine-murrine

# enable services
sudo systemctl enable NetworkManager
sudo systemctl enable lightdm

# 2. install yay and aur tools
cd ~
git clone https://aur.archlinux.org/yay.git
cd yay && makepkg -si --noconfirm
cd .. && rm -rf yay
yay -S --noconfirm polybar-git nmcli-dmenu-git betterlockscreen

# 3. setup folders
mkdir -p ~/.config/{bspwm,sxhkd,alacritty,polybar,picom,dunst}
mkdir -p ~/Pictures/screenshots

# 4. download ascii wallpaper
curl -L -o ~/Pictures/wallpaper.png https://i.imgur.com/cKr62pe.png

# 5. generate bspwm config
cat > ~/.config/bspwm/bspwmrc << 'EOF'
#!/bin/bash
setxkbmap pl
sxhkd &
picom --config ~/.config/picom/picom.conf &
dunst &
feh --bg-scale ~/Pictures/wallpaper.png &
~/.config/polybar/launch.sh &
bspc monitor -d i ii iii iv v vi vii viii ix x
EOF'
#!/bin/bash
sxhkd &
picom --config ~/.config/picom/picom.conf &
dunst &
feh --bg-scale ~/Pictures/wallpaper.png &
~/.config/polybar/launch.sh &
bspc monitor -d i ii iii iv v vi vii viii ix x
EOF
chmod +x ~/.config/bspwm/bspwmrc

# 6. generate sxhkd config
cat > ~/.config/sxhkd/sxhkdrc << 'EOF'
super + Return
  alacritty
super + d
  dmenu_run
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

# 7. screenshot menu script
cat > ~/.config/polybar/screenshotmenu.sh << 'EOF'
#!/bin/bash
choice=$(printf "entire screen\nselect area\nactive window" | dmenu -i -p "screenshot")
dest=~/Pictures/screenshots/screenshot_$(date +%Y-%m-%d_%H-%M-%S).png
case "$choice" in
  "entire screen") maim "$dest";;
  "select area") maim -s "$dest";;
  "active window") maim -i $(xdotool getactivewindow) "$dest";;
esac
[ -f "$dest" ] && notify-send "screenshot saved to $dest"
EOF
chmod +x ~/.config/polybar/screenshotmenu.sh

# 8. polybar config
cat > ~/.config/polybar/config.ini << 'EOF'
[bar/top]
width = 100%
height = 24
background = #000000
foreground = #ffffff
font-0 = JetBrainsMono:size=10;1
modules-left = bspwm
modules-center = activewindow
modules-right = volume wlan battery date

[module/bspwm]
type = internal/bspwm
label-focused = %name%
label-focused-background = #ffffff
label-focused-foreground = #000000
label-occupied = %name%
label-empty =

[module/activewindow]
type = custom/script
exec = xprop -id $(xdotool getactivewindow 2>/dev/null) WM_NAME | cut -d '"' -f 2 || echo ""
interval = 1

[module/volume]
type = custom/script
exec = echo VOL
click-left = ~/.config/polybar/volumemenu.sh

[module/wlan]
type = custom/script
exec = echo WIFI
click-left = ~/.config/polybar/wifimenu.sh

[module/date]
type = internal/date
interval = 5
format = %Y-%m-%d %H:%M

[module/battery]
type = internal/battery
battery = BAT0
adapter = AC
full-at = 98
format-charging = CHG %percentage%%
format-discharging = BAT %percentage%%
EOF

# 9. polybar scripts
cat > ~/.config/polybar/launch.sh << 'EOF'
#!/bin/bash
killall -q polybar
while pgrep -x polybar >/dev/null; do sleep 1; done
polybar top &
EOF
chmod +x ~/.config/polybar/launch.sh

cat > ~/.config/polybar/powermenu.sh << 'EOF'
#!/bin/bash
choice=$(printf "suspend\npoweroff\nreboot\nlogout\nrestart bspwm" | dmenu -i -p "power menu")
case "$choice" in
  suspend) systemctl suspend;;
  poweroff) systemctl poweroff;;
  reboot) systemctl reboot;;
  logout) pkill -KILL -u $USER;;
  restart\ bspwm) bspc wm -r;;
esac
EOF
chmod +x ~/.config/polybar/powermenu.sh

cat > ~/.config/polybar/wifimenu.sh << 'EOF'
#!/bin/bash
nmcli_dmenu
EOF
chmod +x ~/.config/polybar/wifimenu.sh

cat > ~/.config/polybar/volumemenu.sh << 'EOF'
#!/bin/bash
choice=$(printf "volume up\nvolume down\nmute\nopen mixer" | dmenu -i -p "volume")
case "$choice" in
  volume\ up) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+;;
  volume\ down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-;;
  mute) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle;;
  open\ mixer) alacritty -e alsamixer;;
esac
EOF
chmod +x ~/.config/polybar/volumemenu.sh

# 10. picom config
cat > ~/.config/picom/picom.conf << 'EOF'
backend = "glx";
vsync = true;
corner-radius = 0;
opacity-rule = [ "90:class_g = 'Alacritty'" ];
EOF

# 11. alacritty config
cat > ~/.config/alacritty/alacritty.yml << 'EOF'
window:
  opacity: 0.95
  decorations: none
  padding:
    x: 6
    y: 6
colors:
  primary:
    background: '0x000000'
    foreground: '0xffffff'
font:
  normal:
    family: JetBrainsMono
    size: 11
EOF

# 12. dunst config
cat > ~/.config/dunst/dunstrc << 'EOF'
[global]
    monitor = 0
    follow = mouse
    width = 300
    height = 100
    offset = 10x10
    scale = 0
    origin = top-right
    font = JetBrainsMono 10
    frame_width = 1
    separator_height = 2
    padding = 8
    background = "#000000"
    foreground = "#ffffff"
    frame_color = "#ffffff"
EOF

# 13. zsh config
chsh -s /bin/zsh
cat > ~/.zshrc << 'EOF'
alias poweroff='systemctl poweroff'
alias reboot='systemctl reboot'
export TERM=xterm-256color
autoload -Uz promptinit && promptinit
prompt off
alias ls='ls --color=never'
neofetch
EOF

# 14. xinitrc fallback
cat > ~/.xinitrc << 'EOF'
exec bspwm
EOF

# 15. lightdm greeter config
sudo mkdir -p /etc/lightdm

# write greeter config
sudo bash -c 'cat > /etc/lightdm/lightdm-gtk-greeter.conf' << EOF
[greeter]
theme-name=Adwaita
gtk-theme-name=Adwaita
icon-theme-name=Adwaita
background=/usr/share/backgrounds/xfce/xfce-blue.jpg
font-name=JetBrainsMono 11
xft-antialias=true
xft-hintstyle=hintfull
EOF

# set greeter session
sudo bash -c 'cat > /etc/lightdm/lightdm.conf' << EOF
[Seat:*]
greeter-session=lightdm-gtk-greeter
user-session=bspwm
EOF
echo -e "rice installation complete. reboot and login via lightdm."
