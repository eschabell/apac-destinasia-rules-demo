# Use jbossdemocentral/developer as the base
FROM jbossdemocentral/developer

# Maintainer details
MAINTAINER Andrew Block, Eric D. Schabell

# Environment Variables 
ENV BRMS_HOME /opt/jboss/brms/jboss-eap-7.0
ENV BRMS_VERSION_MAJOR 6
ENV BRMS_VERSION_MINOR 4
ENV BRMS_VERSION_MICRO 0
ENV BRMS_VERSION_PATCH GA

ENV EAP_VERSION_MAJOR 7
ENV EAP_VERSION_MINOR 0
ENV EAP_VERSION_MICRO 0

ENV EAP_INSTALLER=jboss-eap-$EAP_VERSION_MAJOR.$EAP_VERSION_MINOR.$EAP_VERSION_MICRO-installer.jar
ENV BRMS_DEPLOYABLE=jboss-brms-$BRMS_VERSION_MAJOR.$BRMS_VERSION_MINOR.$BRMS_VERSION_MICRO.$BRMS_VERSION_PATCH-deployable-eap7.x.zip

# ADD Installation and Management Files
COPY support/installation-eap support/installation-eap.variables installs/$BRMS_DEPLOYABLE installs/$EAP_INSTALLER support/fix-permissions /opt/jboss/

# Update Permissions on Installers
USER root
RUN usermod -g root jboss \
  && chown 1000:1000 /opt/jboss/$EAP_INSTALLER /opt/jboss/$BRMS_DEPLOYABLE /opt/jboss/fix-permissions \
  && chmod +x /opt/jboss/fix-permissions

# Prepare and run installer and cleanup installation components
RUN sed -i "s:<installpath>.*</installpath>:<installpath>$BRMS_HOME</installpath>:" /opt/jboss/installation-eap \
	  && java -jar /opt/jboss/$EAP_INSTALLER /opt/jboss/installation-eap -variablefile /opt/jboss/installation-eap.variables \
    && unzip -qo /opt/jboss/$BRMS_DEPLOYABLE  -d $BRMS_HOME/.. \
    && /opt/jboss/fix-permissions $BRMS_HOME \
    && rm -rf /opt/jboss/$BRMS_DEPLOYABLE /opt/jboss/$EAP_INSTALLER /opt/jboss/installation-eap /opt/jboss/installation-eap.variables $BRMS_HOME/standalone/configuration/standalone_xml_history/  \
    && $BRMS_HOME/bin/add-user.sh -a -r ApplicationRealm -u erics -p jbossbrms1! -ro analyst,admin,manager,user,kie-server,kiemgmt,rest-all --silent

# Add support files
COPY support/brms-demo-niogit $BRMS_HOME/bin/.niogit
COPY support/standalone.xml $BRMS_HOME/standalone/configuration/
COPY support/userinfo.properties $BRMS_HOME/standalone/deployments/business-central.war/WEB-INF/classes/
COPY support/start.sh /opt/jboss/

# Fix permissions on support files
RUN chown -R 1000:root $BRMS_HOME \
    &&/opt/jboss/fix-permissions $BRMS_HOME/standalone/configuration/standalone.xml \
    && /opt/jboss/fix-permissions $BRMS_HOME/standalone/deployments/business-central.war/WEB-INF/classes/userinfo.properties \
    && /opt/jboss/fix-permissions $BRMS_HOME/bin/.niogit \
    && /opt/jboss/fix-permissions /opt/jboss/start.sh \
    && /opt/jboss/fix-permissions /etc/passwd \
    && /opt/jboss/fix-permissions /etc/group \
    && /opt/jboss/fix-permissions /opt/jboss/.m2 \
    && chmod +x /opt/jboss/start.sh

# Run as JBoss 
USER 1000

# Expose Ports, 9481 is to allow for cloning of BRMS repos.
EXPOSE 9990 9999 8080 9418 8001

# Helper script
ENTRYPOINT ["/opt/jboss/start.sh"]
