# 🧠 Inferencia Distribuida con Ollama

Este proyecto permite distribuir consultas a modelos LLM (como LLaMA 3) a través de múltiples nodos en una red local, usando el motor de inferencia **Ollama**.

---

## 📦 Componentes

- **`setup_nodo.sh`**: Script para instalar y configurar automáticamente un nodo con Ollama (soporta Debian y Arch).
- **`orquestador_ollama.py`**: Orquestador que escanea la red local, detecta los nodos activos y distribuye los prompts en modo round-robin.
- **`nodos/nodos.txt`**: Archivo que guarda los nodos detectados para uso persistente.

---

## ⚙️ Requisitos

- GNU/Linux (Debian, Ubuntu o Arch)
- Python 3.9 o superior
- Docker y acceso a `sudo`
- Acceso a una red local (LAN)

---

## 🚀 Instalación y Uso Paso a Paso

### 🔹 Paso 1: Configurar los Nodos

En cada máquina que actuará como nodo de inferencia:

1. Clona el repositorio o copia el archivo `setup_nodo.sh`.
2. Da permisos de ejecución y ejecútalo:

```bash
chmod +x setup_nodo.sh
./setup_nodo.sh
```

🔧 Esto hará:
- Detectar tu distribución (Debian o Arch)
- Instalar Docker y Ollama
- Instalar soporte para NVIDIA si se detecta GPU
- Dejar el nodo listo y escuchando en el puerto `11434`

---

### 🔹 Paso 2: Ejecutar el Orquestador (en el nodo principal)

1. Asegúrate de tener Python 3.9+ y `pip` instalado.
2. Instala las dependencias:

```bash
pip install -r requirements.txt
```

3. Ejecuta el orquestador:

```bash
python orquestador_ollama.py
```

🔍 El orquestador:
- Escanea la red `192.168.0.0/24`
- Detecta los nodos con Ollama activos
- Guarda sus IPs en `nodos/nodos.txt`
- Inicia una consola interactiva para enviar prompts

---

### 🧠 Uso del Orquestador

Una vez iniciado el script:

```text
🔍 Escaneando red local para encontrar nodos activos...
✅ Nodos disponibles:
 - 192.168.0.5
 - 192.168.0.6

🧠 Prompt > ¿Qué es la inteligencia artificial?
📡 Enviando a nodo 192.168.0.5...
🗨️  Respuesta: La inteligencia artificial es...
```

Puedes seguir enviando prompts uno tras otro. Para salir, simplemente escribe:

```text
🧠 Prompt > salir
```

---

## 📁 Estructura del Proyecto

```
├── setup_nodo.sh            # Script de instalación del nodo
├── orquestador_ollama.py    # Script principal de distribución
├── requirements.txt         # Dependencias de Python
├── LICENSE                  # Licencia MIT
├── README.md                # Este archivo
└── nodos/
    └── nodos.txt            # Lista de nodos detectados
```

---

## 🧪 Pruebas Realizadas

- Instalación automática en Arch y Debian
- Envío de múltiples prompts en modo round-robin
- Tolerancia a fallos (si un nodo se cae, rota al siguiente)
- Persistencia de nodos detectados entre ejecuciones

---

## 📄 Licencia

Este proyecto está bajo licencia MIT. Ver el archivo `LICENSE` para más detalles.
