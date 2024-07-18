FROM ubuntu:22.04

ARG regina_url_prefix=https://sourceforge.net/projects/regina-rexx/files/regina-rexx/3.9.5
ARG regina_bin_deb=regina-rexx_3.9.5-2_amd64-Debian-11.deb
ARG regina_lib_deb=libregina3_3.9.5-2_amd64-Debian-11.deb

# Coreutils assumed installed
# jq required
# Regina binary and library required
RUN apt-get update                                                         && \
    apt-get install -y curl jq                                             && \
    curl -sLk ${regina_url_prefix}/${regina_lib_deb} > ./${regina_lib_deb} && \
    curl -sLk ${regina_url_prefix}/${regina_bin_deb} > ./${regina_bin_deb} && \
    apt-get install -y ./${regina_lib_deb}                                 && \
    apt-get install -y ./${regina_bin_deb}                                 && \
    apt-get purge --auto-remove -y                                         && \
    apt-get clean                                                          && \
    rm -rf /var/lib/apt/lists/*

COPY . /opt/test-runner
WORKDIR /opt/test-runner
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
