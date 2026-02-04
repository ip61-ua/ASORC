#!/usr/bin/python3
'''
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
'''

import socket
import struct
import sys
import subprocess
import re
import os
import select
import time

VM_OWNER_USER = os.environ.get("SUDO_USER") or "ibai"

# Variables globales para los sockets
sock_udp = None
sock_raw = None
sockets_list = []

def cleanup_sockets():
    '''
    Cierra todos los sockets de escucha abiertos.
    '''
    global sockets_list
    if sockets_list:
        print("\n[INFO] Cerrando sockets...")
        for s in sockets_list:
            try:
                s.close()
            except Exception:
                pass

def get_vm_mac_map():
    '''
    Busca todas las máquinas virtuales registradas por el usuario VM_OWNER_USER,
    extrae sus MACs de red y crea un diccionario que mapea la MAC al nombre exacto de la VM,
    solo para las VMs que NO están en estado 'running'.

    Retorna:
        dict: Diccionario donde la clave es la MAC y el valor es el nombre de la VM.
    '''
    mac_map = {}
    try:
        # Usamos -H para asegurar que la variable HOME es la del usuario
        list_command = ["sudo", "-H", "-u", VM_OWNER_USER, "VBoxManage", "list", "vms"]
        result = subprocess.run(list_command, capture_output=True, text=True, check=True)
        vm_lines = result.stdout.strip().split('\n')

        vm_names = []
        for line in vm_lines:
            match = re.search(r'"(.*?)"', line)
            if match and match.group(1) != "<inaccessible>":
                vm_names.append(match.group(1))

        print(f"[*] VMs registradas encontradas para {VM_OWNER_USER}: {', '.join(vm_names)}")

        for name in vm_names:
            info_command = ["sudo", "-H", "-u", VM_OWNER_USER, "VBoxManage", "showvminfo", name, "--machinereadable"]
            info_result = subprocess.run(info_command, capture_output=True, text=True, check=True)

            state_match = re.search(r'VMState="(.*?)"', info_result.stdout)
            state = state_match.group(1) if state_match else "unknown"

            for line in info_result.stdout.strip().split('\n'):
                mac_match = re.search(r'macaddress(\d+)="(.*?)"', line)

                if mac_match:
                    nic_number = mac_match.group(1)
                    raw_mac = mac_match.group(2)
                    formatted_mac = ":".join(raw_mac[i:i+2] for i in range(0, len(raw_mac), 2)).upper()

                    print(f"[*] VM '{name}' (NIC {nic_number}) -> MAC: {formatted_mac} (Estado: {state})")

                    if raw_mac != "000000000000" and state != "running":
                        mac_map[formatted_mac] = name
                    elif state == "running":
                        print(f"[*] MAC {formatted_mac} ignorada: VM '{name}' ya está ejecutándose.")

    except subprocess.CalledProcessError as e:
        err_msg = e.stderr.strip() if e.stderr else "Sin detalles de error"
        print(f"[ERROR] No se pudo ejecutar VBoxManage como {VM_OWNER_USER}. {err_msg}")
        raise
    except Exception as e:
        print(f"[ERROR] Error al parsear la informacion de las VMs: {e}")
        raise

    return mac_map

def start_vm(vm_name):
    '''
    Ejecuta el comando VBoxManage para encender la máquina virtual especificada.
    '''
    print(f"[WOL] Arrancando VM: {vm_name}")
    # Añadido -H para establecer HOME y capture_output para manejar errores
    start_command = ["sudo", "-H", "-u", VM_OWNER_USER, "VBoxManage", "startvm", vm_name, "--type", "headless"]

    # Ejecutamos con capture_output=True para obtener stderr si falla
    subprocess.run(start_command, check=True, capture_output=True, text=True)
    print(f"[WOL] VM {vm_name} arrancada.")

def setup_sockets():
    '''
    Configura y devuelve la lista de sockets Capa 2 (RAW) y Capa 4 (UDP).
    '''
    global sock_udp, sock_raw, sockets_list

    # 1. Socket UDP (Capa 4)
    try:
        sock_udp = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock_udp.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
        sock_udp.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        sock_udp.bind(('', 9))
        sockets_list.append(sock_udp)
        print("[*] Socket UDP vinculado al puerto 9 (wakeonlan).")
    except Exception as e:
        print(f"[ERROR] Fallo al crear socket UDP: {e}.")

    # 2. Socket RAW (Capa 2)
    try:
        sock_raw = socket.socket(socket.AF_PACKET, socket.SOCK_RAW, socket.htons(3))
        sockets_list.append(sock_raw)
        print("[*] Socket RAW vinculado a ETH_P_ALL (ether-wake).")
    except Exception as e:
        print(f"[ERROR] Fallo al crear socket RAW (requiere root): {e}.")

    return sockets_list

def listen_wol(initial_mac_map):
    '''
    Bucle principal que escucha en ambos sockets y gestiona la activación de VMs.
    '''
    global sockets_list
    current_mac_map = initial_mac_map

    print(f"[*] Monitorizando Capa 2 (Ethernet) y Capa 4 (UDP :9) en TODAS las interfaces...")

    while True:
        try:
            readable, _, _ = select.select(sockets_list, [], [])

            for s in readable:
                try:
                    data, _ = s.recvfrom(2048)
                except Exception as e:
                    print(f"[ERROR] Error al recibir datos en el socket: {e}")
                    continue

                sync_stream = b'\xff' * 6

                if sync_stream in data:
                    idx = data.find(sync_stream)
                    mac_part_start = idx + 6
                    mac_part_end = mac_part_start + (16 * 6)

                    if len(data) >= mac_part_end:
                        mac_data = data[mac_part_start:mac_part_end]
                        target_mac_bytes = mac_data[:6]

                        if mac_data == target_mac_bytes * 16:
                            mac_str = ':'.join(f'{b:02x}' for b in target_mac_bytes).upper()
                            print(f"\n{'-'*50}")
                            print(f"[!] Paquete Mágico detectado para MAC: {mac_str}")
                            print(f"[*] Actualizando mapa de VMs...")

                            try:
                                current_mac_map = get_vm_mac_map()
                            except Exception as e:
                                print(f"[ERROR] Fallo al actualizar el mapa: {e}.")

                            if mac_str in current_mac_map:
                                vm_name = current_mac_map[mac_str]
                                try:
                                    start_vm(vm_name)
                                except subprocess.CalledProcessError as e:
                                    # Aquí capturamos el error real gracias a capture_output=True
                                    err_out = e.stderr.strip() if e.stderr else "Sin detalles"
                                    print(f"[ERROR] Fallo al iniciar VM '{vm_name}': {err_out}")
                                except Exception as e:
                                    print(f"[ERROR] Fallo inesperado al iniciar VM '{vm_name}': {e}.")
                            else:
                                print(f"[WOL] MAC {mac_str} ignorada (no mapeada o VM encendida).")
                            print(f"{'-'*50}\n")

        except select.error as e:
            if e.errno == 4:
                continue
            print(f"[ERROR] Error en select: {e}.")
            time.sleep(1)
        except KeyboardInterrupt:
            raise
        except Exception as e:
            print(f"[ERROR] Error bucle principal: {e}.")
            time.sleep(1)

if __name__ == "__main__":
    if os.geteuid() != 0:
        print("[WARN] Este programa requiere elevación (sudo).")

    print(f"[*] Usando al usuario '{VM_OWNER_USER}' para consultar y arrancar VMs.")

    try:
        MAPPING = get_vm_mac_map()

        if not MAPPING:
            print("[WARN] No hay máquinas apagadas que mapear.")
            sys.exit(0)

        setup_sockets()
        listen_wol(MAPPING)

    except KeyboardInterrupt:
        cleanup_sockets()
        print("[INFO] Programa terminado.")
        sys.exit(0)
    except Exception:
        cleanup_sockets()
        sys.exit(1)