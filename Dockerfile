FROM docker.elastic.co/elasticsearch/elasticsearch:5.6.3

ENV xpack.security.enabled false

VOLUME /usr/share/elasticsearch/data

VOLUME /usr/share/elasticsearch/config/
