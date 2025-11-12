FROM node:18-alpine as builder

# Accept build argument for API URL
ARG REACT_APP_API_URL=http://56.228.10.255:5000/api
ENV REACT_APP_API_URL=$REACT_APP_API_URL

WORKDIR /app

COPY package*.json ./
RUN npm install --only=production

COPY . .
RUN npm run build

FROM nginx:alpine

# Copy built app
COPY --from=builder /app/build /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Remove user switching - run as root in container (safe in Docker)
# USER nginx  ← REMOVE THIS LINE

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]