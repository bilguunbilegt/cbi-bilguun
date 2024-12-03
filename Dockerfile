# Stage 1: Build the Go application
FROM golang:1.17-alpine AS go-builder
ENV PORT 8080
ENV HOSTDIR 0.0.0.0

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod tidy
COPY . .
RUN go build -o /main

# Stage 2: Set up Python environment
FROM python:3.9-slim AS python-env

# Install Python dependencies
RUN apt-get update && apt-get install -y libpq-dev && \
    pip install --no-cache-dir pandas sqlalchemy psycopg2 prophet dash plotly

WORKDIR /app

# Copy Python scripts
COPY forecasting.py .
COPY app.py .

# Stage 3: Final multi-service container
FROM alpine:latest
RUN apk add --no-cache bash

# Copy Go binary
COPY --from=go-builder /main /main

# Copy Python environment and scripts
COPY --from=python-env /app /app
COPY --from=python-env /usr/local/lib/python3.9 /usr/local/lib/python3.9
COPY --from=python-env /usr/local/bin/python3.9 /usr/local/bin/python3.9
COPY --from=python-env /usr/local/bin/pip /usr/local/bin/pip

WORKDIR /app

# Expose necessary ports
EXPOSE 8080 8050

# Entry point to run both Go and Python services
CMD ["bash", "-c", "/main & python3 app.py"]
