#!/bin/bash
export SHOW_DEBUG=1    ## Comment this line to remove @DEBUG statements

###############################################################################
## ISCTE-IUL: Trabalho prático de Sistemas Operativos 2022/2023
##
## Aluno: Nº: 111679       Nome: Joel Maximiano Matos
## Nome do Módulo: menu.sh
## Descrição/Explicação do Módulo: 
## Neste módulo temos o display do que o utilizador vai usar. 
## Cada das opcoes selecionadas pelo utilizador vai executar os scripts criados anteriormente
## E o Menu deixa de aparecer quando o utilizador desejar abandonar o kiosk
###############################################################################

#!/bin/bash

## 5.1.1 Apresenta menu de opções
while true; do
    echo "MENU:"
    echo "1: Regista/Atualiza saldo utilizador"
    echo "2: Compra produto"
    echo "3: Reposição de stock"
    echo "4: Estatísticas"
    echo "0: Sair"

    read -p "Opção: " opcao

## 5.2.1 valida se a opção inserida pelo utilizador é válida




# 5.2.2 Analisa a opção escolhida e invoca o script correspondente

case $opcao in
   ##5.2.2.1 
    1)
        ./success 5.2.1 $opcao
        echo "Regista utilizador/ Atualiza o saldo utilizador:"
        read -p "Indique o nome do utilizador: " nome
        read -p "Indique a senha do utilizador: "  senha
        read -p "Para registar o utilizador, insira o NIF do utilizador: " nif
        read -p "Indique o saldo a adicionar ao utilizador: " saldo

        ./regista_utilizador.sh "$nome" "$senha" "$saldo" "$nif"
        if [ $? -eq 0 ];then 
            ./success 5.2.2.1
        else
            ./error 5.2.2.1
        fi
        ;;
        ## 5.2.2.2 
    2) 
        ./success 5.2.1 $opcao
        ./compra.sh

        if [ $? -eq 0 ];then
            ./success 5.2.2.2
        else
            ./error 5.2.2.2
        fi
        ;;
    3)
        ./success 5.2.1 $opcao
        ./refill.sh

        if [ $? -eq 0 ];then
            ./success 5.2.2.3
        else
            ./error 5.2.2.3
        fi
        ;;
    4)
        ./success 5.2.1 $opcao
        echo "Estatísticas: "
        echo "1: Listar utilizadores que já fizeram compras "
        echo "2: Listar os produtos mais vendidos "
        echo "3: Histograma de vendas"
        
        read -p "Sub-Opcao: " subopcao
        case $subopcao in
        
        1) 
            ./stats.sh listar
            if [ $? -eq 0 ];then
                ./success 5.2.2.3
            else 
                ./error 5.2.2.3
            fi
            ;;
        2)
            echo "Listar os produtos mais vendidos : "
            read -p "Indique o número de produtos mais vendidos a listar : " num
            ./stats.sh "popular" $num
              if [ $? -eq 0 ];then
                ./success 5.2.2.3
            else 
                ./error 5.2.2.3
            fi
            ;;
        3)
            ./stats.sh "histograma"
            if [ $? -eq 0 ];then
                ./success 5.2.2.3
            else 
                ./error 5.2.2.3
            fi
            ;;
        *)
            ./error 5.2.2.3 $subopcao
            ;;
        esac
        ;;
    0) 
        ./success 5.2.1 $opcao
        ./success 5.2.2
        exit 0
        ;;
    *)
        ./error 5.2.1 $opcao
        ;;

esac

done

