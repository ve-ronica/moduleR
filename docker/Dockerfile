############################################################
# Dockerfile to build fruadscore container images
# Based on Ubuntu
############################################################

# Set the base image to Ubuntu
FROM ubuntu

# File Author / Maintainer
MAINTAINER Socure "support@socure.me"

################## BEGIN INSTALLATION ######################

# Set up Logstash repos
#RUN echo 'deb http://packages.elasticsearch.org/logstash/1.5/debian stable main' | sudo tee /etc/apt/sources.list.d/logstash.list
#RUN apt-get install -y wget
#RUN wget -O - http://packages.elasticsearch.org/GPG-KEY-elasticsearch | sudo apt-key add -

# Install RApache module
RUN apt-get install -y software-properties-common
RUN add-apt-repository ppa:opencpu/rapache
RUN apt-get update
RUN apt-get install -y --force-yes libapache2-mod-r-base

# Install Apache web server
RUN apt-get install -y apache2

# Install R packages
RUN Rscript -e 'install.packages("futile.logger", repo="http://cran.rstudio.com/")'
RUN Rscript -e 'install.packages("rjson", repo="http://cran.rstudio.com/")'
RUN Rscript -e 'install.packages("Rook", repo="http://cran.rstudio.com/")'
RUN Rscript -e 'install.packages("gbm", repo="http://cran.rstudio.com/")'

# Remove redundant configuration
RUN rm /etc/apache2/mods-enabled/mpm_event.conf
RUN rm /etc/apache2/mods-enabled/mpm_event.load 
RUN rm /etc/apache2/mods-enabled/mod_R.load 
RUN rm /etc/apache2/sites-enabled/*

# Logstash
#RUN apt-get -y update
#RUN apt-get install -y --fix-missing
#RUN apt-get install -y default-jre-headless
#RUN apt-get install -y logstash
#RUN /opt/logstash/bin/plugin install logstash-filter-alter
#RUN /opt/logstash/bin/plugin install logstash-filter-environment
#RUN usermod -a -G adm logstash
#ADD logstash.conf /etc/logstash/conf.d/
#ADD cacert.pem /etc/logstash/
#RUN chgrp adm /etc/logstash/cacert.pem

# Deep Security Agent
#RUN wget -O /tmp/Agent-Ubuntu_14.04-9.5.3-2754.x86_64.zip http://files.trendmicro.com/products/deepsecurity/en/9.5_SP1/Agent-Ubuntu_14.04-9.5.3-2754.x86_64.zip
#RUN cd /tmp && unzip -q Agent-Ubuntu_14.04-9.5.3-2754.x86_64.zip
#RUN dpkg -i /tmp/Agent-Core-Ubuntu_14.04-9.5.3-2754.x86_64.deb

# Copy config files into image
ADD fraudscore.R          /opt/webservice/
ADD rapache.conf          /opt/webservice/
ADD RSourceOnStartup.R    /opt/webservice/
ADD model                 /opt/webservice/model/
ADD fraudscore.logrotate  /etc/logrotate.d/

# Link to new config
RUN ln -s /opt/webservice/rapache.conf /etc/apache2/sites-enabled/ 

# Driver Script so we can run two daemons (Apache + LogStash)
#ADD dockerstart.sh /
#RUN chmod +x /dockerstart.sh


################## END INSTALLATION ######################
# Expose the default port
EXPOSE 80

# Set default container command
#CMD ["/dockerstart.sh"]
CMD ["-D", "FOREGROUND"]
ENTRYPOINT ["/usr/sbin/apachectl"]


