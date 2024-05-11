#!/bin/bash
export SHOW_DEBUG=1    ## Comment this line to remove @DEBUG statements

###############################################################################
## ISCTE-IUL: Trabalho prático de Sistemas Operativos 2022/2023
##
## Aluno: Nº:   111679    Nome: Joel Maximiano Matos
## Nome do Módulo: compra.sh
## Descrição/Explicação do Módulo: 
## O código está explicado ao longo do ficheiro.
## O conceito principal deste módulo é que o utilizador consiga comprar os produtos
## em stock  caso tenha dinheiro e que o seu saldo seja decrementado apos cada compra
###############################################################################


##Verificação da operação introduzida pelo utilizador 
awk -F: '$4 > 0 {printf "%d: %s: %d EUR\n", NR, $1, $3}' produtos.txt | awk '{print $0} END {print "0: Sair\n"}'
echo "Insira a sua Opção: "
read opcao

##2.1.1 Verifica se o produtos.txt  e o utilizadores.txt existem

if [ ! -f produtos.txt ]  || [ ! -f utilizadores.txt ];then
       ./error 2.1.1
    exit 1
else
    ./success 2.1.1
   
fi

#2.1.2 Escolhe o produto ou operação de acordo com o valor introduzido pelo Utilizador

##Verifica o valor se o valor introduzido existe
if [[ "$opcao" =~ ^[0-9]+$ ]]; then
   
    ##verifica se o utilizador pretende sair
    if [ "$opcao" -eq 0 ]; then
     ./success 2.1.2
     exit 0
    else
        #Verifica se existe stock do produto
        produto=$(awk -v opcao="$opcao" -F: '$4 > 0 && NR == opcao {print $0}' produtos.txt)
            
         if [ -z "$produto" ];then
            ./error 2.1.2 "Produto sem Stock "
            exit 1 
        else
            ##procura o nome do produto que o utilziador escolheu
            nome_produto=$(grep "^$produto" produtos.txt | cut -d ':' -f1)
            ./success 2.1.2 "$nome_produto"
        fi
    fi
    else
    ./error 2.1.2 "Valor introduzido não é válido"
fi

#2.1.3  Id do utilizador
echo "Insira o ID do seu utilizador: "
read id_user
    ##verifica se o id introduzido está no sistema
    if grep -q "^$id_user" utilizadores.txt ;then
       ##procura o nome do utilziador que corresponde ao id introduzido
        nome=$(grep "^$id_user:" utilizadores.txt | cut -d: -f2) 
        ./success 2.1.3 "$nome"
        else
        ./error 2.1.3 "id não registado"
    fi

##2.1.4 Verificação da senha do utilizador
echo "Insira a senha do seu utilizador: "
read senha_inserida
## obtém a senha registada no sistema
senha_registada=$(grep "^$id_user" utilizadores.txt | cut -d":" -f3)
    ##verifica se a senha inserida é igual à registada no sistema
if [ "$senha_registada" != "$senha_inserida" ]; then
    ./error 2.1.4 "Senha Incorreta"
    exit 1
    else
    ./success 2.1.4
fi
##2.2.1 Valida se o utilizador tem saldo para comprar o artigo desejado

## obtém o saldo que o utilizador tem atualmente
saldo_disponivel=$(grep "^$id_user" utilizadores.txt | cut -f6  -d":")

##Obtém o valor do produto que o utilizador escolheu
preco_produto=$(echo "$produto" | cut -f3 -d":")

##Verifica se o utilizador tem saldo suficiente para comprar
if [ $saldo_disponivel -lt $preco_produto ]; then
    ./error 2.2.1 $preco_produto $saldo_disponivel 
    exit 1
    else
    ./success 2.2.1 $preco_produto $saldo_disponivel 
fi

##2.2.2  Decrementa o valor do preco do produto do saldo do utilizador
   
    ## desconta o valor do produto ao saldo do utilizador
saldo_apos_compra=$(( $saldo_disponivel - $preco_produto ))

## desconta o saldo do utilizador no ficheiro de utilizadores
sed -i -E "s/^$id_user:(.*):$saldo_disponivel$/$id_user:\\1:$saldo_apos_compra/" utilizadores.txt

if [ $? -eq 0 ]; then
    ./success 2.2.2
    else
    ./error 2.2.2
    exit 1
fi

 ##2.2.3
    ## adquire o stock atual do produto

    stock_produto=$(grep "$produto" produtos.txt | cut -f4 -d":")
   
    ## Subtrai 1 unidade ao stock existente

    novo_stock_produto=$(( $stock_produto - 1 ))
   
    ## desconta o stock do produto no ficheiro produtos.txt
    
    sed -i -E "s/^$nome_produto:(.*):$stock_produto:(.*)/$nome_produto:\\1:$novo_stock_produto:\\2/"  produtos.txt

    if [ $? -eq 0 ];then
    ./success 2.2.3
    else
    ./error 2.2.3
    exit 1
    fi

##2.2.4 Regista a compra e a data de compra
    ## Adquire a data de compra
    data_de_compra=$(date '+%Y-%m-%d')
    ## adiciona o registo de compra ao relatório
    echo "${nome_produto}:$(echo $produto | cut -f2 -d':'):${id_user}:${data_de_compra}" >> relatorio_compras.txt
    if [ $? -eq 0 ]; then
        ./success 2.2.4
    else
        ./error 2.2.4
    fi
#2.2.5 Lista de compras do Utilizador

    ##Verifica se o utilizador já realizou compras
    grep -q "$id_user" relatorio_compras.txt
    if [ $? -eq 0 ];then
        ##inicia a lista de compras do utilizador
        echo  "**** ${data_de_compra}: Compras de ${nome} ****" > lista-compras-utilizador.txt
        ## Adiciona os artigos e as datas que o utilizador realizou compras
        grep ":$id_user:" relatorio_compras.txt | cut -f1,4 -d':' | sed "s/:/, /" >> lista-compras-utilizador.txt

        ./success 2.2.5
        else
        ./error 2.2.6
    fi