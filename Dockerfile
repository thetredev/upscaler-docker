FROM ubuntu:22.04 AS builder

ARG realesrgan_version="v0.2.0"
ARG realesrgan_zip_url="https://github.com/xinntao/Real-ESRGAN-ncnn-vulkan/releases/download/${realesrgan_version}/realesrgan-ncnn-vulkan-${realesrgan_version}-ubuntu.zip"

RUN apt-get update
RUN apt-get install --no-install-recommends -y meson
RUN apt-get install --no-install-recommends -y ninja-build
RUN apt-get install --no-install-recommends -y blueprint-compiler
RUN apt-get install --no-install-recommends -y git
RUN apt-get install --no-install-recommends -y desktop-file-utils
RUN apt-get install --no-install-recommends -y libadwaita-1-dev
RUN apt-get install --no-install-recommends -y gettext
RUN apt-get install --no-install-recommends -y libgettextpo-dev
RUN apt-get install --no-install-recommends -y ca-certificates

WORKDIR /app

RUN git clone https://gitlab.com/TheEvilSkeleton/Upscaler.git upscaler

WORKDIR /app/upscaler

RUN meson --prefix=/usr/local build
RUN ninja -C build
RUN ninja -C build install

RUN apt-get install --no-install-recommends -y curl
RUN apt-get install --no-install-recommends -y unzip

WORKDIR /tmp
RUN curl -fsSL -o realesrgan.zip ${realesrgan_zip_url}
RUN unzip realesrgan.zip
RUN mv "realesrgan-ncnn-vulkan-${realesrgan_version}-ubuntu/realesrgan-ncnn-vulkan" /usr/local/bin


FROM jlesage/baseimage-gui:ubuntu-20.04-v4.1.5

RUN apt-get update \
    && \
        # Upgrade all packages
        apt-get -y full-upgrade \
    && \
        # Upgrade to Ubuntu 22.04
        apt-get install -y update-manager-core && \
        do-release-upgrade -f DistUpgradeViewNonInteractive && \
        # Upgrade to Ubuntu 22.10
        sed -i 's/Prompt=lts/Prompt=normal/g' /etc/update-manager/release-upgrades && \
        do-release-upgrade -f DistUpgradeViewNonInteractive \
    && \
        # Install runtime dependencies
        apt-get install --no-install-recommends -y \
            ca-certificates \
            curl \
            python3 \
            python3-gi \
            python3-gi-cairo \
            gir1.2-gtk-4.0 \
            gir1.2-adw-1 \
            libgtk-4-1 \
            xfonts-base \
            libgl1-mesa-glx \
            libegl1-mesa \
            libgomp1 \
    && \
        # Clean up
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local /usr/local
COPY ./startapp.sh /startapp.sh

RUN set-cont-env APP_NAME "Upscaler" && \
    chmod +x /startapp.sh
