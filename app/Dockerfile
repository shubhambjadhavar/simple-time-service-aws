FROM golang:1.24.3-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY .. .
RUN go build -o app-service

FROM alpine:latest
ENV USER=appuser
RUN addgroup -S ${USER} && \
    adduser -S -h /home/${USER} -s /bin/bash -G ${USER} ${USER} && \
    mkdir -p /home/${USER} && \
    chown -R ${USER}:${USER} /home/${USER} && \
    chmod 0711 /home/${USER}
WORKDIR /home/${USER}/
COPY --from=builder /app/app-service /home/${USER}/app-service
USER ${USER}
EXPOSE 8080
CMD ["./app-service"]
