# orquestador_ollama.py
# Envia prompts a múltiples nodos Ollama y distribuye la carga (round-robin + verificación activa + descubrimiento automático)

import requests
import json
import os
import itertools
import socket

# Escanear red local para detectar nodos con Ollama
from ipaddress import ip_network
from concurrent.futures import ThreadPoolExecutor

red_local = "192.168.0.0/24"  # Puedes ajustar esto si tu red es diferente
puerto = 11434

def verificar_nodo(ip):
    try:
        r = requests.get(f"http://{ip}:{puerto}/api/tags", timeout=1.5)
        if r.status_code == 200:
            return ip
    except:
        return None

print("🔍 Escaneando red local para encontrar nodos activos...")
nodos_disponibles = []
with ThreadPoolExecutor(max_workers=50) as executor:
    resultados = list(executor.map(verificar_nodo, [str(ip) for ip in ip_network(red_local).hosts()]))
    nodos_disponibles = [ip for ip in resultados if ip is not None]

if not nodos_disponibles:
    print("❌ No se detectaron nodos activos en la red.")
    exit(1)

# Guardar lista de nodos detectados
ruta_nodos = os.path.expanduser("~/ollama-nodos/nodos.txt")
os.makedirs(os.path.dirname(ruta_nodos), exist_ok=True)
with open(ruta_nodos, "w") as f:
    f.write("\n".join(nodos_disponibles))

# Preparar iterador round-robin
nodos_rr = itertools.cycle(nodos_disponibles)

print("✅ Nodos disponibles:")
for nodo in nodos_disponibles:
    print(f" - {nodo}")

print("\nEscribe 'salir' para terminar.\n")

while True:
    prompt = input("🧠 Prompt > ")
    if prompt.lower() in ["salir", "exit", "quit"]:
        break

    nodo = next(nodos_rr)
    url = f"http://{nodo}:{puerto}/api/generate"
    print(f"📡 Enviando a nodo {nodo}...\n")

    payload = {
        "model": "llama3",
        "prompt": prompt
    }

    try:
        response = requests.post(url, json=payload, stream=True)
        if response.status_code == 200:
            print("🗨️  Respuesta:")
            for line in response.iter_lines():
                if line:
                    data = json.loads(line)
                    print(data.get("response", ""), end="", flush=True)
            print("\n")
        else:
            print(f"❌ Nodo {nodo} respondió con error:", response.status_code)
    except Exception as e:
        print(f"❌ Falló la conexión al nodo {nodo}:", str(e))
