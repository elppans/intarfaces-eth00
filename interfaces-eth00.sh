#!/bin/bash

# Função para verificar se o script está sendo executado como root
verificar_root() {
    if [[ $(id -u) -ne 0 ]]; then
        echo "Este script deve ser executado como root."
        exit 1
    fi
}

# Função para verificar se o argumento foi fornecido
verificar_argumento() {
    if [[ -z "$1" ]]; then
        echo "Erro: O argumento 'rota' é obrigatório."
        echo "Indique o IP da rota que será usado!"
        exit 1
    fi
}

# Função para obter o endereço IP configurado na interface eth0
obter_ip_eth0() {
    ifconfig eth0 | grep 'inet ' | awk '{print $2}' | sed 's/addr://'
}

# Função para obter a máscara de rede da interface eth0 no formato correto
obter_mascara_eth0() {
    ifconfig eth0 | grep 'inet ' | awk '{print $4}' | sed 's/Mask://'
}

# Função para verificar se o IP address e a rota estão no mesmo range
verificar_mesmo_range() {
    local ip_sistema="$1"
    local rota="$2"
    local mask="$3"

    # Verifica se todos os valores estão no formato esperado
    if [[ -z "$ip_sistema" || -z "$rota" || -z "$mask" ]]; then
        echo "Erro ao obter IP ou máscara. Verifique a interface eth0."
        exit 1
    fi

    # Converte IP e máscara para números inteiros
    ip_decimal=$(ip_to_decimal "$ip_sistema")
    rota_decimal=$(ip_to_decimal "$rota")
    mask_decimal=$(ip_to_decimal "$mask")

    # Aplica a máscara ao IP e à rota
    ip_masked=$((ip_decimal & mask_decimal))
    rota_masked=$((rota_decimal & mask_decimal))

    # Compara os resultados mascarados
    [[ "$ip_masked" -eq "$rota_masked" ]]
}

# Função auxiliar para converter IP em decimal
ip_to_decimal() {
    local ip="$1"
    local -a octetos
    IFS='.' read -r -a octetos <<< "$ip"

    # Verifica se os octetos estão corretos
    if [[ ${#octetos[@]} -ne 4 ]]; then
        echo "Erro: IP inválido '$ip'."
        exit 1
    fi

    echo $((octetos[0] * 256 ** 3 + octetos[1] * 256 ** 2 + octetos[2] * 256 + octetos[3]))
}

# Função para verificar se o bloco completo já existe no arquivo
verificar_configuracao_existe() {
    local arquivo="$1"
    local configuracao="$2"

    # Verifica se o bloco de configuração está no arquivo
    grep -F -- "$configuracao" "$arquivo"
}

# Função para adicionar configuração ao arquivo de interfaces
adicionar_configuracao() {
    local arquivo="$1"
    local nova_rota="$2"
    local oct4="$3"
    local mask="$4"
    local destino="$5"
    local rota="$6"
    local mesmo_range="$7"

    local rota_tef="post-up ip route add $destino via $rota"
    local bloco_configuracao="
# Interface para rota TEF
iface $interface_eth00 inet static
address $nova_rota.$oct4
netmask $mask

# Rota para TEF
$rota_tef
"

    if [[ "$mesmo_range" == "true" ]]; then
        if verificar_configuracao_existe "$arquivo" "$rota_tef"; then
            echo "A rota '$rota_tef' já está configurada."
        else
            echo -e "\n# Rota para TEF\n$rota_tef" | tee -a "$arquivo"
        fi
    else
        # if verificar_configuracao_existe "$arquivo" "$bloco_configuracao"; then
          #  echo "A configuração da interface eth0:0 já está presente."
        # else
            echo -e "$bloco_configuracao" | tee -a "$arquivo"
            systemctl restart networking
        # fi
    fi
}

# Função para modificar a linha de configuração no arquivo de interfaces
modificar_linha() {
    local arquivo="$1"
    local linha_atual="$2"
    local interface_adicionar="$3"
    if [[ "$mesmo_range" == "false" ]]; then
      if ! grep -q "$interface_adicionar" "$arquivo" ; then
      sed -i "s/$linha_atual/$linha_atual $interface_adicionar/g" "$arquivo"
      else
      echo "A interfce $interface_adicionar já existe!"
      exit 0
      fi
    fi
}
# Função principal
principal() {
    verificar_root
    verificar_argumento "$1"

    local interface_file="/etc/network/interfaces"
    local rota="$1"
    local destino="172.19.0.0/16"

    local line_to_check="auto lo eth0"
    local interface_eth00="eth0:0"
    local eth00="iface $interface_eth00 inet static"

    # Obtém IP e máscara do sistema
    local ip_sistema=$(obter_ip_eth0)
    local mask=$(obter_mascara_eth0)

    # Verifica se os IPs estão no mesmo range
    local mesmo_range="false"
    if verificar_mesmo_range "$ip_sistema" "$rota" "$mask"; then
        mesmo_range="true"
        echo "Os IPs estão no mesmo range. A interface eth0:0 não será adicionada."
    else
        echo "Os IPs não estão no mesmo range. Adicionando interface eth0:0."
    fi

    # Interface eth0:0
    modificar_linha "$interface_file" "$line_to_check" "$interface_eth00"
    echo "A interface $interface_eth00 foi adicionada."

    # Adiciona a configuração apropriada
    local nova_rota=$(echo "$rota" | cut -d. -f-3)
    local oct4=$(echo "$ip_sistema" | cut -d '.' -f 4)
    adicionar_configuracao "$interface_file" "$nova_rota" "$oct4" "$mask" "$destino" "$rota" "$mesmo_range"
}

# Executa a função principal com os argumentos passados
principal "$@"
