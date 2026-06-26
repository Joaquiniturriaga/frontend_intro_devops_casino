FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

FROM nginxinc/nginx-unprivileged:1.27-alpine AS runtime

COPY --from=builder --chown=nginx:nginx /app/dist/casino-frontend/browser/. /usr/share/nginx/html/
COPY --chown=nginx:nginx default.conf.template /etc/nginx/templates/default.conf.template

USER nginx
EXPOSE 8080

#FROM node:20-alphine AS builder
#Primera epata del multi-stage build Usa node:20-alpine por que necesitas node.js para compilar angular el as builder le da 
#El nombre a esta etapa para referenciarla despues alpine es una distro linux minimalista (5mb bs 100 de debian) menos peso,, 
#Menos superficie de ataque

#WORKDIR /app
#Define el directorio de trabajo dentro del contenedor, Todo lo que venga despues COPY, RUN se ejecuta desde /app si no existiera, docker 
#lo crea

#COPY . .Y npm ci
#Aqui tenemos una decision muy importante de optimizacion de cache docker, copiamos primero los package.json (no el codigo fuente) y corremos 
#npm ci ¿Por que? por que las capas docker se cachean, si tu codigo cambia pero package.json no cambio docker reutiliza la capa de dependencias
#sin reinstalar nada npm ci en vez de npm install por que es determinista instala exacatamente lo que dice package-lock,json sin resolver versiones, ideal para CI

#COPY . . RUN npm run build
#copiamos todo el codigo fuente con from y esto genera archivos estaticos en app/dist/casino-frontend/browser va despues de instlar dependencias
#por la razon del cache que hablamos arriba

