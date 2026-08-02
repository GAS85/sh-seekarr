FROM bash:5.3

ARG VERSION=dev
ARG VCS_REF=dev
ARG BUILD_DATE=unknown
ARG USER=nobody

LABEL maintainer="Georgiy Sitnikov <g.shseekarr@sitnikov.eu>" \
    org.opencontainers.image.title="sh-seekarr" \
    org.opencontainers.image.description="SH implementation of Seekarr as alternative to Huntarr. A lightweight tool that triggers manual searches in Sonarr and Radarr to find missing items and upgrade existing ones to better quality. No UI. No exposed ports. Queries Sonarr and/or Radarr for missing and/or cutoff-unmet items" \
    org.opencontainers.image.source="https://github.com/GAS85/sh-seekarr" \
    org.opencontainers.image.url="https://hub.docker.com/r/gas85/sh-seekarr" \
    org.opencontainers.image.documentation="https://github.com/GAS85/sh-seekarr#" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.version=$VERSION \
    org.opencontainers.image.revision=$VCS_REF

ENV VERSION=$VERSION
ENV VCS_REF=$VCS_REF
ENV TZ=Europe/Zurich

RUN apk add --no-cache curl jq coreutils

WORKDIR /app

COPY --chmod=555 sh-seekarr.sh /app/sh-seekarr.sh
COPY --chmod=444 LICENSE /app/LICENSE

USER $USER

CMD ["bash", "/app/sh-seekarr.sh"]

HEALTHCHECK --interval=5m \
             --timeout=5s \
             --retries=3 \
             CMD pgrep -f /app/sh-seekarr.sh