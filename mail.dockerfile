FROM itsissa/namshi-smtp:4.89-2.deb9u5
LABEL maintainer=Florian.Mayer@dbca.wa.gov.au
LABEL description="namshi-smtp configured for ODK Central mail"

ENV MAILNAME=domain

COPY files/dkim/config.disabled /etc/exim4/_docker_additional_macros/config

# Follow https://docs.getodk.org/central-install-digital-ocean/#configuring-dkim
# to create an RSA keypair.
# Create a configmap with a key "domain.key" and the contents
# of rsa.private as value and map the configmap as volume at /etc/exim4

EXPOSE 25
