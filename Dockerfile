# vdirsyncer with the `google` extra (aiohttp-oauthlib), pinned to a known-good version.
#
# Why not a public image: every public vdirsyncer image we audited ships WITHOUT
# the `google` extra, so the `google_calendar` / `google_contacts` storages raise
# "aiohttp-oauthlib not installed" at runtime. The upstream project's own
# docs for the Google storages require that extra.
#
# Built and published from this repo's release workflow to GHCR.

FROM python:3.13-slim

ARG VDIRSYNCER_VERSION=0.21.0

# curl: the healthcheck probes the local vdirsyncer process.
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# `google` extra pulls aiohttp-oauthlib, which the Google storages import.
RUN pip install --no-cache-dir "vdirsyncer[google]==${VDIRSYNCER_VERSION}"

# Run as a non-root user; the data directory is owned by it.
RUN useradd --create-home --uid 1000 --shell /usr/sbin/nologin vdirsyncer
USER vdirsyncer
WORKDIR /home/vdirsyncer

# The config file and the OAuth token file live here. Both are bind-mounted
# from the host so the Google token survives a container rebuild.
ENV HOME=/home/vdirsyncer \
    XDG_CONFIG_HOME=/home/vdirsyncer/.config \
    XDG_DATA_HOME=/home/vdirsyncer/.local/share \
    XDG_CACHE_HOME=/home/vdirsyncer/.cache

ENTRYPOINT ["vdirsyncer"]
CMD ["--help"]
