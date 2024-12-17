#!/bin/bash

# Verifica se o usuário é root (UID 0)
if [[ $(id -u) -ne 0 ]]; then
    echo "Este script deve ser executado como root."
    exit 1
fi

# Verifica se o primeiro argumento foi fornecido
if [[ -z "$1" ]]; then
    echo "Erro: O argumento 'rota' é obrigatório..."
    echo "Indique o IP da rota que será usado!"
    exit 1
fi

# Arquivo interfaces
interface_file="/etc/network/interfaces"

# Rota padrão da loja
rota="$1" # "192.168.1.201"

# Obtém o comprimento total da string
comprimento=${#rota}

# Extrai todos os caracteres até o terceiro ponto (excluindo o último octeto)
nova_rota=$(echo "$rota" | cut -d. -f-3)

# Último octeto do endereço IP da Interface eth0
oct4="$(ifconfig eth0 | grep 'inet ' | awk '{print $2}' | cut -d '.' -f '4')"

# Máscara da Interface eth0
mask="$(ifconfig eth0 | grep 'inet ' | awk '{print $4}')"

# echo "$nova_rota.$oct4"
# echo "$mask"

# 1ª Linha a ser verificada e modificada
line_to_check="auto lo eth0"
interface_to_add="eth0:0"

# Interface secundario
eth0_0="iface $interface_to_add inet static"

# Função para encontrar e modificar a linha
function modify_line() {
    sed -i "s/$line_to_check/$line_to_check $interface_to_add/g" "$interface_file"
}

# Verifica se a linha já existe e contém a interface a ser adicionada
if grep -q "$line_to_check.*$interface_to_add" "$interface_file"; then
    echo "A interface $interface_to_add já existe."
else
    # Se não existir, chama a função para modificar a linha
    modify_line
    echo "A interface $interface_to_add foi adicionada."
fi

# Comando para verificar se a linha existe
if grep -Fxq "$eth0_0" "$interface_file"; then
  echo "A linha '$eth0_0' foi encontrada no interface_file $interface_file."
else
  echo "A linha '$eth0_0' não foi encontrada. Executando configuração..."
  echo "Configurando a interface eth0:0 para modo estático..."
echo -e "\n
# Interface para rota TEF
iface eth0:0 inet static
address "$nova_rota.$oct4"
netmask "$mask"

# Rota para TEF
post-up ip route add 172.19.0.0/16 via "$rota"

" | sudo tee -a "$interface_file"
   sudo systemctl restart networking
fi
