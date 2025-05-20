FROM swift:6.1

# Install D-Bus dependencies
RUN apt-get update && apt-get install -y \
    libdbus-1-dev \
    dbus \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set up D-Bus system bus
RUN mkdir -p /var/run/dbus
RUN dbus-daemon --system --fork

# Create a working directory
WORKDIR /app

# Copy the Swift package
COPY . .

# Build and test
CMD ["swift", "test"]
