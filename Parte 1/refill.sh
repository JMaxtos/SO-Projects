#!/bin/bash
export SHOW_DEBUG=1    ## Comment this line to remove @DEBUG statements

###############################################################################
## ISCTE-IUL: Trabalho prático de Sistemas Operativos 2022/2023
##
## Aluno: Nº: 111679      Nome: Joel Maximiano Matos
## Nome do Módulo: refill.sh
## Descrição/Explicação do Módulo: 
## O código está explicado ao longo ficheiro
## Neste módulo o objetivo é principal  repÔr os produtos que não estão em stock
###############################################################################

##3.1.1 Validação da existência dos ficheiros produtos.txt e reposicao.txt

if [ ! -f produtos.txt ] || [ ! -f reposicao.txt ];then
    ./error 3.1.1
else
    ./success 3.1.1
fi

##3.1.2 Valida se os produtos de reposicao.txt existem  e se algum produto tem o numero a adicionar diferente do formato "number" 
 ## ciclo while que lê as linhas do ficheiro reposicao.txt
while read line;do
  nome_produto=$(echo $line | cut -f1 -d":" )
  nr_itens_adicionar=$(echo $line | cut -f3 -d":")

  grep "^$nome_produto" produtos.txt

  if [ $? -ne 0 ];then
    ./error 3.1.2 $nome_produto
  fi
 
if [[ "$nr_itens_adicionar" =~ ^[^0-9]+$ ]];then
    ./error 3.1.2 $nome_produto
    exit 1
fi
done < reposicao.txt
./success 3.1.2


## 3.2.1 Cria ficheiro dos produtos em falta e mostra quais são
##Obtém a data
data=$(date '+%Y-%m-%d')
escreveu=0

if [ -f produtos-em-falta.txt ];then
    echo -n > produtos-em-falta.txt
fi 
## Ciclo que lê as linhas do ficheito produtos.txt e vê o stock atual e máximo de cada produto
while read line 
do
    stock_atual=$(echo $line | cut -f4 -d":" )
    stock_maximo=$(echo $line | cut -f5 -d":")
    diferenca_stock=$(( $stock_maximo - $stock_atual ))
    
    if [ "$diferenca_stock" -gt "0" ];then
        if [ $escreveu -eq 0 ]; then
       
            echo " **** Produtos em falta em  ${data} **** " >> produtos-em-falta.txt
            escreveu=1
        fi
        ## Escreve no ficheiro produts-em-falta.txt o stock em falta
        echo " $(grep "$line" produtos.txt | cut -f1 -d":"), ${diferenca_stock} unidades" >> produtos-em-falta.txt
        if [ $? -ne 0 ];then
            ./error 3.2.1
            exit 1
        fi 
    fi
done < produtos.txt
./success 3.2.1


           
##3.2.2 Reposicao dos produtos
while read line
do 
    produto=$(echo $line | cut -f1 -d":" )
    stock_atual=$(grep "^$produto" produtos.txt| cut -f4 -d":" )
    stock_permitido=$(grep "^$produto" produtos.txt | cut -f5 -d":")
    
    grep -q "^$produto" produtos.txt
    ## verifica se o produto existe
    if [ $? -eq 0 ] ;then 
        ## substituicao do novo stock de produtos
        sed -i -E "s/^$produto:(.*):$stock_atual:(.*)/$produto:\\1:$stock_permitido:\\2/" produtos.txt
        
        ## verificacao se se conseguiu substituir o stock do produto
        if [ $? -ne 0 ];then
            ./error 3.2.2
        else
            ./success 3.2.2
        fi
    fi
done < reposicao.txt


