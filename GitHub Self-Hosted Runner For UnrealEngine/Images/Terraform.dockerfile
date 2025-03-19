# Use Terraform as the base image
FROM hashicorp/terraform:1.9.8

# Install necessary tools: jq, iprange, curl, bash
RUN apk add --no-cache jq iprange curl bash

# Set default working directory
WORKDIR /workspace

# Ensure bash is the default shell
ENTRYPOINT ["/bin/bash"]