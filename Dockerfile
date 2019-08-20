FROM debian:buster-20190812 as builder

# install build deps
RUN apt-get update \
    && apt-get install -y \
        automake \
        build-essential \
        git \
        libssl-dev \
        libtool \
        strace

# build
RUN cd /opt \
    && git clone https://github.com/httperf/httperf.git \
    && cd httperf \
    && autoreconf -i \
    && ./configure \
    && make \
    && make install

# check libraries loaded
RUN ldd /usr/local/bin/httperf \
    | tr -s '[:blank:]' '\n' \
    | grep '^/' \
    | xargs -I % sh -c 'mkdir -p $(dirname deps%); cp % deps%;'

# ldd won't catch everything
RUN strace -e trace=open,openat httperf 2>&1 \
    | grep -oP '^(open|openat).*?"\K(.*)(?=".*?)' \
    | xargs -I % sh -c 'mkdir -p $(dirname deps%); cp % deps%;'

# somehow stuff for dns is still not picked up
RUN mkdir -p /deps/lib/x86_64-linux-gnu \
    && cp /lib/x86_64-linux-gnu/libnss_dns.so.2 /deps/lib/x86_64-linux-gnu/libnss_dns.so.2

# do it again for the nss dns lib
RUN ldd /lib/x86_64-linux-gnu/libnss_dns.so.2 \
    | tr -s '[:blank:]' '\n' \
    | grep '^/' \
    | xargs -I % sh -c 'mkdir -p $(dirname deps%); cp % deps%;'

RUN echo "Found runtime dependencies:" \
    && find /deps -type f

# final image
FROM scratch
COPY --from=builder /deps /
COPY --from=builder /usr/local/bin/httperf /httperf

ENTRYPOINT ["/httperf"]
