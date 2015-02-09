FROM pblittle/docker-logstash
MAINTAINER John Crygier <john.crygier@ventivtech.com>

ENV LOGBACK_VERSION 1.1.1
ENV SLF4J_VERSION 1.7.5

ADD http://search.maven.org/remotecontent?filepath=ch/qos/logback/logback-classic/$LOGBACK_VERSION/logback-classic-$LOGBACK_VERSION.jar /opt/logstash/jars/logback-classic-$LOGBACK_VERSION.jar
ADD http://search.maven.org/remotecontent?filepath=ch/qos/logback/logback-core/$LOGBACK_VERSION/logback-core-$LOGBACK_VERSION.jar /opt/logstash/jars/logback-core-$LOGBACK_VERSION.jar
ADD http://search.maven.org/remotecontent?filepath=org/slf4j/slf4j-api/$SLF4J_VERSION/slf4j-api-$SLF4J_VERSION.jar /opt/logstash/jars/slf4j-api-$SLF4J_VERSION.jar
ADD lib /opt/logstash/lib/
