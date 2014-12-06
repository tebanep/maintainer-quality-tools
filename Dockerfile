FROM ubuntu:14.04

# MAINTAINER "Vauxoo"

#  Fix http://stackoverflow.com/questions/22466255/is-it-possibe-to-answer-dialog-questions-when-installing-under-docker
ENV DEBIAN_FRONTEND noninteractive

ENV PYTHONIOENCODING utf-8

#  Basic configuration for a CI image
RUN echo 'APT::Get::Assume-Yes "true";' >> /etc/apt/apt.conf \
    && echo 'APT::Get::force-yes "true";' >> /etc/apt/apt.conf

#  Fix log odoo warning "unable to set lang fr_FR"
RUN locale-gen fr_FR \
    && locale-gen en_US.UTF-8 \
    && dpkg-reconfigure locales \
    && update-locale LANG=en_US.UTF-8 \
    && update-locale LC_ALL=en_US.UTF-8 \
    && echo 'LANG="en_US.UTF-8"' > /etc/default/locale

#  Update and upgrade
RUN apt-get update -q && apt-get upgrade -q

#  Installing basic OS package
RUN apt-get install --allow-unauthenticated -q bzr \
    python \
    python-dev \
    python-setuptools \
    git \
    vim \
    nano \
    wget \
    tmux \
    htop

#  Installing basic dev packages
RUN apt-get install --allow-unauthenticated -q libssl-dev \
    libyaml-dev \
    libjpeg-dev \
    libgeoip-dev \
    libffi-dev \
    libqrencode-dev \
    libfreetype6-dev \
    zlib1g-dev \
    libpq-dev

#  Installing postgres
RUN apt-get install --allow-unauthenticated -q postgresql-9.3 \
    postgresql-contrib-9.3 \
    postgresql-client-9.3

#  Fix http://www.nigeldunn.com/2011/05/14/ubuntu-11-04-libjpeg-so-libpng-so-php-installation-issues/
RUN ln -s /usr/include/freetype2 /usr/local/include/freetype \
    && ln -s /usr/lib/x86_64-linux-gnu/libjpeg.so /usr/lib/ \
    && ln -s /usr/lib/x86_64-linux-gnu/libfreetype.so /usr/lib/ \
    && ln -s /usr/lib/x86_64-linux-gnu/libz.so /usr/lib/

#  Installing pip
RUN apt-get install python-pip

#  Add git config data to root user
RUN git config --global user.name oca_docker \
    && git config --global user.email hello@oca.com

#  Fix shippable key issue on start postgresql - https://github.com/docker/docker/issues/783#issuecomment-56013588
RUN mkdir -p /etc/ssl/private-copy \
        && mkdir -p /etc/ssl/private \
        && mv /etc/ssl/private/* /etc/ssl/private-copy/ \
        && rm -rf /etc/ssl/private \
        && mv /etc/ssl/private-copy /etc/ssl/private \
        && chmod -R 0700 /etc/ssl/private \
        && chown -R postgres /etc/ssl/private

#  Create postgres role to root
RUN su - postgres /etc/init.d/postgresql start \
    && su - postgres -c 'psql -c "CREATE ROLE root LOGIN SUPERUSER INHERIT CREATEDB CREATEROLE;"'

ADD * /tmp/

#  Installing basic odoo dependencies
RUN WITHOUT_ODOO=1 SHIPPABLE="true" WITHOUT_DEPENDENCIES="" /tmp/travis_install_nightly

#  Setting global env for next shippable build
ENV WITHOUT_DEPENDENCIES 1
