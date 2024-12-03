# Stage 1: Build the Go application
FROM golang:1.17-alpine AS go-builder
WORKDIR /app

# Install Go dependencies
COPY go.mod go.sum ./
RUN go mod tidy

# Copy and build the application
COPY . ./
RUN go build -o /main

# Stage 2: Set up Python environment
FROM python:3.9-slim AS python-env

# Install system dependencies for Prophet and other libraries
RUN apt-get update && apt-get install -y \
    libpq-dev gcc g++ make && \
    pip install --no-cache-dir pandas sqlalchemy psycopg2 prophet dash plotly

WORKDIR /app

# Copy Python scripts
COPY covid_forecasting.py .
COPY covid_dashboard.py .
COPY app.py .

# Stage 3: Final multi-service container
FROM alpine:latest

# Install Bash and dependencies
RUN apk add --no-cache bash libstdc++ libgcc

# Copy Go binary
COPY --from=go-builder /main /main

# Copy Python environment and scripts
COPY --from=python-env /usr/local /usr/local
COPY --from=python-env /app /app

WORKDIR /app

# Expose necessary ports
EXPOSE 8080 8050

# Entry point to run both Go and Python services
CMD ["bash", "-c", "/main & python3 app.py"]
