# 🧠 Inferencia Distribuida con Ollama

Este proyecto permite distribuir consultas a modelos LLM (como LLaMA 3) a través de múltiples nodos en una red local, usando el motor de inferencia **Ollama**.

## 📦 Componentes

- **`setup_nodo.sh`**: Script para instalar y configurar automáticamente un nodo con Ollama (soporta Debian y Arch).
- **`orquestador_ollama.py`**: Orquestador que escanea la red local, detecta los nodos activos y distribuye los prompts en modo round-robin.
- **`nodos/nodos.txt`**: Archivo que guarda los nodos detectados para uso persistente.

## ⚙️ Requisitos

- GNU/Linux (Debian, Ubuntu o Arch)
- Python 3.9 o superior
- Docker y acceso a sudo
- Acceso a una red local (LAN)

## 🚀 Cómo Usar

### 1. Instalar un Nodo

En cada máquina que actuará como nodo:

```bash
bash setup_nodo.sh
