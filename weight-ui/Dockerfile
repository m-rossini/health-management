# Stage 1: Build stage
FROM node:latest AS build

# Set the working directory
WORKDIR /app
 
# Copy package.json and package-lock.json
COPY package.json ./

# Install dependencies
RUN npm install && npm install -g typescript && npm install -g webpack webpack-cli && npm install source-map-loader --save-dev
RUN npm install datatables.net-dt && npm install --save datatables.net-colreorder-dt && npm install --save datatables.net-responsive-dt
# Copy the rest of the application
COPY . .

# Build the application
RUN npm run build

# Stage 2: Serve stage
FROM nginx

# Copy the built files from the build stage
COPY --from=build /app/public /usr/share/nginx/html/
COPY --from=build /app/src/config-dev.json /usr/share/nginx/html/config.json
# COPY --from=build /app/src/index.* /usr/share/nginx/html
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf

# Expose the port the app runs on
EXPOSE 8080

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
