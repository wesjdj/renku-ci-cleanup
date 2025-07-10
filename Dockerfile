# Build stage
FROM golang:1.24-alpine AS builder

# Install git and other build dependencies
RUN apk add --no-cache git make bash

# Set working directory
WORKDIR /app

# Clone the renku-dev-utils repository
RUN git clone https://github.com/SwissDataScienceCenter/renku-dev-utils.git .

# Build the rdu binary
RUN make rdu

# Runtime stage
FROM alpine:3.18

# Install kubectl, bash, and other required tools
RUN apk add --no-cache \
    bash \
    curl \
    ca-certificates \
    jq \
    openssl \
    && ARCH=$(case $(uname -m) in x86_64) echo amd64;; aarch64) echo arm64;; *) echo amd64;; esac) \
    && curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/

# Install Helm
RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
    && chmod 700 get_helm.sh \
    && ./get_helm.sh \
    && rm get_helm.sh

# Copy the rdu binary from builder stage
COPY --from=builder /go/bin/rdu /usr/local/bin/rdu

# Make rdu executable
RUN chmod +x /usr/local/bin/rdu

# Create a non-root user
RUN addgroup -g 1000 appuser && \
    adduser -u 1000 -G appuser -s /bin/bash -D appuser

# Switch to non-root user
USER appuser

# Set working directory
WORKDIR /home/appuser

# Verify installations
RUN rdu version || echo "rdu installed" && \
    kubectl version --client && \
    helm version

# Default command
CMD ["/bin/bash"]