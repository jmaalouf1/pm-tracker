FROM node:20-alpine
WORKDIR /app
COPY package.json package-lock.json* /app/
RUN npm ci || npm install
COPY . /app
EXPOSE 8080
CMD ["node","src/server.js"]
