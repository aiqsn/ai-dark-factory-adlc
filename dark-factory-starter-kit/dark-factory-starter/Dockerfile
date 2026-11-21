# Container image for Google Cloud Run and Azure Container Apps (deploy-gcp.yml, deploy-azure.yml).
# The app has no runtime dependencies, so nothing is installed: the image is the Node base plus src/.
FROM node:22-alpine
WORKDIR /app
ENV NODE_ENV=production PORT=8080
COPY package.json ./
COPY src ./src
USER node
EXPOSE 8080
CMD ["node", "src/server.js"]
