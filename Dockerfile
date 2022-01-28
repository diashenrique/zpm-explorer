ARG IMAGE=intersystemsdc/iris-community
FROM $IMAGE

USER root   
## add git
RUN apt update && apt-get -y install git
        
WORKDIR /opt/irisbuild
RUN chown ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /opt/irisbuild
USER ${ISC_PACKAGE_MGRUSER}

COPY  src src
COPY Installer.cls Installer.cls
COPY module.xml module.xml
COPY iris.script iris.script

RUN iris start IRIS \
	&& iris session IRIS < iris.script \
    && iris stop IRIS quietly
