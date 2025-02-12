# start from a base ubuntu image
FROM ubuntu:bionic
MAINTAINER Cass Johnston <cassjohnston@gmail.com>

# set users cfg file
ARG USERS_CFG=users.json

# Install pre-reqs
RUN apt-get update
RUN apt-get install -y curl vim sudo wget rsync
RUN apt-get install -y apache2
RUN apt-get install -y python
RUN apt-get install -y python-pip
RUN apt-get install -y supervisor
RUN apt-get install -y git
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Fetch  brat
RUN mkdir /var/www/brat
RUN curl http://weaver.nlplab.org/~brat/releases/brat-v1.3_Crunchy_Frog.tar.gz > /var/www/brat/brat-v1.3_Crunchy_Frog.tar.gz 
RUN cd /var/www/brat && tar -xvzf brat-v1.3_Crunchy_Frog.tar.gz

# create a symlink so users can mount their data volume at /bratdata rather than the full path
RUN mkdir /bratdata && mkdir /bratcfg && mkdir /work
RUN chown -R www-data:www-data /bratdata /bratcfg /work
RUN chmod o-rwx /bratdata /bratcfg
RUN ln -s /bratdata /var/www/brat/brat-v1.3_Crunchy_Frog/data
RUN ln -s /bratcfg /var/www/brat/brat-v1.3_Crunchy_Frog/cfg
RUN ln -s /work /var/www/brat/brat-v1.3_Crunchy_Frog/work

# And make that location a volume
VOLUME /bratdata
VOLUME /bratcfg
VOLUME /work

ADD brat_install_wrapper.sh /usr/bin/brat_install_wrapper.sh
RUN chmod +x /usr/bin/brat_install_wrapper.sh

# Make sure apache can access it
RUN chown -R www-data:www-data /var/www/brat/brat-v1.3_Crunchy_Frog/

ADD 000-default.conf /etc/apache2/sites-available/000-default.conf

# Install simstring for normalization feature
RUN pip install git+git://github.com/vitalco/simstring-python-package#egg=simstring

# add the user patching script
ADD user_patch.py /var/www/brat/brat-v1.3_Crunchy_Frog/user_patch.py

# Enable cgi
RUN a2enmod cgi

EXPOSE 80

# We can't use apachectl as an entrypoint because it starts apache and then exits, taking your container with it. 
# Instead, use supervisor to monitor the apache process
RUN mkdir -p /var/log/supervisor

ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

CMD ["/usr/bin/supervisord"]





