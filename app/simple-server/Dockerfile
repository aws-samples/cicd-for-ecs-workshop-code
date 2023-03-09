FROM public.ecr.aws/docker/library/node:buster-slim
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install
RUN apt -y update && apt -y upgrade
RUN apt -y install curl
COPY . .
EXPOSE 80
CMD ["node", "server.js"]
