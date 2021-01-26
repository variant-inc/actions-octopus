FROM octopusdeploy/octo:7.4.4-alpine

ARG BUILD_DATE
ARG BUILD_REVISION
ARG BUILD_VERSION

LABEL com.github.actions.name="Lazy Octopus Action" \
  com.github.actions.description="Create Release in Octopus" \
  com.github.actions.icon="code" \
  com.github.actions.color="red" \
  maintainer="Variant DevOps <devops@drivevariant.com>" \
  org.opencontainers.image.created=$BUILD_DATE \
  org.opencontainers.image.revision=$BUILD_REVISION \
  org.opencontainers.image.version=$BUILD_VERSION \
  org.opencontainers.image.authors="Variant DevOps <devops@drivevariant.com>" \
  org.opencontainers.image.url="https://github.com/variant-inc/lazy-action-octopus" \
  org.opencontainers.image.source="https://github.com/variant-inc/lazy-action-octopus" \
  org.opencontainers.image.documentation="https://github.com/variant-inc/lazy-action-octopus" \
  org.opencontainers.image.vendor="AWS ECR" \
  org.opencontainers.image.description="Create Release in Octopus"


ENV PATH="$PATH:/root/.dotnet/tools"

RUN apk add --no-cache \
  ca-certificates \
  less \
  ncurses-terminfo-base \
  krb5-libs \
  libgcc \
  libintl \
  libssl1.1 \
  libstdc++ \
  tzdata \
  userspace-rcu \
  zlib \
  icu-libs \
  bash \
  jq \
  curl &&\
  apk -X https://dl-cdn.alpinelinux.org/alpine/edge/main add --no-cache \
  lttng-ust &&\
  curl -sL https://github.com/PowerShell/PowerShell/releases/download/v7.1.0/powershell-7.1.0-linux-alpine-x64.tar.gz -o /tmp/powershell.tar.gz &&\
  mkdir -p /opt/microsoft/powershell/7 &&\
  tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7 &&\
  chmod +x /opt/microsoft/powershell/7/pwsh &&\
  ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh &&\
  curl -sL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet.sh &&\
  chmod +x /tmp/dotnet.sh &&\
  /tmp/dotnet.sh --install-dir "/usr/bin" &&\
  dotnet tool install --global GitVersion.Tool --version 5.6.4

WORKDIR /scripts

COPY scripts/ .

RUN chmod +x -R ./*

ENTRYPOINT ["pwsh", "/scripts/entrypoint.ps1"]