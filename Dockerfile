FROM ubuntu:xenial

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN apt-get -qq update \
 && apt-get -qq upgrade -y \
 && apt-get -qq install -y apt-transport-https ca-certificates openjdk-8-jdk build-essential curl procps git libfontconfig zip imagemagick libjpeg8-dev zlib1g-dev python-pip python-pythonmagick \

 && apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D \
 && echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" > /etc/apt/sources.list.d/docker.list \
 && apt-get -qq update \
 && apt-get -qq install -y docker-engine \

 && pip install --upgrade pip \
 && pip install awscli \

 && apt-get -qq clean -y \
 && rm -fR /tmp/*

# --------------------------------------------------------------- teamcity-agent
ENV TEAMCITY_VERSION 10.0.4

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
RUN curl -sLO https://deb.nodesource.com/setup_6.x \
 && chmod +x setup_6.x \
 && ./setup_6.x \
 && apt-get -qq install -y nodejs \
 && apt-get -qq clean -y \
 && rm setup_6.x \
 && rm -fR /tmp/* \
 && npm update  -g \
 && npm install -g node-gyp bower grunt-cli gulp-cli karma-cli typescript angular-cli

# ------------------------------------------------------------------------ maven
ENV MAVEN_VERSION 3.3.9

RUN (curl -L http://www.us.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | gunzip -c | tar x) \
 && mv apache-maven-$MAVEN_VERSION apache-maven

ENV M2_HOME /apache-maven
ENV MAVEN_OPTS -Xmx512m -Xss256k -XX:+UseCompressedOops
ENV PATH $PATH:$M2_HOME/bin

# ---------------------------------------------------------- aws-maven extension
ENV AWS_MAVEN_VERSION 5.0.0.RELEASE

RUN mvn dependency:get -DgroupId=org.springframework.build -DartifactId=aws-maven -Dversion=$AWS_MAVEN_VERSION \
 && mvn dependency:copy-dependencies -f /root/.m2/repository/org/springframework/build/aws-maven/$AWS_MAVEN_VERSION/aws-maven-$AWS_MAVEN_VERSION.pom -DincludeScope=runtime -DoutputDirectory=/teamcity-agent/plugins/mavenPlugin/maven-watcher-jdk16/ \
 && cp /root/.m2/repository/org/springframework/build/aws-maven/$AWS_MAVEN_VERSION/aws-maven-$AWS_MAVEN_VERSION.jar /teamcity-agent/plugins/mavenPlugin/maven-watcher-jdk16/ \
 && rm -f /teamcity-agent/plugins/mavenPlugin/maven-watcher-jdk16/logback-* \
 && rm -fR /root/.m2


RUN useradd -m teamcity \
 && usermod -aG docker teamcity \
 && chown -R teamcity:teamcity /apache-maven /usr/lib/node_modules /teamcity-agent

USER teamcity
EXPOSE 9090
CMD ["/teamcity-agent/bin/agent.sh", "run"]
