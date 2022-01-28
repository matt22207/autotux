# Moonlight notes - not yet an automated install script
# admin is on https://localhost:47990/

# build from here: https://github.com/loki-47-6F-64/sunshine
# with Arch overrides here for systemd and udev.rules : https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=sunshine

#  Error: Could not create Sunshine Mouse: Permission denied #52 https://github.com/loki-47-6F-64/sunshine/issues/52
sudo echo "uinput" > /etc/modules-load.d/uinput.conf

# Ctrl+Alt+Shift+S to enable the stats overlay while streaming.
# Use 60fps+ on client for least lag

# config settings:

resolutions = [
    1280x720,
    1920x1080
]
gamepad = x360
upnp = disabled
amd_rc = auto
amd_quality = default
fps = [10,30,60]
key_rightalt_to_key_win = disabled
min_log_level = 2
origin_pin_allowed = pc
origin_web_ui_allowed = lan
fec_percentage = 10 # default 20 - Percentage of error correcting packets per data packet in each video frame. Higher values can correct for more network packet loss, but at the cost of increasing bandwidth usage. The default value of 20 is what GeForce Experience uses. 
channels = 1 # different channels for multicasting
audio_sink = alsa_output.pci-0000_05_00.1.hdmi-stereo-extra1.monitor
qp = 22 # default 28 - Quantitization Parameter . Higher value means more compression, but less quality
min_threads = 12 # default 1 - for ffmpeg - Increasing the value slightly reduces encoding efficiency, but the tradeoff is usually worth it to gain the use of more CPU cores for encoding. The ideal value is the lowest value that can reliably encode at your desired streaming settings on your hardware. 
hevc_mode = 0
encoder = vaapi

# TODO : remember how to enable VAAPI from: 

# Setup Wake-on-lan - https://wiki.archlinux.org/title/Wake-on-LAN
# triggers: d (disabled), p (PHY activity), u (unicast activity), m (multicast activity), b (broadcast activity), a (ARP activity), and g (WOL / magic packet activity).
sudo ethtool -s enp2s0 wol g
# list current WOL setting
sudo ethtool enp2s0 | grep Wake

# sudo vi /usr/lib/systemd/user/sunshine.service

[Unit]
Description=Sunshine Gamestream Server for Moonlight
StartLimitInterval=300
StartLimitBurst=5

[Service]
ExecStart=/usr/bin/sunshine /home/mehrens/.config/sunshine/sunshine.conf
Restart=on-failure
RestartSec=30

[Install]
WantedBy=graphical-session.target

systemctl --user enable sunshine.service
systemctl --user start sunshine.service

# https://www.rockyourcode.com/how-to-restart-systemd-service-after-suspend/

# sudo vi /usr/lib/systemd/user/sunshine_suspend.service

[Unit]
Description=Sunshine suspend actions
Before=sleep.target

[Service]
Type=simple
ExecStart=-/usr/bin/systemctl --user stop sunshine.service
ExecStartPost=/usr/bin/sleep 5

[Install]
WantedBy=sleep.target

# sudo vi /usr/lib/systemd/user/sunshine_resume.service

[Unit]
Description=Sunshine resume action
Requires=network-online.target
After=network-online.target
Wants=network-online.target NetworkManager-wait-online.service
StartLimitInterval=300
StartLimitBurst=5

[Service]
Type=simple
ExecStart=/usr/bin/systemctl --user restart sunshine.service
Restart=on-failure
RestartSec=30

[Install]
WantedBy=suspend.target
WantedBy=hibernate.target
WantedBy=hybrid-sleep.target

systemctl --user enable sunshine_suspend.service
systemctl --user enable sunshine_resume.service
systemctl --user start sunshine_suspend.service
systemctl --user start sunshine_resume.service

systemctl --user status sunshine_suspend.service
systemctl --user status sunshine_resume.service