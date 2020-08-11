FROM nginx:latest
ARG nginx_uid=1001
ARG nginx_port=8000

RUN groupadd -g ${nginx_uid} appuser && \
  useradd -r -u ${nginx_uid} -g appuser appuser && \
  mkdir -p /opt/nginx/ && \
  chown -R appuser:appuser /opt/nginx && \
  mkdir -p /var/cache/nginx && \
  chown -R appuser:appuser /var/cache/nginx && \
  mkdir -p /etc/nginx/ && \
  chown -R appuser:appuser /etc/nginx/ && \
  mkdir -p /app && \
  chown -R appuser:appuser /app

COPY --chown=appuser:appuser nginx.conf /etc/nginx/nginx.conf
USER appuser
WORKDIR /app
EXPOSE ${nginx_port}
CMD ["nginx", "-g", "daemon off;"]
