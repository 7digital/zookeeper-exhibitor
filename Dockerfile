FROM openjdk:8-jdk-alpine

ENV ZK_VERSION 3.4.10
ENV ZK_RELEASE http://www.apache.org/dist/zookeeper/zookeeper-${ZK_VERSION}/zookeeper-${ZK_VERSION}.tar.gz
ENV EXHIBITOR_POM https://raw.githubusercontent.com/7digital/exhibitor/master/exhibitor-standalone/src/main/resources/buildscripts/standalone/maven/pom.xml

# Use one step so we can remove intermediate dependencies and minimize size
RUN \
    # Install dependencies
    apk update && \
    apk add curl maven

    # Install ZK
RUN \
    curl -Lo /tmp/zookeeper.tgz $ZK_RELEASE \
    && mkdir -p /opt/zookeeper/transactions /opt/zookeeper/snapshots \
    && tar -xvf /tmp/zookeeper.tgz -C /opt/zookeeper --strip-components=1 \
    && rm /tmp/zookeeper.tgz

    # Install Exhibitor
RUN \
    mkdir -p /opt/exhibitor \
    && curl -Lo /opt/exhibitor/pom.xml $EXHIBITOR_POM \
    && mvn -f /opt/exhibitor/pom.xml package \
    && ln -s /opt/exhibitor/target/exhibitor*jar /opt/exhibitor/exhibitor.jar \

    # Remove build-time dependencies
    && rm -rf /var/lib/apt/lists/*

# Add the wrapper script to setup configs and exec exhibitor
ADD include/wrapper.sh /opt/exhibitor/wrapper.sh

# Add the optional web.xml for authentication
ADD include/web.xml /opt/exhibitor/web.xml

USER root
WORKDIR /opt/exhibitor
EXPOSE 2181 2888 3888 8181

ENTRYPOINT ["bash", "-ex", "/opt/exhibitor/wrapper.sh"]