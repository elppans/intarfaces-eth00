# intarfaces-eth00

Este script Bash automatiza a adição e configuração da interface de rede secundária `eth0:0` em sistemas Ubuntu 16.04.   
Ele é útil para adicionar uma interface adicional para uma rede específica, como uma rede de gerenciamento ou uma rede de armazenamento.

## Instalação

1. **Clone este repositório:**
   ```bash
   git clone [URL]
   ```
   ___
## Uso

1. **Execute o script:**
   ```bash
   ./interfaces-eth00.sh
   ```
   O script irá modificar o arquivo `/etc/network/interfaces` e reiniciar o serviço de rede para aplicar as alterações.

## Configuração

* **Rota padrão da loja:** A variável `rota` no início do script define a rota padrão para a nova interface. Você pode modificar esse valor para se adequar à sua rede.
* **Arquivo interfaces:** O script modifica o arquivo `/etc/network/interfaces`. Certifique-se de ter permissões de escrita nesse arquivo.

## Limitações

* **Sistema operacional:** O script foi projetado para sistemas Ubuntu 16.04 e pode não funcionar corretamente em outras distribuições.
* **Interface principal:** O script assume que a interface principal é `eth0`. Se a sua interface principal tiver um nome diferente, você precisará modificar o script.
