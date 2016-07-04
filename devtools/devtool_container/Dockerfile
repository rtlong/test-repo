FROM quay.io/goodguide/base:ubuntu-15.10-2

# Install Docker-client
RUN set -x \
 && apt-key adv --keyserver 'hkp://p80.pool.sks-keyservers.net:80' --recv-keys '58118E89F3A912897C070ADBF76221572C52609D' \
 && echo 'deb https://apt.dockerproject.org/repo ubuntu-wily main' > /etc/apt/sources.list.d/docker.list \
 && apt-get update \
 && apt-get install docker-engine \
 && apt-get clean

# install docker-compose
RUN set -x \
 && version='1.6.0' sha256='58f6d50fcad042f54463cf8e380d72809334d61294e4b958aa256b8283b39781' \
 && curl -L -o /tmp/docker-compose "https://github.com/docker/compose/releases/download/${version}/docker-compose-$(uname -s)-$(uname -m)" \
 && shasum -a 256 /tmp/docker-compose | grep -q "${sha256}" \
 && install -v /tmp/docker-compose "$PREFIX/bin/docker-compose" \
 && rm -vrf /tmp/*

RUN apt-get update \
 && apt-get install -y ruby

RUN gem install rake
RUN gem install pry

WORKDIR /app

ENV PATH /app/devtools/bin:$PATH
ENV IS_DEVTOOL_CONTAINER true
