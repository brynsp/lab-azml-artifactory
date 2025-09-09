#!/usr/bin/env bash
# Robust, idempotent Artifactory OSS install script (clean rewrite)
set -Eeuo pipefail
trap 'echo "[artifactory-setup][ERROR] line $LINENO exit $?: $(sed -n "${LINENO}p" "$0")" >&2' ERR

ARTI_VERSION="${ARTI_VERSION:-7.77.3}"          # override with env if desired
ARTI_IMAGE_PRIMARY="releases-docker.jfrog.io/jfrog/artifactory-oss:${ARTI_VERSION}"
ARTI_IMAGE_ALT="docker.io/jfrog/artifactory-oss:${ARTI_VERSION}"
DATA_DIR="/opt/artifactory/data"
COMPOSE_DIR="/opt/artifactory"
COMPOSE_FILE="${COMPOSE_DIR}/docker-compose.yml"
SERVICE_FILE="/etc/systemd/system/artifactory.service"
FORCE_REWRITE="${FORCE_REWRITE:-0}"
NO_SYSTEMD="${NO_SYSTEMD:-0}"
CLEAN_BOOT="${CLEAN_BOOT:-0}"            # if 1, backup & recreate data dir before start (fresh bootstrap)
USE_NAMED_VOLUME="${USE_NAMED_VOLUME:-0}" # if 1, use a docker named volume instead of host bind mount

# Memory tuning (respect explicit user values; auto-tune only if defaults used)
_DEFAULT_XMS=256m
_DEFAULT_XMX=1024m
JAVA_XMS="${JAVA_XMS:-${_DEFAULT_XMS}}"
JAVA_XMX="${JAVA_XMX:-${_DEFAULT_XMX}}"
if free -m >/dev/null 2>&1; then
  total_mem=$(free -m | awk '/Mem:/ {print $2}')
  if [ "$total_mem" -ge 7800 ] && [ -z "${JAVA_TUNED:-}" ] && [ "$JAVA_XMS" = "${_DEFAULT_XMS}" ] && [ "$JAVA_XMX" = "${_DEFAULT_XMX}" ]; then
    JAVA_XMS="512m"; JAVA_XMX="2048m"; JAVA_TUNED=1
  fi
fi

# Detect a primary non-root login user (overrideable via PRIMARY_USER or ADMIN_NAME env)
if [ -n "${ADMIN_NAME:-}" ] && [ -z "${PRIMARY_USER:-}" ]; then
  PRIMARY_USER="$ADMIN_NAME"
fi
PRIMARY_USER="${PRIMARY_USER:-}"
if [ -z "$PRIMARY_USER" ]; then
  for d in /home/*; do
    [ -d "$d" ] || continue
    b=$(basename "$d")
    # ignore common service/system dirs if any show up
    case "$b" in
      labadmin|ubuntu|azureuser|admin|user|ec2-user|debian) PRIMARY_USER="$b"; break;;
      *) PRIMARY_USER="$b"; break;;
    esac
  done
fi
PRIMARY_USER=${PRIMARY_USER:-root}
PRIMARY_HOME="/home/${PRIMARY_USER}"
if [ "$PRIMARY_USER" = "root" ]; then
  PRIMARY_HOME="/root"
fi

log(){ printf '[artifactory-setup] %s\n' "$*"; }

require_root(){ [ "$(id -u)" -eq 0 ] || { echo "Run as root (use sudo)." >&2; exit 1; }; }
require_root

ensure_deps(){
  if ! command -v docker >/dev/null 2>&1; then
    log "Installing Docker engine + dependencies"
    apt-get update -y
    DEBIAN_FRONTEND=noninteractive apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release jq
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
    apt-get update -y
    DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  usermod -aG docker "$PRIMARY_USER" 2>/dev/null || true
    systemctl enable docker --now
  fi
  command -v curl >/dev/null || apt-get install -y curl
}

write_compose(){
  mkdir -p "$COMPOSE_DIR"
  if [ "$USE_NAMED_VOLUME" != "1" ]; then
    mkdir -p "$DATA_DIR"
    chown -R 1030:1030 "$DATA_DIR" || true
  fi
  if [ ! -f "$COMPOSE_FILE" ] || [ "$FORCE_REWRITE" = "1" ]; then
  [ "$FORCE_REWRITE" = "1" ] && rm -f "$COMPOSE_FILE"
    local img="$ARTI_IMAGE_PRIMARY"
    log "Writing compose file (force=$FORCE_REWRITE)"
    cat >"$COMPOSE_FILE" <<EOF
services:
  artifactory:
    image: "$img"
    container_name: artifactory
    restart: unless-stopped
    ports:
      - "8082:8082"
      - "8081:8081"
    environment:
      - JF_SHARED_DATABASE_TYPE=derby
      - EXTRA_JAVA_OPTIONS=-Xms${JAVA_XMS} -Xmx${JAVA_XMX}
    volumes:
$( if [ "$USE_NAMED_VOLUME" = "1" ]; then echo "      - artifactory_data:/var/opt/jfrog/artifactory"; else echo "      - ${DATA_DIR}:/var/opt/jfrog/artifactory"; fi )
    ulimits:
      nofile:
        soft: 32000
        hard: 40000
      nproc: 65535
EOF
    if [ "$USE_NAMED_VOLUME" = "1" ]; then
      printf '\nvolumes:\n  artifactory_data:\n' >> "$COMPOSE_FILE"
    fi
  fi
}

clean_boot_if_requested(){
  if [ "$CLEAN_BOOT" != "1" ]; then return 0; fi
  if [ "$USE_NAMED_VOLUME" = "1" ]; then
    log "CLEAN_BOOT=1 with USE_NAMED_VOLUME=1: removing docker volume if exists"
    docker volume rm -f artifactory_data 2>/dev/null || true
  elif [ -d "$DATA_DIR" ]; then
    local ts backup
    ts=$(date +%Y%m%d-%H%M%S)
    backup="${DATA_DIR}.bak-${ts}"
    log "CLEAN_BOOT=1: backing up existing data dir to $backup and recreating fresh"
    systemctl stop artifactory.service 2>/dev/null || true
    docker compose -f "$COMPOSE_FILE" down 2>/dev/null || true
    mv "$DATA_DIR" "$backup"
  fi
  if [ "$USE_NAMED_VOLUME" != "1" ]; then
    mkdir -p "$DATA_DIR"
    chown -R 1030:1030 "$DATA_DIR" || true
  fi
}

validate_compose(){
  log "Validating compose syntax"
  if ! docker compose -f "$COMPOSE_FILE" config >/dev/null 2> /tmp/compose_validate.err; then
    log "Initial validation failed; attempting automatic remediation"
    # Show diagnostics
    log "---- compose file (numbered) ----"
    nl -ba "$COMPOSE_FILE" | sed -n '1,120p'
    log "---- visible characters ----"
    sed -n '1,120p' "$COMPOSE_FILE" | sed -n l
    log "---- error output ----"
    cat /tmp/compose_validate.err || true
    # Try alternate image registry replacement
    if grep -q "docker.io/jfrog/artifactory-oss" "$COMPOSE_FILE"; then
      log "Switching to alternate image registry"
      sed -i "s|docker.io/jfrog/artifactory-oss:${ARTI_VERSION}|${ARTI_IMAGE_ALT}|" "$COMPOSE_FILE"
    fi
    # Strip any CR characters & tabs which can break YAML
    tr -d '\r' < "$COMPOSE_FILE" | sed $'s/\t/  /g' > "${COMPOSE_FILE}.san" && mv "${COMPOSE_FILE}.san" "$COMPOSE_FILE"
  # Repair any literal escaped newline artifacts from older versions
  sed -i 's/volumes:\\n/volumes:/g' "$COMPOSE_FILE"
  # Repair any lingering backslash space in EXTRA_JAVA_OPTIONS
  sed -i 's/EXTRA_JAVA_OPTIONS=-Xms\([0-9a-zA-Z]*\)\\ -Xmx/EXTRA_JAVA_OPTIONS=-Xms\1 -Xmx/g' "$COMPOSE_FILE"
    log "Re-validating after sanitation"
    docker compose -f "$COMPOSE_FILE" config >/dev/null
  fi
}

start_stack(){
  log "Pulling image (primary: $ARTI_IMAGE_PRIMARY)"
  if ! docker compose -f "$COMPOSE_FILE" pull artifactory 2> /tmp/artipull.err; then
    if grep -Ei 'denied|not found|manifest unknown|access' /tmp/artipull.err >/dev/null; then
      log "Primary pull failed; switching to alternate image $ARTI_IMAGE_ALT"
      sed -i "s|releases-docker.jfrog.io/jfrog/artifactory-oss:${ARTI_VERSION}|${ARTI_IMAGE_ALT}|" "$COMPOSE_FILE"
      if ! docker compose -f "$COMPOSE_FILE" pull artifactory 2>> /tmp/artipull.err; then
        log "Alternate image pull failed"; cat /tmp/artipull.err; exit 1;
      fi
    else
      log "Non-access pull error continuing: $(head -1 /tmp/artipull.err)"
    fi
  fi
  log "Starting container"
  if ! docker compose -f "$COMPOSE_FILE" up -d 2> /tmp/artistart.err; then
    log "Startup failed; showing diagnostics"; cat /tmp/artistart.err; docker compose -f "$COMPOSE_FILE" ps; exit 1;
  fi
}

create_systemd(){
  [ "$NO_SYSTEMD" = "1" ] && { log "Skipping systemd unit (NO_SYSTEMD=1)"; return; }
  if [ ! -f "$SERVICE_FILE" ]; then
    log "Creating systemd unit"
    cat >"$SERVICE_FILE" <<EOF
[Unit]
Description=Artifactory (Docker Compose)
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=${COMPOSE_DIR}
ExecStart=/usr/bin/docker compose -f ${COMPOSE_FILE} up -d
ExecStop=/usr/bin/docker compose -f ${COMPOSE_FILE} down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF
    chmod 644 "$SERVICE_FILE"
    systemctl daemon-reload
    systemctl enable artifactory.service
  fi
  systemctl start artifactory.service || true
}

wait_ready(){
  log "Waiting for port 8082 (timeout ~5m)"
  for i in $(seq 1 60); do
    if ss -ltn 2>/dev/null | grep -q ':8082' || curl -sf -o /dev/null http://localhost:8082/; then
      log "Port 8082 responsive"
      return 0
    fi
    sleep 5
  done
  log "ERROR: Timed out waiting for Artifactory service" >&2
  docker compose -f "$COMPOSE_FILE" ps || true
  exit 1
}

install_az_cli(){
  command -v az >/dev/null && return 0
  log "Installing Azure CLI"
  curl -sL https://aka.ms/InstallAzureCLIDeb | bash
}

sample_build_script(){
  local script="${PRIMARY_HOME}/build-sample-image.sh"
  [ -f "$script" ] && return 0
  cat >"$script" <<'EOS'
#!/usr/bin/env bash
set -Eeuo pipefail
log(){ echo "[sample-image] $*"; }
WORK=/tmp/sample-app
mkdir -p "$WORK"; cd "$WORK"
cat >Dockerfile <<DOCKER
FROM python:3.9-slim
WORKDIR /app
COPY . /app
EXPOSE 80
CMD ["python","-c","print('Hello from Contoso Lab Container!');import time;time.sleep(3600)"]
DOCKER
echo "print('Sample ML model placeholder')" > app.py
docker build -t localhost:8082/contoso-lab/sample-ml-model:latest .
echo "Built sample image. Push with: docker push localhost:8082/contoso-lab/sample-ml-model:latest" >&2
EOS
  chmod +x "$script"
  chown "$PRIMARY_USER":"$PRIMARY_USER" "$script" 2>/dev/null || true
}

main(){
  ensure_deps
  clean_boot_if_requested
  write_compose
  validate_compose
  start_stack
  create_systemd
  wait_ready
  install_az_cli || true
  sample_build_script
  local ip
  ip=$(hostname -I | awk '{print $1}')
  log "Artifactory ready: http://${ip}:8082" 
  log "Default credentials: admin / password (change immediately if still default)"
}

main "$@"
exit 0