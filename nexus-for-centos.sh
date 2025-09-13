#!/bin/bash
set -euxo pipefail

# Variables
NEXUS_USER="nexus"
INSTALL_DIR="/opt/nexus"
DATA_DIR="/data/nexus-data"
NEXUS_VERSION="3.84.0-03"
ARCHIVE="nexus-${NEXUS_VERSION}-linux-x86_64.tar.gz"
DOWNLOAD_URL="https://download.sonatype.com/nexus/3/${ARCHIVE}"
SERVICE_FILE="/etc/systemd/system/nexus.service"
LIMIT_NOFILE=65536

# Redirect all output to a log file
exec > >(tee /var/log/user-data.log) 2>&1

echo "=== Starting Nexus installation via user-data ==="

# Update and install prerequisites
yum update -y


# Create nexus user if needed
if ! id "${NEXUS_USER}" &>/dev/null; then
  useradd --system --no-create-home --shell /sbin/nologin ${NEXUS_USER}
fi

# Prepare directories
mkdir -p "${INSTALL_DIR}"
mkdir -p "${DATA_DIR}"

# Download the confirmed working archive
echo "Downloading Nexus version ${NEXUS_VERSION} from ${DOWNLOAD_URL}..."
cd /tmp
wget -O nexus-${NEXUS_VERSION}.tar.gz "${DOWNLOAD_URL}"
if [ $? -ne 0 ] || [ ! -s nexus-${NEXUS_VERSION}.tar.gz ]; then
  echo "Error: Failed to download Nexus archive."
  exit 1
fi

# Extract
echo "Extracting Nexus..."
tar xzf nexus-${NEXUS_VERSION}.tar.gz
EXTRACTED_DIR="nexus-${NEXUS_VERSION}"
if [ ! -d "${EXTRACTED_DIR}" ]; then
  echo "Error: Expected extracted directory ${EXTRACTED_DIR} does not exist."
  exit 1
fi

# Move contents into INSTALL_DIR

mv "${EXTRACTED_DIR}"/* "${INSTALL_DIR}/"

# Clean up
rm -rf /tmp/nexus-${NEXUS_VERSION}.tar.gz /tmp/${EXTRACTED_DIR}

# Set correct permissions
chown -R ${NEXUS_USER}:${NEXUS_USER} "${INSTALL_DIR}"
chown -R ${NEXUS_USER}:${NEXUS_USER} "${DATA_DIR}"
chmod -R 755 "${INSTALL_DIR}"
restorecon -Rv "${INSTALL_DIR}"

ln -s /opt/nexus/jdk/temurin_17.0.13_11_linux_x86_64/jdk-17.0.13+11/bin/nexus.rc /opt/nexus/bin/nexus.rc

# Setup vmoptions for data directory, logs etc.
VMOPTIONS_FILE="${INSTALL_DIR}/bin/nexus.vmoptions"
if [ ! -f "${VMOPTIONS_FILE}" ]; then
  echo "Error: nexus.vmoptions not found at ${VMOPTIONS_FILE}"
  exit 1
fi
cp "${VMOPTIONS_FILE}" "${VMOPTIONS_FILE}.orig"

grep -q "Dkaraf.data=${DATA_DIR}/nexus3" "${VMOPTIONS_FILE}" || cat <<EOF >> "${VMOPTIONS_FILE}"
-Dkaraf.data=${DATA_DIR}/nexus3
-Djava.io.tmpdir=${DATA_DIR}/nexus3/tmp
-XX:LogFile=${DATA_DIR}/nexus3/log/jvm.log
EOF

# Create systemd service file
cat <<EOF > "${SERVICE_FILE}"
[Unit]
Description=Sonatype Nexus Repository
After=network.target

[Service]
Type=forking
LimitNOFILE=${LIMIT_NOFILE}
User=${NEXUS_USER}
Group=${NEXUS_USER}
ExecStart=${INSTALL_DIR}/bin/nexus start
ExecStop=${INSTALL_DIR}/bin/nexus stop
Restart=on-failure
RestartSec=10
TimeoutStartSec=600
Environment=JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))

[Install]
WantedBy=multi-user.target
EOF

# Reload and start service
systemctl daemon-reload
systemctl enable nexus.service
systemctl start nexus.service

# Wait and show status
sleep 30
systemctl status nexus.service --no-pager

echo "=== Nexus installation complete ==="
