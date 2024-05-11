#!/bin/bash
export SHOW_DEBUG=1    ## Comment this line to remove @DEBUG statements

###############################################################################
## ISCTE-IUL: Trabalho prático de Sistemas Operativos 2022/2023
##
## Aluno: Nº:111679       Nome: Joel Maximiano Matos
## Nome do Módulo: regista_utilizador.sh
## Descrição/Explicação do Módulo: 
## O módulo consiste em realizar o registo de um utilizador ao kiosk, com um id, senha e um numero de contribuinte criando email, podendo atualizar saldo.
## O módulo vai sendo explicado ao longo do código.
###############################################################################


##1.1.1 - Verificação do número de argumentos
    ## Verificacao se foram apenas passados ou 3 ou 4 argumentos
if [ $# -ne 3 ] && [ $# -ne 4 ];then
    ./error 1.1.1 ;
    exit 1
    else
    ./success 1.1.1 ;
fi
    ##1.1.2 - Verificação do nome 
 ## Obtencao dos nomes de todos os alunos  de SO
cut -f 5 -d ':' /etc/passwd | cut -f 1 -d ',' | grep -w "$1$"  > /dev/null ; ##/dev/null para não ser visível o output
 if [ $? -ne 0 ]; then
    ./error 1.1.2
    exit 1;
    else
    ./success 1.1.2
    fi
    ##1.1.3 Verificação do saldo
    # Verfica que o saldo é um número
    if ! [[ $3 =~ ^[0-9]+$ ]]; then 
        ./error 1.1.3
        exit 1;
        else
            ./success 1.1.3
        fi
       ##1.1.4 Valida o número e o formato de Contribuinte 
       #verifica se o contribuinte foi passado
    if [ -n "$4" ];then
        #verifica se o número de contribuinte é um número de 9 digitos
        if ! [[ $4 =~ ^[0-9]{9}$ ]];then
        
        ./error 1.1.4
        exit 1;
        else
        ./success 1.1.4
        fi
    fi


    ##1.2.1 Verificação da existência do ficheiro utilizadores.txt
if [ -f "utilizadores.txt" ]; then 
./success 1.2.1
else
./error 1.2.1

    ##1.2.2 Criação do ficheiro caso não exista e verificação do sucesso da sua criação
    touch utilizadores.txt

    # verifica se foi criado com sucesso
    if [ $? -ne 0 ]; then 
        ./error 1.2.2
        exit 1
     else
     ./success 1.2.2
    fi
fi
##1.2.3 Verificar se o utilizador está registado
    # procura do utilizador no ficheiro de utilizadores registados
if  grep -q "$1" "utilizadores.txt" ; then
    ./success 1.2.3
    else
    nao_registado="nr"
    ./error 1.2.3
        ##1.2.4 Valida se o nrº de Contribuinte  foi passado
    if [ -z "$4" ]; then
        ./error 1.2.4
        exit 1;
        else
        ./success 1.2.4
        
    fi
      ##1.2.5 Define o campo do Id do utilziador
         if [ -s "utilizadores.txt" ]; then
         ## encontra o maior id  caso o utilizadores.txt já tenha sido preenchido com conteúdo
        bigID=$(awk 'BEGIN {FS=":"} {if ($1 > max) max=$1} END {print max}' utilizadores.txt)
        userID=$((bigID+1))
        ./success 1.2.5
        else
        ./error 1.2.5
         userID=1
    fi
    ##1.2.6 Criação do email
    #obtém o primeiro e último nome do utilizador
    userName=$(echo $1 | tr [:upper:] [:lower:] ) #conversão para letras minúsculas
    firstname=$(echo "$userName" | cut -d' ' -f 1 )
    lastname=$(echo "$userName" | awk '{print $NF}')
   ## verifica se foi introduzido  um apelido
    if [ -z "$lastname" ]; then
        ./error 1.2.6
        exit 1
        else
        #cria o email caso tenha sido introduzido
        email="$firstname.$lastname@kiosk-iul.pt"
        ./success 1.2.6 $email
    fi

    ##1.2.7 registo do utilizador
    linha="$userID:${1}:${2}:${email}:${4}:${3}"
    echo $linha >> utilizadores.txt
    if  [ $? -eq  0 ] ;then
    id=$(echo $linha | cut -d":" -f1)
    ./success 1.2.7  $id
    else
    ./error 1.2.7 
    exit 1
    fi
fi

##1.3.1 Verificação da senha do utilizador
line=$(grep ":$1:" utilizadores.txt | cut -f1 -d ":" )

    if [  $line -eq 0 ];then
        ./error 1.3.1 "Utilizador não registado"
        exit 1
    else
        senha=$(grep "^$line" utilizadores.txt | cut -d":" -f3)
         
        if [[ "$senha" == "$2" ]];then
        ./success 1.3.1
        else
            ./error 1.3.1 "Senha Incorreta"
            exit 1
        fi
    fi

    ##1.3.2 Atualização de saldo
     grep  -q -w "$1" "utilizadores.txt" 
   if [ $? -eq 0 ] && [[ $nao_registado != "nr" ]] ;then
        saldo=$(grep -w "$1" utilizadores.txt | cut -f6 -d ':' )
    
     novo_saldo=$(( $3 + $saldo ))
    ## substituicao do novo saldo do utilizador
        sed -i -E "s/^$line:(.*):$saldo$/$line:\\1:$novo_saldo/" utilizadores.txt
            if [ $? -ne 0 ];then
                ./error 1.3.2
                else    
                ./success 1.3.2 $novo_saldo
            fi
            else
            ./error 1.3.2 "Utilizador ainda não foi registado"
    fi

    #1.4.1 Colocar os saldos ordenados
    ## ordenacao dos saldos dos utilizadores por ordem decrescente
   sort -t':' -k6,6nr utilizadores.txt > saldos-ordenados.txt
   if [ ! -f saldos-ordenados.txt ];then
        ./error 1.4.1
        exit 1
    else
    ./success 1.4.1
    fi




      
 