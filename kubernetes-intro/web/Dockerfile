FROM nginx:latest
ARG nginx_uid=1001
ARG nginx_gid=33
RUN usermod -u ${nginx_uid} -o nginx && groupmod -g ${nginx_gid} -o nginx
COPY nginx.conf /etc/nginx/nginx.conf
WORKDIR /app
USER ${UID}
