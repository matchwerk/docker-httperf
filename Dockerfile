FROM debian:buster

RUN apt-get update \
    && apt-get install -y \
        build-essential \
        automake \
        git \
        libtool \
        libssl-dev

RUN cd /opt \
    && git clone https://github.com/httperf/httperf.git \
    && cd httperf \
    && autoreconf -i \
    && ./configure \
    && make \
    && make install

ENTRYPOINT ["httperf"]
