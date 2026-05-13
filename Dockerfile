# ──────────────────────────────────────────────────────────────
# ETAPA 1 — builder: compila Angular
# ──────────────────────────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

# Copiar manifiestos primero para aprovechar cache de Docker
# Si package.json no cambia, npm ci no se vuelve a ejecutar
COPY package*.json ./
RUN npm ci

# Copiar el resto del codigo y compilar para produccion
COPY . .
RUN npm run build
# Salida: dist/casino-frontend/browser/

# ──────────────────────────────────────────────────────────────
# ETAPA 2 — runtime: Nginx sirve los estaticos
# La imagen final NO tiene Node ni npm (multi-stage)
# ──────────────────────────────────────────────────────────────
FROM nginx:alpine AS runtime

# Limpiar archivos default de Nginx para no tener conflictos
RUN rm -rf /usr/share/nginx/html/* \
 && rm -f /etc/nginx/conf.d/default.conf

# Template de configuracion con reverse proxy
# nginx:alpine ejecuta envsubst sobre *.template al arrancar
# y genera /etc/nginx/conf.d/default.conf con las variables resueltas
COPY default.conf.template /etc/nginx/templates/default.conf.template

# Copiar estaticos compilados de Angular
# El "/." final copia el CONTENIDO de browser/, no la carpeta
COPY --from=builder /app/dist/casino-frontend/browser/. /usr/share/nginx/html/

EXPOSE 80

# nginx:alpine ya corre como root en puerto 80 por defecto
# nginxinc/nginx-unprivileged corre en 8080 sin root (alternativa mas segura)