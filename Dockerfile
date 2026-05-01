FROM ubuntu:22.04 AS build

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libphonenumber-dev \
    libprotobuf-dev \
    libicu-dev \
    cmake \
    build-essential \
    wget \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Install Zig (minimum 0.15.2 )
ARG ZIG_VERSION=0.15.2

RUN wget https://ziglang.org/download/${ZIG_VERSION}/zig-x86_64-linux-${ZIG_VERSION}.tar.xz \
    && tar -xf zig-x86_64-linux-${ZIG_VERSION}.tar.xz \
    && mv zig-x86_64-linux-${ZIG_VERSION} /usr/local/zig \
    && ln -s /usr/local/zig/zig /usr/local/bin/zig \
    && rm zig-x86_64-linux-${ZIG_VERSION}.tar.xz

# Set working directory
WORKDIR /app

# Copy source code
COPY . .

# Build C++ wrapper
RUN chmod +x build_wrapper.sh && ./build_wrapper.sh

# Build Zig application
RUN zig build -Doptimize=ReleaseFast

# --- runtime stage ---

FROM ubuntu:22.04 AS runtime

RUN apt-get update && apt-get install -y \
    libphonenumber8 \
    libprotobuf23 \
    libicu70 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /app/zig-out/bin/phonecheck ./
COPY --from=build /app/lib/libphonenumber_wrapper.so ./lib/

# Fix the shared lib path so the binary finds the wrapper
ENV LD_LIBRARY_PATH=/app/lib

EXPOSE 8080
CMD ["/app/phonecheck"]
