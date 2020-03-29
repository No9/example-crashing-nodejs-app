FROM node:12.16-buster

USER node

# Create app directory (with user `node`)
RUN mkdir -p /home/node/app

WORKDIR /home/node/app

COPY --chown=node index.js ./

COPY --chown=node entrypoint.sh ./

RUN chmod +x ./entrypoint.sh

# Bind to all network interfaces so that it can be mapped to the host OS
ENV HOST=0.0.0.0 PORT=3000

EXPOSE ${PORT}

CMD [ "./entrypoint.sh" ]






