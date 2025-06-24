#!/bin/bash

if [ -z "$1" ]; then
    echo "Uso: $0 <red/CIDR>"
    echo "Ejemplo: $0 10.0.0.0/24"
    exit 1
fi

RED="$1"
WORDLIST="/usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt"

echo "[*] Descubriendo hosts activos en $RED..."
HOSTS=$(nmap -sn "$RED" -oG - | awk '/Up$/{print $2}')

if [ -z "$HOSTS" ]; then
    echo "[!] No se encontraron hosts activos."
    exit 1
fi

echo "[*] Hosts activos encontrados:"
echo "$HOSTS"

# Construir lista para nmap: 10.0.0.3,10,12,15,16
PRINCIPAL=$(echo "$HOSTS" | head -n1 | cut -d'.' -f1-3)
SUFIJOS=$(echo "$HOSTS" | sed "s/$PRINCIPAL\.//" | tr '\n' ',' | sed 's/,$//')
NMAP_TARGET="$PRINCIPAL.$SUFIJOS"

mkdir -p resultados

echo "[*] Escaneando puertos TCP abiertos en: $NMAP_TARGET"
nmap -sS -Pn --min-rate 5000 --open -oN resultados/tcp_scan.txt $NMAP_TARGET

# Recopilar todos los puertos únicos abiertos en todos los hosts
ALL_PORTS=$(grep -oP '^\d+/tcp\s+open' resultados/tcp_scan.txt | cut -d'/' -f1 | sort -n | uniq | tr '\n' ',' | sed 's/,$//')
if [ -z "$ALL_PORTS" ]; then
    echo "[!] No se encontraron puertos abiertos."
    exit 1
fi
echo "[*] Puertos abiertos detectados: $ALL_PORTS"

echo "[*] Escaneando servicios (único archivo de salida)..."
nmap -sV -Pn -p "$ALL_PORTS" $NMAP_TARGET -oN resultados/all_service_scan.txt

for ip in $HOSTS; do
    echo "[*] Procesando $ip..."
    mkdir -p "resultados/$ip"

    # Extraer puertos abiertos solo para este host
    HOST_PORTS=$(awk "/^Host: $ip/" resultados/tcp_scan.txt | grep -oP '\d+/open/tcp' | cut -d'/' -f1 | tr '\n' ',' | sed 's/,$//')

    if [ -z "$HOST_PORTS" ]; then
        echo "    [!] No se encontraron puertos abiertos en $ip."
        continue
    fi

    # === WEB ===
    if echo "$HOST_PORTS" | grep -qE '\b(80|443|8080|8000|8443)\b'; then
        echo "  [+] Servicios web detectados en $ip"
        whatweb "http://$ip" > "resultados/$ip/whatweb.txt" 2>&1
        nikto -h "http://$ip" > "resultados/$ip/nikto.txt" 2>&1
        gobuster dir -u "http://$ip" -w "$WORDLIST" -q -o "resultados/$ip/gobuster.txt" 2>&1
    fi

    # === SMB ===
    if echo "$HOST_PORTS" | grep -q 445; then
        echo "  [+] SMB detectado en $ip"
        smbclient -L "//$ip" -N > "resultados/$ip/smb_enum.txt" 2>&1

        echo "    [>] Probando acceso anónimo a cada recurso SMB..."
        grep 'Disk' "resultados/$ip/smb_enum.txt" | awk '{print $1}' | while read -r share; do
            smbclient "//$ip/$share" -N -c 'ls' > "resultados/$ip/smb_public_${share}.txt" 2>&1
            if grep -q -v "NT_STATUS_ACCESS_DENIED" "resultados/$ip/smb_public_${share}.txt"; then
                echo "      [+] Acceso público a //$ip/$share"
            else
                echo "      [-] Acceso denegado a //$ip/$share"
                rm -f "resultados/$ip/smb_public_${share}.txt"
            fi
        done
    fi

    # === FTP ===
    if echo "$HOST_PORTS" | grep -q 21; then
        echo "  [+] FTP detectado en $ip"
        echo -e "user anonymous\npass anonymous\nls\nquit" | ftp -nv "$ip" > "resultados/$ip/ftp_anonymous_listing.txt" 2>&1
        if grep -q "^226" "resultados/$ip/ftp_anonymous_listing.txt" || grep -qi "ftp>" "resultados/$ip/ftp_anonymous_listing.txt"; then
            echo "      [+] Acceso FTP anónimo exitoso en $ip"
        else
            echo "      [-] Acceso FTP anónimo fallido"
            rm -f "resultados/$ip/ftp_anonymous_listing.txt"
        fi
    fi

done

echo "[*] Todo listo. Revisa la carpeta ./resultados/"
