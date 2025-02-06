FROM debian:stable-slim as spamassassin-builder

RUN apt-get -qy update && apt-get -qy upgrade
RUN apt-get -qy install build-essential make libssl-dev libxml2-dev perl-base libperl-dev razor pyzor
RUN apt-get -qy install cpanminus libidn2-dev libidn-dev
RUN apt-get -qy install zlib1g-dev
RUN cpanm MIME::Base64 
RUN cpanm Encode::Detect::Detector
RUN cpanm Net::LibIDN2
RUN cpanm Net::LibIDN 
RUN cpanm Email::Address::XS
RUN cpanm Mail::DKIM
RUN cpanm Mail::SPF
RUN cpanm IO::Socket::SSL
RUN cpanm Mail::DMARC
RUN cpanm IO::Socket::IP
RUN cpanm Net::Patricia
RUN cpanm Archive::Zip
RUN cpanm IO::String

RUN cpanm -n -v --no-interactive --no-prompt  Mail::SpamAssassin

RUN apt-get -qy install wget curl tini

ADD scripts/entryPoint.sh /entryPoint.sh
RUN chmod a+x /entryPoint.sh

# add a user for running rss2email in the container
RUN adduser -u 4534 --disabled-login spamassassin

RUN chown -R spamassassin:spamassassin /etc/mail/spamassassin/
RUN mkdir -p /var/lib/spamassassin && chown -R spamassassin:spamassassin /var/lib/spamassassin
COPY config/* /etc/mail/spamassassin/
RUN chown -R spamassassin:spamassassin /etc/mail/spamassassin/

USER spamassassin

RUN sa-update

ENTRYPOINT ["/usr/bin/tini", "--", "/entryPoint.sh"]

