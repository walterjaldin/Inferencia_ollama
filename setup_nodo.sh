#!/bin/bash
# setup_ollama_single_node.sh - Configura un nodo Ollama en red (Docker) para Debian y Arch

set -e

# Detectar IP local
IP_LOCAL=$(ip -4 addr | grep inet | grep -E '192\.|10\.|172\.' | awk '{print $2}' | cut -d/ -f1 | head -n 1)
RED=$(echo $IP_LOCAL | cut -d. -f1-3)
echo "📡 IP local detectada: $IP_LOCAL (Red: $RED.0/24)"

# Detectar distribución
if [ -f /etc/debian_version ]; then
  DISTRO="debian"
elif [ -f /etc/arch-release ]; then
  DISTRO="arch"
else
  echo "❌ Distribución no soportada. Usa Debian, Ubuntu o Arch Linux."
  exit 1
fi

# Instalar Docker
if ! command -v docker &>/dev/null; then
  echo "📦 Instalando Docker..."
  if [ "$DISTRO" = "debian" ]; then
    sudo apt update && sudo apt install -y docker.io curl
  elif [ "$DISTRO" = "arch" ]; then
    sudo pacman -Sy --noconfirm docker curl
  fi
  sudo systemctl enable docker
  sudo systemctl start docker
else
  echo "✅ Docker ya está instalado."
fi

# Detectar comando compose
if command -v docker-compose &>/dev/null; then
  COMPOSE_CMD="docker-compose"
elif docker compose version &>/dev/null; then
  COMPOSE_CMD="docker compose"
else
  echo "📥 Instalando Docker Compose v2 como binario..."
  VERSION="v2.24.5"
  sudo curl -L https://github.com/docker/compose/releases/download/$VERSION/docker-compose-$(uname -s)-$(uname -m) \
    -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  if command -v docker-compose &>/dev/null; then
    COMPOSE_CMD="docker-compose"
    echo "✅ Docker Compose v2 instalado como binario."
  else
    echo "❌ No se pudo instalar Docker Compose."
    exit 1
  fi
fi

# Verificar puerto
if ss -tuln | grep -q ':11434'; then
  echo "⚠️ El puerto 11434 ya está en uso. Abortando para evitar conflictos."
  exit 1
fi

# Preparar carpeta
mkdir -p ~/ollama-node && cd ~/ollama-node

# Crear docker-compose.yml
cat <<EOF > docker-compose.yml
version: '3.8'
services:
  ollama-node:
    image: ollama/ollama:latest
    container_name: ollama-node
    ports:
      - "11434:11434"
    volumes:
      - ollama_data:/root/.ollama
    restart: unless-stopped
volumes:
  ollama_data:
EOF

# Contenedor ya existe
if docker ps -a --format '{{.Names}}' | grep -q '^ollama-node$'; then
  echo "⚠️ El contenedor ollama-node ya existe. Reiniciando..."
  $COMPOSE_CMD restart
  exit 0
fi

# Iniciar nodo
echo "🚀 Iniciando el nodo Ollama..."
$COMPOSE_CMD up -d

# Descargar modelo llama3
echo "⬇️ Descargando modelo llama3..."
docker exec ollama-node ollama run llama3 || true

# Verificar modelo
if ! docker exec ollama-node ollama list | grep -q 'llama3'; then
  echo "❌ Falló la descarga del modelo. Revisa tu conexión o reinicia el nodo."
  exit 1
fi

# Verificación final
echo "🔍 Verificando acceso..."
sleep 5
if curl -s http://localhost:11434/api/tags | grep -q 'models'; then
  echo "✅ Nodo activo en http://$IP_LOCAL:11434"
else
  echo "❌ Error: Ollama no responde. Revisa con 'docker logs ollama-node'"
fi

# Guardar IP del nodo
mkdir -p ~/ollama-nodos
echo "$IP_LOCAL" > ~/ollama-nodos/nodo.txt

# Script de reinicio
cat <<EOF > ~/ollama-node/restart.sh
#!/bin/bash
$COMPOSE_CMD restart
EOF
chmod +x ~/ollama-node/restart.sh

# Guardar logs
docker logs -f ollama-node &> ~/ollama-node/ollama.log &

# Info final
echo -e "\n✅ Nodo listo para recibir prompts. Puedes probar con:\n"
echo "curl -X POST http://$IP_LOCAL:11434/api/generate -d '{\"model\":\"llama3\",\"prompt\":\"Hola mundo\"}'"

exit 0
