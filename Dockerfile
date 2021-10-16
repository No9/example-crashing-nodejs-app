FROM node:14.18.1-buster

USER node

RUN mkdir -p /home/node/app

WORKDIR /home/node/app

COPY --chown=node index.js ./

COPY --chown=node entrypoint.sh ./

RUN chmod +x ./entrypoint.sh

CMD [ "./entrypoint.sh" ]
