#!/bin/bash
# Final stage: swap in the patched NetworkManager packages and trust this repo's signing key.
set -euxo pipefail

# Replace every installed native package built from NetworkManager's SRPM. The i686 libnm
# stays as it is (the daemon change doesn't touch the library), and plugins with their own
# SRPM (openvpn, openconnect) are left alone.
srpm=$(rpm -q --qf '%{SOURCERPM}' NetworkManager)
pkgs=()
while read -r name arch src; do
    [ "$src" = "$srpm" ] && [ "$arch" != i686 ] || continue
    f=$(ls /nm/"$name"-[0-9]*."$arch".rpm)
    pkgs+=("$f")
done < <(rpm -qa --qf '%{NAME} %{ARCH} %{SOURCERPM}\n' 'NetworkManager*')
rpm -Uvh --replacefiles "${pkgs[@]}"
rpm -q NetworkManager | grep -q '\.wowlan1\.'

install -Dm644 /ctx/system_files/etc/pki/containers/jaklans.pub /etc/pki/containers/jaklans.pub
install -Dm644 /ctx/system_files/etc/containers/registries.d/jaklans.yaml /etc/containers/registries.d/jaklans.yaml
python3 - <<'PY'
import json
p = "/etc/containers/policy.json"
policy = json.load(open(p))
policy["transports"]["docker"]["ghcr.io/jaklans/bazzite-deck-nvidia"] = [{
    "type": "sigstoreSigned",
    "keyPath": "/etc/pki/containers/jaklans.pub",
    "signedIdentity": {"type": "matchRepository"},
}]
json.dump(policy, open(p, "w"), indent=4)
PY
