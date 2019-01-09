#
# Ubuntu Dockerfile
#
# https://github.com/dockerfile/ubuntu
#

# Pull base image.
FROM ubuntu:18.04

# Install.
RUN \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y build-essential && \
  apt-get install -y software-properties-common && \
  apt-get install -y git libgnat-7 && \
  apt-get install -y gnat zlib1g-dev && \
  apt-get autoremove && apt-get clean && \
  rm -rf /var/lib/apt/lists/* && \
  git clone --single-branch --branch ghdl-0.35 https://github.com/ghdl/ghdl.git && cd ghdl && \
  ./configure --prefix=/usr/local && \
  make -j9  && \
  make install  && \
  cd .. && \
  rm -rf ghdl && \
  apt-get -y --purge remove build-essential gnat zlib1g-dev && \
  apt-get -y --purge autoremove && \
  echo OK

# Add files.
#ADD root/.bashrc /root/.bashrc
#ADD root/.gitconfig /root/.gitconfig
#ADD root/.scripts /root/.scripts

# Set environment variables.
ENV HOME /root

# Define working directory.
WORKDIR /root

# Define default command.
CMD ["bash"]

