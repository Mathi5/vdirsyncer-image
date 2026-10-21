# vdirsyncer-image

Docker packaging of [vdirsyncer](https://github.com/pimutils/vdirsyncer) **with the
`google` extra**, published to GHCR as `ghcr.io/mathi5/vdirsyncer-image`.

## Why this exists

Every public vdirsyncer image we audited ships **without** the `google` extra, so the
`google_calendar` and `google_contacts` storages fail at runtime with:

```
aiohttp-oauthlib not installed
```

Upstream's own documentation for the Google storages requires that extra
(`pip install vdirsyncer[google]`). This image pins `vdirsyncer==0.21.0` (the
current release on PyPI) with the extra installed.

Verified on the built image:

```console
$ docker run --rm --entrypoint python3 ghcr.io/mathi5/vdirsyncer-image:0.1.0 \
    -c "import aiohttp_oauthlib, vdirsyncer; print('oauth OK')"
oauth OK
$ docker run --rm --entrypoint python3 ghcr.io/mathi5/vdirsyncer-image:0.1.0 \
    -c "from vdirsyncer.storage import google; print([c for c in dir(google) if 'Storage' in c])"
['GoogleCalendarStorage', 'GoogleContactsStorage']
```

## Usage

The image expects a vdirsyncer config file at `/config/config` and stores the
Google OAuth token in the same mounted directory, so the token survives a rebuild.

```yaml
services:
  vdirsyncer:
    image: ghcr.io/mathi5/vdirsyncer-image:0.1.0
    volumes:
      - ./config:/config
    command: ["sync"]
```

Entrypoint commands:

- `discover` — runs discovery. **This is what triggers the Google OAuth flow.**
  The authorization URL is printed to the logs; open it in a browser on your own
  machine.
- `sync` — runs an initial sync, then loops every `VDIRSYNCER_INTERVAL` seconds
  (default 3600).

## The Google OAuth caveat

vdirsyncer's Google flow uses a **loopback redirect** (`http://127.0.0.1:<random-port>`),
so the browser that completes the sign-in must be able to reach the container's
loopback. When the container is remote, use an SSH tunnel:

```sh
ssh -L 5000:127.0.0.1:5000 user@host
```

and forward the printed port. The token is then written to the mounted config
directory and the flow never repeats.

The Google Cloud credentials must be an **OAuth client of type "Desktop
application"** — a "Web application" client no longer works (upstream changed this
in v0.19.2, issue #1078).

## Publishing

Tag a release and the workflow builds and pushes a multi-arch image
(`linux/amd64`, `linux/arm64`):

```sh
git tag v0.1.0 && git push --tags
```
