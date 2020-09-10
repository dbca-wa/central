FROM redis:5
LABEL maintainer=Florian.Mayer@dbca.wa.gov.au
LABEL description="redis:5 configured for ODK Central enketo_redis_main"

COPY files/enketo/redis-enketo-main.conf /usr/local/etc/redis/redis.conf

EXPOSE 6379

CMD redis-server /usr/local/etc/redis/redis.conf
