# Bazzite (deck, NVIDIA) with one change: NetworkManager rebuilt with
# nm-keep-wowlan-on-wake.patch. CI passes the base digest and its Fedora release.
ARG BASE_IMAGE=ghcr.io/ublue-os/bazzite-deck-nvidia:stable
ARG FEDORA=45

FROM scratch AS ctx
COPY build_files /
COPY system_files /system_files

# Which NetworkManager build the base ships.
FROM ${BASE_IMAGE} AS info
RUN mkdir /info \
    && rpm -q --qf '%{NAME}-%{VERSION}-%{RELEASE}' NetworkManager > /info/nm-nvr \
    && rpm -q --qf '%{VENDOR}' NetworkManager > /info/nm-vendor

FROM registry.fedoraproject.org/fedora:${FEDORA} AS nm
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=bind,from=info,source=/info,target=/info \
    /ctx/build-nm.sh

FROM ${BASE_IMAGE}
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=bind,from=nm,source=/out,target=/nm \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/install.sh
RUN bootc container lint
