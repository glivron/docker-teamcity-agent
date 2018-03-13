FROM ubuntu:xenial

RUN apt-get -qq update     \
 && apt-get -qq upgrade -y \
 && apt-get -qq install -y apt-utils apt-transport-https ca-certificates locales iputils-ping openjdk-8-jdk build-essential curl procps git libfontconfig zip imagemagick libjpeg8-dev zlib1g-dev python-pip python-pythonmagick \

 && apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D \
 && echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" > /etc/apt/sources.list.d/docker.list \
 && apt-get -qq update \
 && apt-get -qq install -y docker-engine \
 && curl -L https://github.com/docker/compose/releases/download/1.12.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose \
 && chmod +x /usr/local/bin/docker-compose \

 && pip install --upgrade pip \
 && pip install awscli \

 && apt-get -qq clean -y \
 && rm -fR /tmp/*

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# --------------------------------------------------------------- teamcity-agent
ENV TEAMCITY_VERSION 2017.2.3

RUN curl -LO http://download.jetbrains.com/teamcity/TeamCity-$TEAMCITY_VERSION.war \
 && unzip -qq TeamCity-$TEAMCITY_VERSION.war -d /tmp/teamcity \
 && unzip -qq /tmp/teamcity/update/buildAgent.zip -d /teamcity-agent \

 && chmod +x /teamcity-agent/bin/*.sh \
 && mv /teamcity-agent/conf/buildAgent.dist.properties /teamcity-agent/conf/buildAgent.properties \

 && rm -f TeamCity-$TEAMCITY_VERSION.war \
 && rm -fR /tmp/* ~/.cache/*

RUN sed -i 's/serverUrl=http:\/\/localhost:8111\//serverUrl=http:\/\/teamcity:8080\/teamcity\//' /teamcity-agent/conf/buildAgent.properties \
 && sed -i 's/workDir=..\/work/workDir=\/home\/teamcity\/work/'                                  /teamcity-agent/conf/buildAgent.properties

# ----------------------------------------------------------------------- nodejs
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash - \
 && apt-get -qq install -y nodejs    \
 && apt-get -qq clean -y             \
 && npm update  -g                   \
 && npm install -g node-gyp gulp-cli || true


RUN useradd -m teamcity \
 && usermod -aG docker teamcity \
 && chown -R teamcity:teamcity /usr/lib/node_modules /teamcity-agent

USER teamcity
EXPOSE 9090
CMD ["/teamcity-agent/bin/agent.sh", "run"]
