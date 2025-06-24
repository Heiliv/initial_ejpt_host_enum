# initial_ejpt_host_enum
Script en Bash para automatizar la enumeración inicial de hosts en escenarios de pentesting tipo eJPT, Hack The Box o laboratorios personales.

---

## 🚀 ¿Qué hace?

Este script ejecuta una serie de tareas automáticas sobre una subred dada para detectar hosts activos y obtener información útil para la fase de reconocimiento inicial:

- 🛰️ Ping sweep para detectar hosts vivos
- 🔍 Escaneo con Nmap de puertos abiertos
- 🌐 Enumeración de servicios web (WhatWeb, Nikto, Gobuster)
- 📂 Enumeración de FTP (acceso anónimo)
- 🗂️ Enumeración de SMB (shares públicas)
- 📁 Organización de resultados en carpetas por IP

---

## 📦 Requisitos

Asegúrate de tener instaladas las siguientes herramientas:

```bash
sudo apt install gobuster nikto whatweb smbclient ftp nmap
```

---

## 🛠️ Uso

```bash
chmod +x initial_host_enum.sh
./initial_host_enum.sh <subred>
```

Ejemplo:

```bash
./initial_host_enum.sh 10.10.10.0/24
```

---

## 📁 Estructura de salida

Los resultados se guardan en:

```
./resultados/
   └── 10.10.10.2/
       ├── nmap.txt
       ├── ftp.txt
       ├── smb.txt
       ├── nikto.txt
       ├── whatweb.txt
       └── gobuster.txt
```

---

## 📚 Inspiración

Este script fue desarrollado como parte de mi preparación para el eJPTv2 y otros laboratorios ofensivos. Está pensado para ahorrar tiempo en CTFs, pruebas de pentesting y simulaciones reales de red.

---


## ⚠️ Disclaimer

Este script es solo para fines educativos y de laboratorio. No debe utilizarse en sistemas sin autorización expresa.

---

## 📇 Autor

**Pablo García Maturana**  
[LinkedIn](https://www.linkedin.com/in/pablo-garcia-maturana/) | [Hack The Box](https://app.hackthebox.com/profile/1007679)
