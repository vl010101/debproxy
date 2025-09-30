# Final working Dockerfile for debproxy on Debian 11
FROM debian:bullseye-slim

ARG DEBIAN_FRONTEND=noninteractive

RUN \
    apt-get update -y && \
    apt-get install -y --no-install-recommends \
      ca-certificates jq tor net-tools cron nano mc python2 python-is-python2 supervisor unzip wget \
      # Add swig, a dependency for compiling m2crypto
      build-essential python2-dev libssl-dev swig \
    && \
    wget https://bootstrap.pypa.io/pip/2.7/get-pip.py -O /tmp/get-pip.py && \
    python2 /tmp/get-pip.py && \
    # Downgrade m2crypto to a much older, more compatible version
    pip2 install apsw==3.9.2.post1 m2crypto==0.22.3 && \
    # --- AceStream Installation ---
    mkdir -p /mnt/media/playlists && \
    wget -O /tmp/acestream.tar.gz http://dl.acestream.org/linux/acestream_3.1.16_debian_8.7_x86_64.tar.gz && \
    tar --strip-components=1 -C /usr/share -vzxf /tmp/acestream.tar.gz && \
    # --- Final Cleanup ---
    apt-get purge -y --auto-remove build-essential python2-dev libssl-dev swig && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY ace.hls_parser.sh /mnt/media/playlists/ace.hls_parser.sh
COPY torrc /etc/tor/torrc
COPY start.sh /usr/bin/start.sh

RUN chmod +x /mnt/media/playlists/ace.hls_parser.sh && \
    chmod +x /usr/bin/start.sh

EXPOSE 8621 62062 9944 9903 6878
VOLUME /mnt/media/playlists
WORKDIR /
ENTRYPOINT ["/usr/bin/start.sh"]
