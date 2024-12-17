#!/bin/bash

# Configurações padrão
INTERFACE_FILE="/etc/network/interfaces"
INTERFACE_TO_ADD="eth0:0"
LINE_TO_CHECK="auto lo eth0"

# Função para configurar a interface eth0:0
configure_interface() {
    local nova_rota="$(ifconfig eth0 | grep 'inet ' | awk '{print $2}' | cut -d. -f-3)"
    local oct4="$(ifconfig eth0 | grep 'inet ' | awk '{print $2}' | cut -d '.' -f '4')"
    local mask="$(ifconfig eth0 | grep 'inet ' | awk '{print $4}')"
    local rota="192.168.1.201"

    # Verifica se o arquivo interfaces existe e é writable
    if [[ ! -f "$INTERFACE_FILE" || ! -w "$INTERFACE_FILE" ]]; then
        echo "Erro: Arquivo $INTERFACE_FILE não encontrado ou não tem permissão de escrita."
        exit 1
    fi

    # Adiciona a configuração da interface
    echo -e "\n
# Interface para rota TEF
iface $INTERFACE_TO_ADD inet static
address "$nova_rota.$oct4"
netmask "$mask"

# Rota para TEF
post-up ip route add 172.19.0.0/16 via "$rota"

" | sudo tee -a "$INTERFACE_FILE"

    # Reinicia o serviço de rede
    sudo systemctl restart networking
}

# Verifica se a linha já existe e contém a interface a ser adicionada
if grep -q "$line_to_check.*$interface_to_add" "$interface_file"; then
    echo "A interface $interface_to_add já existe."
else
    # Modifica a linha e configura a interface
    sed -i "s/$line_to_check/$line_to_check $interface_to_add/g" "$interface_file"
    configure_interface
    echo "A interface $interface_to_add foi adicionada e configurada."
fi
