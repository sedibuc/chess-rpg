FROM node:20-slim
WORKDIR /usr/src/app
COPY package.json package-lock.json* pnpm-lock.yaml* yarn.lock* ./
RUN npm install || true
COPY . .
EXPOSE 5173
CMD ["npm", "run", "dev", "--", "--host"]
