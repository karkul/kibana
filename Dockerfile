# Dockerfile for Kibana 4.5.4

# Build with:
# docker build -t <repo-user>/kibana .

# Run with:
# docker run -p 5601:5601 -it --name kibana <repo-user>/elk

FROM phusion/baseimage
MAINTAINER Ramon Morales http://github.com/karkul
ENV REFRESHED_AT 2016-08-20

###############################################################################
#                                INSTALLATION
###############################################################################

### install prerequisites (cURL, gosu)

ENV GOSU_VERSION 1.8
ENV DEBIAN_FRONTEND=noninteractive

RUN set -x \
 && apt-get update -qq \
 && apt-get install -qqy --no-install-recommends ca-certificates curl \
 && rm -rf /var/lib/apt/lists/* \
 && curl -L -o /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
 && curl -L -o /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
 && export GNUPGHOME="$(mktemp -d)" \
 && gpg --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
 && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
 && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
 && chmod +x /usr/local/bin/gosu \
 && gosu nobody true \
 && apt-get clean \
 && set +x


### install depedencies

RUN apt-get update -qq \
 && apt-get install -qqy \
		openjdk-8-jdk net-tools telnet \
 && apt-get clean


### install Kibana

ENV KIBANA_VERSION 4.5.4
ENV KIBANA_HOME /opt/kibana
ENV KIBANA_PACKAGE kibana-${KIBANA_VERSION}-linux-x64.tar.gz
ENV KIBANA_GID 993
ENV KIBANA_UID 993

RUN mkdir ${KIBANA_HOME} \
 && curl -O https://download.elasticsearch.org/kibana/kibana/${KIBANA_PACKAGE} \
 && tar xzf ${KIBANA_PACKAGE} -C ${KIBANA_HOME} --strip-components=1 \
 && rm -f ${KIBANA_PACKAGE} \
 && groupadd -r kibana -g ${KIBANA_GID} \
 && useradd -r -s /usr/sbin/nologin -d ${KIBANA_HOME} -c "Kibana service user" -u ${KIBANA_UID} -g kibana kibana \
 && mkdir -p /var/log/kibana \
 && chown -R kibana:kibana ${KIBANA_HOME} /var/log/kibana

ADD ./kibana-init /etc/init.d/kibana
RUN sed -i -e 's#^KIBANA_HOME=$#KIBANA_HOME='$KIBANA_HOME'#' /etc/init.d/kibana \
 && chmod +x /etc/init.d/kibana


###############################################################################
#                               CONFIGURATION
###############################################################################

### configure Kibana
ADD ./kibana.yml /opt/kibana/config/kibana.yml


###############################################################################
#                                   START
###############################################################################

ADD ./start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

EXPOSE 5601

ENTRYPOINT [ 'docker-entrypoint.sh' ]
CMD [ "/usr/local/bin/start.sh" ]
