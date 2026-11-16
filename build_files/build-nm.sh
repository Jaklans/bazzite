#!/bin/bash
# Rebuilds the base image's exact Fedora NetworkManager with the wake patch.
# Runs in the fedora:<release> stage; RPMs land in /out.
set -euxo pipefail
NVR=$(cat /info/nm-nvr)
VENDOR=$(cat /info/nm-vendor)
[ "$VENDOR" = "Fedora Project" ] || { echo "base NetworkManager comes from '$VENDOR', not Fedora: fetch that SRPM instead" >&2; exit 1; }

dnf -y -q install rpm-build rpmdevtools dnf-plugins-core koji cpio
mkdir -p /src /out && cd /src
# Koji keeps every build; the updates repo only keeps the newest one.
koji download-build --arch=src "$NVR" || dnf -y -q download --source "$NVR"
rpmdev-setuptree
rpm -i "$NVR.src.rpm"
cp /ctx/nm-keep-wowlan-on-wake.patch ~/rpmbuild/SOURCES/
cd ~/rpmbuild/SPECS
sed -i '/^Source1:/a Patch900: nm-keep-wowlan-on-wake.patch' NetworkManager.spec
sed -i -E 's/^(Release:\s*)(.*)$/\1\2.wowlan1/' NetworkManager.spec
dnf -y -q builddep NetworkManager.spec
jobs=$(nproc); [ "$jobs" -gt 12 ] && jobs=12
rpmbuild -bb NetworkManager.spec --nocheck --define "_smp_build_ncpus $jobs"
# The daemon must carry the patch's log message, or the patch didn't apply.
mkdir /check && rpm2cpio ~/rpmbuild/RPMS/x86_64/NetworkManager-1.*.x86_64.rpm \
    | (cd /check && cpio -idm --quiet ./usr/sbin/NetworkManager)
grep -q "kept its connection over suspend" /check/usr/sbin/NetworkManager \
    || { echo "patch not applied" >&2; exit 1; }
cp ~/rpmbuild/RPMS/*/*.rpm /out/
ls -l /out
