# Use the latest foundry image
FROM ubuntu:20.04

# Copy our source code into the container
WORKDIR .

# Build and test the source code
COPY . .
RUN forge build
RUN forge test

# Set entry point and deploy contracts
ENTRYPOINT ["forge", "create"]