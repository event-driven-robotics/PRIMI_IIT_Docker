ARG BASE_IMAGE=public.ecr.aws/ubuntu/ubuntu:22.04
FROM ${BASE_IMAGE}

ENV DEBIAN_FRONTEND=noninteractive

ARG CODE_DIR=/usr/local/src
ARG BASE_IMAGE
ARG YCM_VERSION=v0.18.4
ARG YARP_VERSION=v3.12.2
ARG ICUB_MAIN_VERSION=v2.9.0
ARG ED_VERSION=main
ARG ED_COMMIT=45bce288ba616b2f19152ee96cecbb4da1c924cf
ARG INSTALL_METAVISION_SDK=0
ARG PROPHESEE_JFROG_USER=
ARG PROPHESEE_JFROG_TOKEN=

RUN apt-get update && apt-get install -y \
    ca-certificates \
    build-essential \
    cmake \
    cmake-curses-gui \
    ffmpeg \
    git \
    libace-dev \
    libassimp-dev \
    libboost-program-options-dev \
    libcanberra-gtk-module \
    libeigen3-dev \
    libglew-dev \
    libglfw3-dev \
    libglm-dev \
    libgsl-dev \
    libgraphviz-dev \
    libgstreamer-plugins-base1.0-dev \
    libgstreamer1.0-dev \
    libjpeg-dev \
    libopencv-dev \
    libqcustomplot-dev \
    mesa-utils \
    python3 \
    python3-pip \
    qtbase5-dev \
    qtdeclarative5-dev \
    qtmultimedia5-dev \
    qml-module-qtmultimedia \
    qml-module-qt-labs-folderlistmodel \
    qml-module-qt-labs-settings \
    qml-module-qtquick-controls \
    qml-module-qtquick-dialogs \
    qml-module-qtquick-window2 \
    qml-module-qtquick2 \
    gstreamer1.0-libav \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gosu \
    && rm -rf /var/lib/apt/lists/*

# Metavision SDK is optional. The default image omits it because the current
# Prophesee SDK 5.x install flow requires authenticated access to JFrog.
RUN if [ "${INSTALL_METAVISION_SDK}" = "1" ]; then \
        if [ -z "${PROPHESEE_JFROG_USER}" ] || [ -z "${PROPHESEE_JFROG_TOKEN}" ]; then \
            echo "INSTALL_METAVISION_SDK=1 requires PROPHESEE_JFROG_USER and PROPHESEE_JFROG_TOKEN" >&2; \
            exit 1; \
        fi; \
        apt-get update; \
        apt-get install -y curl; \
        curl -L https://propheseeai.jfrog.io/artifactory/api/security/keypair/prophesee-gpg/public >/tmp/propheseeai.jfrog.op.asc; \
        cp /tmp/propheseeai.jfrog.op.asc /etc/apt/trusted.gpg.d/propheseeai.jfrog.op.asc; \
        printf 'machine propheseeai.jfrog.io\nlogin %s\npassword %s\n' "${PROPHESEE_JFROG_USER}" "${PROPHESEE_JFROG_TOKEN}" >/etc/apt/auth.conf.d/prophesee-jfrog.conf; \
        chmod 600 /etc/apt/auth.conf.d/prophesee-jfrog.conf; \
        printf 'deb https://propheseeai.jfrog.io/artifactory/metavision-sdk-5-debian/ /\n' >/etc/apt/sources.list.d/metavision-sdk.list; \
        apt-get update; \
        apt-get install -y metavision-sdk; \
        rm -f /etc/apt/auth.conf.d/prophesee-jfrog.conf /etc/apt/sources.list.d/metavision-sdk.list /tmp/propheseeai.jfrog.op.asc; \
        rm -rf /var/lib/apt/lists/*; \
    fi

RUN git clone --depth 1 --branch "${YCM_VERSION}" https://github.com/robotology/ycm-cmake-modules.git "${CODE_DIR}/ycm" \
    && cmake -S "${CODE_DIR}/ycm" -B "${CODE_DIR}/ycm/build" \
    && cmake --build "${CODE_DIR}/ycm/build" -j"$(nproc)" \
    && cmake --install "${CODE_DIR}/ycm/build"

RUN git clone --depth 1 --branch "${YARP_VERSION}" https://github.com/robotology/yarp.git "${CODE_DIR}/yarp" \
    && cmake -S "${CODE_DIR}/yarp" -B "${CODE_DIR}/yarp/build" \
    && cmake --build "${CODE_DIR}/yarp/build" -j"$(nproc)" \
    && cmake --install "${CODE_DIR}/yarp/build" \
    && yarp check

RUN git clone --depth 1 --branch "${ICUB_MAIN_VERSION}" https://github.com/robotology/icub-main.git "${CODE_DIR}/icub-main" \
    && cmake -S "${CODE_DIR}/icub-main" -B "${CODE_DIR}/icub-main/build" -DBUILD_TESTING=OFF \
    && cmake --build "${CODE_DIR}/icub-main/build" -j"$(nproc)" \
    && cmake --install "${CODE_DIR}/icub-main/build"

RUN git clone --depth 1 --branch "${ED_VERSION}" https://github.com/robotology/event-driven.git "${CODE_DIR}/event-driven" \
    && test "$(git -C "${CODE_DIR}/event-driven" rev-parse HEAD)" = "${ED_COMMIT}" \
    && cmake -S "${CODE_DIR}/event-driven" -B "${CODE_DIR}/event-driven/build" \
    && cmake --build "${CODE_DIR}/event-driven/build" -j"$(nproc)" \
    && cmake --install "${CODE_DIR}/event-driven/build"

RUN groupadd -g 1000 -o robotology \
    && useradd -m -u 1000 -g 1000 -o -s /bin/bash robotology

COPY container-scripts/start-yarpserver.sh /usr/local/bin/start-yarpserver
COPY container-scripts/container-entrypoint.sh /usr/local/bin/container-entrypoint
RUN chmod +x /usr/local/bin/start-yarpserver /usr/local/bin/container-entrypoint

ENTRYPOINT ["/usr/local/bin/container-entrypoint"]
WORKDIR /workspace/project

CMD ["/bin/bash"]
