#!/bin/bash
export SHOW_DEBUG=1    ## Comment this line to remove @DEBUG statements

###############################################################################
## ISCTE-IUL: Trabalho prático de Sistemas Operativos 2022/2023
##
## Aluno: Nº:  111679    Nome: Joel Maximiano Matos
## Nome do Módulo: stats.sh
## Descrição/Explicação do Módulo: 
## Neste módulo pretende-se através da operacao inserida e/ou do valor inserido obter  as estatísticas das vendas.
## Os comentários ao longo do módulo vão explicando-o
###############################################################################

##4.1.1  Valida os argumentos recebidos e não múltiplas operacoes
    
    ## Verificacao da inexistencia de ordens  
    if [ $# -eq 0 ] || [ $# -gt 2 ];then
        ./error 4.1.1
        exit 1
    fi
        if [ "$1" == "popular" ] && [ $# -ne 2 ] ;then
            ./error 4.1.1
            exit 1
        fi
        if [ "$1" == "listar" ] && [  $# -gt 1 ];then
            ./error 4.1.1
            exit 1
        fi
         if [ "$1" == "histograma" ] && [  $# -gt 1 ];then
            ./error 4.1.1
            exit 1
        fi

        if [ "$1" != "popular" ] && [ "$1" != "listar" ] && [ "$1" != "histograma" ];then 
        ./error 4.1.1
        exit 1
        fi
        ./success 4.1.1

  
     ##4.2.1 Lista com as compras de todos os  utilizadores
        
        ## Contagem do número de utilizadores registados
        nr_utilizadores=$(wc -l utilizadores.txt | cut -f1 -d ' ' )
    
        # verificacao se a ordem inserida é lista
        if [ "$1" == "listar"  ];then
            ## verificacao da existencia dos ficheiros utilizadores.txt e relatorio_compras.txt 
            if [ -f utilizadores.txt ] && [ -f relatorio_compras.txt ];then
                
                ## verificacao da existencia do ficheiro stats que 
                if [ -f stats.txt ];then
                    rm stats.txt
                fi
                
                for userID in $(seq 1 $nr_utilizadores);
                do
                    utilizador=$(grep -E "^$userID" utilizadores.txt | cut -f2 -d":")
                    nr_compras=$(grep ":$userID:" relatorio_compras.txt | wc -l )
                    compra="compra"
                     if [ $nr_compras -gt 1 ];then
                            compra="compras"
                     fi
                    echo "$utilizador: $nr_compras $compras" >> stats.txt
                done 
                    ./success 4.2.1
                  
            else
                ./error 4.2.1 
                exit 1
            fi
        else
            ./error 4.2.1   
        fi     

        ## 4.2.2 Cria um ficheiro que mostra as categorias de artigos mais vendidas
    nr_produtos=$(cat produtos.txt | cut -f1 -d":" | sort -u | wc -l )
    if [ $# -ne 0 ];then
        if [ $#  -eq 2 ];then 
            if [ "$1" == "popular" ];then 
                if [[ "$2" =~ ^[0-9]+$ ]];then
                    if [ -f stats.txt ] || [ -f statstemp.txt ];then
                        rm stats.txt 2> /dev/null
                        rm statstemp.txt 2> /dev/null
                    fi

                    while read line
                    do

                        nome_produto=$(echo $line | cut -f1 -d":") 

                        nr_compras=$(grep "^$nome_produto:" relatorio_compras.txt | wc -l  )
                        compra="compra"
                        if [ $nr_compras -gt 1 ];then
                            compra="compras"
                        fi
                        echo "$nome_produto: $nr_compras $compra" >> statstemp.txt


                    done < produtos.txt

               
                    sort -t":" -k2 -n -r -o stats.txt  statstemp.txt 
                    cat stats.txt | head -n $2
                    ./success 4.2.2
                else
                    ./error 4.2.2 "Não introduziu um numero de linhas valido"
                    ./exit 1
                fi
            else
                ./error 4.2.2 
            fi
        else
            ./error 4.2.2
        fi

    ## 4.2.3 Cria um ficheiro com o histograma  de venda de produtos por categoria
        if [ $1 == "histograma"  ];then
            if [ -f relatorio_compras.txt ];then
                if [ -f stats.txt ];then
                    rm stats.txt
                fi
                    
                if [ -f categorias.txt ];then
                    rm categorias.txt
                fi
                
                nr_categorias=$(cat produtos.txt | cut -f2 -d":" | sort -u | wc -l )
                cut -f2 -d":" produtos.txt | sort -u >> categorias.txt
            
                while read line 
                do
                    categoria=$(grep "^$line" categorias.txt | tr -d '\n' )
                    echo -n "$categoria     " >> stats.txt
                    quantidade=$(grep ":$categoria:" relatorio_compras.txt | wc -l )
                    for asterisco in $(seq 0 $quantidade);
                    do
                        echo -n "*" >> stats.txt
                    done
                    
                    echo >> stats.txt
                done < categorias.txt 
                ./success 4.2.3
                cat stats.txt
            else
                ./error 4.2.3 
                exit 1
            fi
        else 
            ./error 4.2.3 
        fi 
    fi
     
      
             