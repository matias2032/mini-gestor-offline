# C:\mini\Dockerfile  (raiz do repositorio, ao lado de license_server\ e admin_panel\)
#
# Um unico servico: o painel React e compilado e copiado para dentro do JAR do Spring
# (src/main/resources/static), por isso o Spring serve a API e o painel na mesma origem.
# O contexto de build tem de ser a RAIZ do repo (no Render: Root Directory vazio),
# senao o Docker nao ve a pasta admin_panel.

# ---------- 1. Painel React ----------
FROM node:22-alpine AS panel
WORKDIR /panel
COPY admin_panel/package.json admin_panel/package-lock.json ./
RUN npm ci
COPY admin_panel/ ./
# "npm run build" corre tsc -b: qualquer erro de TypeScript falha o build
RUN npm run build

# ---------- 2. Servidor Spring (com o painel dentro) ----------
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY license_server/pom.xml ./
RUN mvn -B -q dependency:go-offline
COPY license_server/src src
# Nunca empacotar a configuracao local (tem a chave de dev)
RUN rm -f src/main/resources/application-local.yaml
COPY --from=panel /panel/dist src/main/resources/static
RUN mvn -B -q -DskipTests package

# ---------- 3. Imagem final ----------
FROM eclipse-temurin:21-jre-alpine
RUN addgroup -S app && adduser -S app -G app
WORKDIR /app
COPY --from=build /app/target/license_server-0.0.1-SNAPSHOT.jar app.jar
USER app

ENV SPRING_PROFILES_ACTIVE=prod
# Instancia pequena (512 MB no Free/Starter): GC simples e arranque mais rapido
ENV JAVA_TOOL_OPTIONS="-XX:+UseSerialGC -XX:TieredStopAtLevel=1 -XX:MaxRAMPercentage=70"

# A porta vem da variavel PORT que o Render define (application-prod.yaml: PORT:8080)
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]