# Stage 1: Build a static binary targeting musl
FROM ubuntu:26.04 AS builder

RUN apt-get update && apt-get install -y curl xz-utils tar sqlite3 libsqlite3-dev build-essential

ARG ZIG_VERSION="0.15.2"

# Install Zig
RUN curl -LO https://ziglang.org/download/${ZIG_VERSION}/zig-x86_64-linux-${ZIG_VERSION}.tar.xz

RUN tar -xJf zig-x86_64-linux-${ZIG_VERSION}.tar.xz -C /usr/local
RUN ln -s /usr/local/zig-x86_64-linux-${ZIG_VERSION}/zig /bin/zig

RUN zig version
WORKDIR /app

COPY build.zig.zon build.zig.zon
COPY build.zig build.zig 
COPY src/ src/

RUN ls 
# Build targeting musl for static linking
RUN zig build  --release=safe

RUN ls /app/zig-out/bin

EXPOSE 3000
CMD ["/app/zig-out/bin/zigtest"]