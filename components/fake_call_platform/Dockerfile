FROM public.ecr.aws/docker/library/node:lts-alpine

WORKDIR /usr/src/app

COPY package*.json ./

RUN npm install || true

COPY . .

EXPOSE 3000

CMD ["node", "index.js"]
