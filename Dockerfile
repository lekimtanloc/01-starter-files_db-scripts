FROM alpine:latest

RUN apk add --no-cache mysql-client bash

WORKDIR /init

COPY sql/ /init/sql/
COPY wait-for-mysql-and-init.sh /init/wait-for-mysql-and-init.sh

RUN chmod +x /init/wait-for-mysql-and-init.sh

CMD ["/init/wait-for-mysql-and-init.sh"]
