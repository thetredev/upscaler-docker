# Upscaler as Docker container

This project aims to provide [the Upscaler GTK4 project](https://gitlab.com/TheEvilSkeleton/Upscaler) as a Docker container using https://github.com/jlesage/docker-baseimage-gui as a base.

# The Dockerfile
It's a 2-stage build:

1. Use the `ubuntu:22.04` image to build [the Upscaler project](https://gitlab.com/TheEvilSkeleton/Upscaler) and prepare [Real-ESRGAN-ncnn-vulkan](https://github.com/xinntao/Real-ESRGAN-ncnn-vulkan)
2. Use the `jlesage/baseimage-gui:ubuntu-20.04-v4.1.5` image and upgrade it all the way to Ubuntu 22.10. Then install all required runtime dependencies for the application and setup the startup script.

Why Ubuntu 22.10? GTK4 is only supported from 22.04, but its file browser has issues when typing in a file name. GTK4 in Ubuntu 22.10 fixes that issue.

Why not Debian? Debian Sid (Bookworm) is probably less stable than Ubuntu 22.10. Just my personal opinion.

Why not Alpine? There's no `musl` build of [Real-ESRGAN-ncnn-vulkan](https://github.com/xinntao/Real-ESRGAN-ncnn-vulkan).

# Build instructions
```shell
git clone https://github.com/thetredev/upscaler-docker.git
cd upscaler-docker
docker build -t upscaler:test .
```

# What's working?
Start the server as follows:
```shell
docker run --rm \
    --mount type=bind,source="${HOME}",target="${HOME}",readonly \
    -e "USER_ID=$(id -u)" \
    -e "GROUP_ID=$(id -g)" \
    -p 5800:5800 \
    -p 5900:5900 \
    upscaler:test
```

Open a browser and navigate to http://localhost:5800 to use the application. Your home directory is mounted as `/home/<username>` inside the container. Click the 'Upscale' button to open the file browser. Inside, select an image located in your home directory on the host. Then, select the destination image the same way.

# Current issues

The actual upscaling doesn't work currently, though. The reason is that the upscaling engine [Real-ESRGAN-ncnn-vulkan](https://github.com/xinntao/Real-ESRGAN-ncnn-vulkan) needs an actual GPU with Vulkan support to do its work. I have no idea how to pass through a GPU to a Docker container, because I never did that. I saw some tutorials/articles/threads about that topic (https://docs.docker.com/compose/gpu-support/, https://forums.unraid.net/topic/82762-is-it-possible-to-passthrough-amd-gpu-to-dockers/) but I couldn't get the `docker run` command to pass through my AMD GPU (RX 5700 XT). Seems like only NVIDIA CUDA is supported by Docker itself.

The error message is:
```shell
realesrgan-ncnn-vulkan: error while loading shared libraries: libvulkan.so.1: cannot open shared object file: No such file or directory
```

`libvulkan.so.1` and/or the stuff that makes the library work AFAIK comes with the GPU driver itself, so it's not as trivial.
