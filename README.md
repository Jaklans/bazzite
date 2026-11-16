# bazzite

Bazzite deck-nvidia with one change: NetworkManager is rebuilt with a patch that keeps a Wake-on-WLAN wifi connection up across suspend.

Stock NetworkManager unmanages any device with Wake-on-LAN/WLAN armed as soon as the system wakes, then reconnects it from scratch. On my machine that drops wifi for about 7 seconds on every resume, even though the connection stayed up the whole time it was asleep. With the patch, a device that is still activated at wake keeps its connection and just renews DHCP. Anything else takes the stock path.

The image builds the exact Fedora NetworkManager version the current Bazzite stable ships, so it follows Bazzite releases on its own. CI checks the base every 6 hours and only rebuilds when it changed. Images are signed with `cosign.pub`.

Switching to it takes two steps, because the trust config ships inside the image:

```
sudo bootc switch ghcr.io/jaklans/bazzite-deck-nvidia:latest   # unverified, once
# reboot
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/jaklans/bazzite-deck-nvidia:latest
# reboot
```

Updates then come through the normal Bazzite update path. Back to stock is `rpm-ostree rebase ostree-image-signed:docker://ghcr.io/ublue-os/bazzite-deck-nvidia:stable`.

Steam's OS update channel picker still rebases to stock ublue-os images, which drops the patch.
