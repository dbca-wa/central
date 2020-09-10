FROM itsissa/namshi-smtp:4.89-2.deb9u5
LABEL maintainer=Florian.Mayer@dbca.wa.gov.au
LABEL description="namshi-smtp configured for ODK Central mail"

ENV MAILNAME

COPY files/dkim/config /etc/exim4/_docker_additional_macros
COPY files/dkim/rsa.private /etc/exim4/domain.key

EXPOSE 25
