/******************************************************************************
 ** ISCTE-IUL: Trabalho prático 3 de Sistemas Operativos
 **
 ** Aluno: Nº:       Nome:
 ** Nome do Módulo: cliente.c 2 (acrescentei parêntesis na linha 38)
 ** Descrição/Explicação do Módulo:
 **  Neste módulo,  abre-se a MessageQueue do servidor para conseguir trocar mensagens entre os 2.
 ** O utilizador preenche os dados e depois de receber a lista de produtos escolhe o produto desejado.
 ** Depois de selecionado o produto a ser comprado é verificado se a compra pode ou não ser realizada e
 ** por fim as funções finais acabam para informar que a sua sessão vai ser encerrada, que se possa cancelar o pedido
 ** e por fim para dizer que o cliente esperou mais segundos do que o máximo tempo de espera;
 **
 ******************************************************************************/
#include "common.h"
// #define SO_HIDE_DEBUG   // Uncomment this line to hide all @DEBUG statements
#include "so_utils.h"

/* Variáveis globais */
int msgId = RET_ERROR;                      // Variável que tem o ID da Message Queue
MsgContent msg;                             // Variável que serve para todas as mensagens trocadas entre Cliente e Servidor

/* Protótipos de funções. Os alunos não devem alterar estes protótipos. */
int initMsg_C1();                           // C1:  Função a ser completada pelos alunos (definida abaixo)
int triggerSignals_C2();                    // C2:  Função a ser completada pelos alunos (definida abaixo)
MsgContent getDadosPedidoUtilizador_C3();   // C3:  Função a ser completada pelos alunos (definida abaixo)
int sendClientLogin_C4(MsgContent);         // C4:  Função a ser completada pelos alunos (definida abaixo)
void configuraTemporizador_C5(int);         // C5:  Função a ser completada pelos alunos (definida abaixo)
int receiveProductList_C6();                // C6:  Função a ser completada pelos alunos (definida abaixo)
int getIdProdutoUtilizador_C7();            // C7:  Função a ser completada pelos alunos (definida abaixo)
int sendClientOrder_C8(int, int);                // C8:  Função a ser completada pelos alunos (definida abaixo)
void receivePurchaseAck_C9();                // C9:  Função a ser completada pelos alunos (definida abaixo)
void trataSinalSIGUSR2_C10(int);            // C10: Função a ser completada pelos alunos (definida abaixo)
void trataSinalSIGINT_C11(int);             // C11: Função a ser completada pelos alunos (definida abaixo)
void trataSinalSIGALRM_C12(int);            // C12: Função a ser completada pelos alunos (definida abaixo)

/**
 * Main: Processamento do processo Cliente
 *       Não é suposto que os alunos alterem nada na função main()
 * @return int Exit value (RET_SUCCESS | RET_ERROR)
 */
int main() {
    so_exit_on_error((msgId = initMsg_C1()), "C1");
    so_exit_on_error(triggerSignals_C2(), "C2");
    msg = getDadosPedidoUtilizador_C3();
    so_exit_on_error(msg.msgData.infoLogin.nif, "C3");
    so_exit_on_error(sendClientLogin_C4(msg), "C4");
    configuraTemporizador_C5(MAX_ESPERA);
    so_exit_on_error(receiveProductList_C6(), "C6");
    int idProduto = getIdProdutoUtilizador_C7();
    so_exit_on_error(sendClientOrder_C8(idProduto, msg.msgData.infoLogin.pidServidorDedicado), "C8");
    receivePurchaseAck_C9();
    so_exit_on_error(-1, "ERRO: O cliente nunca devia chegar a este passo");
    return RET_ERROR;
}

/******************************************************************************
 * FUNÇÕES IPC MESSAGE QUEUES (cópia de /home/so/reference/msg-operations.c )
 *****************************************************************************/

/**
 * @brief Internal Private Function, not to be used by the students.
 */
int __msgGet( int msgFlags ) {
    int msgId = msgget( IPC_KEY, msgFlags );
    if ( msgId < 0 ) {
        so_debug( "Could not create/open the Message Queue with key=0x%x", IPC_KEY );
    } else {
        so_debug( "Using the Message Queue with key=0x%x and id=%d", IPC_KEY, msgId );
    }
    return msgId;
}

/**
 * @brief Creates an IPC Message Queue NON-exclusively, associated with the IPC_KEY, of an array of size multiple of sizeof(Aluno)
 *
 * @return int msgId. In case of error, returns -1
 */
int msgCreate() {
    return __msgGet( IPC_CREAT | 0600 );
}

/**
 * @brief Opens an already created IPC Message Queue associated with the IPC_KEY
 *
 * @return int msgId. In case of error, returns -1
 */
int msgGet() {
    return __msgGet( 0 );
}

/**
 * @brief Removes the IPC Message Queue associated with the IPC_KEY
 *
 * @param msgId IPC MsgID
 * @return int 0 if success or if the Message Queue already did not exist, or -1 if the Message Queue exists and could not be removed
 */
int msgRemove( int msgId ) {
    // Ignore any errors here, as this is only to check if the Message Queue exists and remove it
    if ( msgId > 0 ) {
        // If the Message Queue with IPC_KEY already exists, remove it
        int result = msgctl( msgId, IPC_RMID, 0 );
        if ( result < 0) {
            so_debug( "Could not remove the Message Queue with key=0x%x and id=%d", IPC_KEY, msgId );
        } else {
            so_debug( "Removed the Message Queue with key=0x%x and id=%d", IPC_KEY, msgId );
        }
        return result;
    }
    return 0;
}

/**
 * @brief Sends the passed message to the IPC Message Queue associated with the IPC_KEY
 *
 * @param msgId IPC MsgID
 * @param msg Message to be sent
 * @param msgType Message Type (or Address)
 * @return int success
 */
int msgSend(int msgId, MsgContent msg, int msgType) {
    msg.msgType = msgType;
    int result = msgsnd(msgId, &msg, sizeof(msg.msgData), 0);
    if (result < 0) {
        so_debug( "Could not send the Message to the Message Queue with key=0x%x and id=%d", IPC_KEY, msgId );
    } else {
        so_debug( "Sent the Message to the Message Queue with key=0x%x and id=%d", IPC_KEY, msgId );
    }
    return result;
}

/**
 * @brief Reads a message of the passed tipoMensagem from the IPC Message Queue associated with the IPC_KEY
 *
 * @param msgId IPC MsgID
 * @param msg Pointer to the Message to be filled
 * @param msgType Message Type (or Address)
 * @return int Number of bytes read, or -1 in case of error
 */
int msgReceive(int msgId, MsgContent* msg, int msgType) {
    int result = msgrcv(msgId, msg, sizeof(msg->msgData), msgType, 0);
    if ( result < 0) {
        so_debug( "Could not Receive the Message of Type %d from the Message Queue with key=0x%x and id=%d", msgType, IPC_KEY, msgId );
    } else {
        so_debug( "Received a Message of Type %d from the Message Queue with key=0x%x and id=%d, with %d bytes", msgType, IPC_KEY, msgId, result );
    }
    return result;
}

/******************************************************************************
 * MÓDULO CLIENTE
 *****************************************************************************/

/**
 *  O módulo Cliente é responsável pela interação com o utilizador. Após o login do utilizador,
 *  este poderá realizar atividades durante o tempo da sessão. Assim, definem-se as seguintes
 *  tarefas a desenvolver:
 */

/**
 * @brief C1    Abre a Message Queue (MSG) do projeto, que tem a KEY IPC_KEY. Deve assumir que a
 *              fila de mensagens já foi criada pelo Servidor. Em caso de erro, dá so_error e
 *              termina o Cliente. Caso contrário dá so_success <msgId>.
 *
 * @return int RET_ERROR em caso de erro, ou a msgId em caso de sucesso
 */
int initMsg_C1() {
    int result = RET_ERROR;    // Por omissão retorna erro
    so_debug("<");

     msgId = msgget(IPC_KEY,0);
    if(msgId < 0 ){
        so_error("C1","Message Queue não foi aberta ");
        return result;
    } 
    result=msgId;
    so_success("C1","%d", msgId);

    so_debug("> [@return:%d]", );
    return result;
}

/**
 * @brief C2    Arma e trata os sinais SIGUSR2 (ver C10), SIGINT (ver C11), e SIGALRM (ver C12).
 *              Em caso de qualquer erro a armar os sinais, dá so_error e termina o Cliente.
 *              Caso contrário, dá so_success.
 *
 * @return int Sucesso (RET_SUCCESS | RET_ERROR)
 */
int triggerSignals_C2() {
    int result = RET_ERROR;    // Por omissão retorna erro
    so_debug("<");

    if( signal(SIGUSR2,trataSinalSIGUSR2_C10)== SIG_ERR){
        so_error("C2", " SIGUSR2 não foi armado");
        return result;
    }else{  
        if(signal(SIGINT,trataSinalSIGINT_C11)==SIG_ERR){
            so_error("C2","SIGINT não foi armado");
            return result;
        }else{
            if(signal(SIGALRM,trataSinalSIGALRM_C12)== SIG_ERR){
                  so_error("C2","SIGALRM não foi armado");
            return result;
            }else{
            result = RET_SUCCESS;
            so_success("C2","Todos os sinais foram armados");
            }
        }
    }

    so_debug("> [@return:%d]", result);
    return result;
}

/**
 * @brief C3    Pede ao utilizador que preencha os dados referentes à sua autenticação (NIF e
 *              Senha), criando um elemento do tipo Login com essas informações, e preenchendo
 *              também o campo pidCliente com o PID do seu próprio processo Cliente. Os restantes
 *              campos da estrutura Login não precisam ser preenchidos.
 *              Em caso de qualquer erro, dá so_error e termina o Cliente.
 *              Caso contrário dá so_success <nif> <senha> <pidCliente>;
 *              Convenciona-se que se houver problemas, esta função coloca nif = USER_NOT_FOUND;
 *
 * @return Login Elemento com os dados preenchidos. Se nif==USER_NOT_FOUND,
 *               significa que o elemento é inválido
 */
MsgContent getDadosPedidoUtilizador_C3() {
    MsgContent msg;
    msg.msgData.infoLogin.nif = USER_NOT_FOUND;   // Por omissão retorna erro
    so_debug("<");
    printf("Introduza o seu Nif: \n");
    if(scanf("%d", &msg.msgData.infoLogin.nif)!= 1){
        so_error("C3", "Não foi possível ler o Nif");
    }
    
    printf("Introduza a sua senha: \n");
    if(scanf("%s", &msg.msgData.infoLogin.senha)!=1){
        so_error("C3"," Não foi possível ler a Senha");
    }
    msg.msgData.infoLogin.pidCliente= getpid();
    so_success("C3","%d %s %d", msg.msgData.infoLogin.nif,
                                msg.msgData.infoLogin.senha, msg.msgData.infoLogin.pidCliente);

    so_debug("> [@return nif:%d, senha:%s, pidCliente:%d]", msg.msgData.infoLogin.nif,
                                msg.msgData.infoLogin.senha, msg.msgData.infoLogin.pidCliente);
    return msg;
}

/**
 * @brief C4    Envia uma mensagem do tipo MSGTYPE_LOGIN para a MSG com a informação recolhida do
 *              utilizador. Em caso de erro, dá so_error. Caso contrário, dá so_success.
 *
 * @return int Sucesso (RET_SUCCESS | RET_ERROR)
 */
int sendClientLogin_C4(MsgContent msg) {
    int result = RET_ERROR;    // Por omissão retorna erro
    so_debug("<");

    if(msgSend(msgId,  msg, MSGTYPE_LOGIN)==-1){
        so_error("C4","Não enviou a mensagem");
        return result;
    }
    result=RET_SUCCESS;
    so_success("C4","Mensagem enviada");
    so_debug("> [@return:%d]", result);
    return result;
}

/**
 * @brief C5    Configura um alarme com o valor de tempoEspera segundos (ver C12), e dá
 *              so_success "Espera resposta em <tempoEspera> segundos" (não usa sleep!)
 *
 * @param tempoEspera o tempo em segundos que queremos pedir para marcar o timer do SO (i.e., MAX_ESPERA)
 */
void configuraTemporizador_C5(int tempoEspera) {
    so_debug("< [@param tempoEspera:%d]", tempoEspera);

   
    if(alarm(tempoEspera)==-1){
        so_error("C5","Erro ao armar o alarme");
        exit(1);
    }
    so_success("C5","Espera resposta em %d segundos", tempoEspera);

    so_debug(">");
}

/**
 * @brief C6    Lê da Message Queue uma mensagem cujo tipo é o PID deste processo Cliente.
 *              Se houver erro, dá so_error e termina o Cliente.
 *              Caso contrário, dá so_success <nome> <saldo> <pidServidorDedicado>.
 *        C6.1  “Desliga” o alarme configurado em C5.
 *        C6.2  Valida se o resultado da autenticação do Servidor Dedicado foi sucesso
 *              (convenciona-se que se a autenticação não tiver sucesso, o campo
 *              pidServidorDedicado==-1). Nesse caso, dá so_error, e termina o Cliente.
 *              Senão, escreve no STDOUT a frase “Lista de Produtos Disponíveis:”.
 *        C6.3  Extrai da mensagem recebida o Produto especificado.
 *              Se o campo idProduto tiver o valor FIM_LISTA_PRODUTOS, convencionou-se que
 *              significa que não há mais produtos a listar, então dá so_success
 *              e retorna sucesso (vai para C7).
 *        C6.4  Mostra no STDOUT uma linha de texto com a indicação de idProduto, Nome,
 *              Categoria e Preço.
 *        C6.5  Lê da Message Queue uma nova mensagem cujo tipo é o PID deste processo Cliente.
 *              Se houver erro, dá so_error e termina o Cliente.
 *              Caso contrário, volta ao passo C6.3.
 *
 * @return int Sucesso (RET_SUCCESS | RET_ERROR)
 */
int receiveProductList_C6() {
    int result = RET_ERROR;    // Por omissão retorna erro
    so_debug("<");
    MsgContent reply;
    reply.msgType = getpid();
    if(msgrcv(msgId,&reply, sizeof(reply.msgData),reply.msgType,0) == -1){
            so_error("C6", " A mensagem não foi recebida");
            return result;
        }
        so_success("C6","%s %d %d ", reply.msgData.infoLogin.nome,
         reply.msgData.infoLogin.saldo, reply.msgData.infoLogin.pidServidorDedicado);
    //C6.1
    alarm(0);
    
    //C6.2
    if( reply.msgData.infoLogin.pidServidorDedicado==-1){
        so_error("C6.2","Servidor Dedicado não Autenticado");
        return result;
    }
    
    so_success("C6.3","Servidor autenticado");
       
    printf("Lista de Produtos Disponíveis: \n ");
    
    while( 1){
        so_success("C6.3"," Mensagem recebida");

        if(reply.msgData.infoProduto.idProduto == FIM_LISTA_PRODUTOS){
            so_success("C6.3"," Lista completa");
            break;
        }
        
        // 6.4
        printf(" %d %s %s %d \n", 
                reply.msgData.infoProduto.idProduto,reply.msgData.infoProduto.nomeProduto,
                reply.msgData.infoProduto.categoria,reply.msgData.infoProduto.preco);

        if(msgrcv(msgId,&reply, sizeof(reply.msgData),reply.msgType,0) == -1){
            so_error("C6.5", " A mensagem não foi recebida");
            return result;
        }
        
    
    }
    result= RET_SUCCESS;
    
    so_debug("> [@return:%d]", result);
    return result;
}

/**
 * @brief C7    Pede ao utilizador que indique qual o idProduto (número) que deseja adquirir.
 *              Não necessita validar se o valor inserido faz parte da lista apresentada.
 *              Em caso de qualquer erro, dá so_error e retorna PRODUCT_NOT_FOUND.
 *              Caso contrário dá so_success <idProduto>, e retorna esse idProduto.
 *
 * @return int em caso de erro retorna RET_ERROR. Caso contrário, retorna um idProduto
 */
int getIdProdutoUtilizador_C7() {
    int result = RET_ERROR;    // Por omissão retorna erro
    so_debug("<");

    int idproduto;
    printf("Introduza o Id do produto que prentede adquirir: \n ");
    if(scanf("%d",&idproduto)!= 1){
        so_error("C7", "Não foi possível obter o Id");
        return result;
    }
    result=idproduto;
    so_success("C7", "%d", idproduto);

    so_debug("> [@return:%d]", result);
    return result;
}

/**
 * @brief C8    Envia uma mensagem cujo tipo é o PID do Servidor Dedicado para a MSG com a
 *              informação do idProduto recolhida do utilizador. Em caso de erro, dá so_error.
 *              Caso contrário, dá so_success.
 *
 * @param idProduto O produto pretendido pelo Utilizador
 * @return int Sucesso (RET_SUCCESS | RET_ERROR)
 */
int sendClientOrder_C8(int idProduto, int pidServidorDedicado) {
    int result = RET_ERROR;    // Por omissão retorna erro
    so_debug("<");
        msg.msgType = pidServidorDedicado;
        msg.msgData.infoProduto.idProduto = idProduto;
        if(msgsnd(msgId, &msg,sizeof(msg.msgData),0)==-1){
            so_error("C8", "Mensagem não enviada");
            return result;
        }
        so_success("C8","Mensagem enviada");
        result=RET_SUCCESS;
   

    so_debug("> [@return:%d]", result);
    return result;
}

/**
 * @brief C9    Lê da MSG uma mensagem cujo tipo é o PID deste processo Cliente, com a resposta
 *              final do Servidor Dedicado. Em caso de erro, dá so_error. Caso contrário, dá
 *              so_success <idProduto>. Se o campo idProduto for PRODUTO_COMPRADO, escreve no
 *              STDOUT “Pode levantar o seu produto”. Caso contrário, escreve no STDOUT
 *              “Ocorreu um problema na sua compra. Tente novamente”.
 *              Em ambos casos, termina o Cliente.
 *
 * @return int Sucesso (RET_SUCCESS | RET_ERROR)
 */
void receivePurchaseAck_C9() {
    int result = RET_ERROR;    // Por omissão retorna erro
    so_debug("<");
    if(msgrcv(msgId, &msg, sizeof(msg.msgData),getpid(),0)== -1){
        so_error("C9","Mensagem não foi recebida");
        exit(RET_ERROR);
    }
    if(msg.msgData.infoProduto.idProduto == PRODUTO_COMPRADO){
        printf("Pode levantar o seu produto \n");
    }else{
        printf("Ocorreu um problema na sua compra. Tente novamente\n");
    }
    so_success("C9","%d",msg.msgData.infoProduto.idProduto );
    
    so_debug(">");
     exit(RET_SUCCESS);
}

/**
 * @brief C10   O sinal armado SIGUSR2 serve para o Servidor Dedicado indicar que o servidor
 *              está em modo shutdown. Se o Cliente receber esse sinal, dá so_success e
 *              termina o Cliente.
 *
 * @param sinalRecebido nº do Sinal Recebido (preenchido pelo SO)
 */
void trataSinalSIGUSR2_C10(int sinalRecebido) {
    so_debug("< [@param sinalRecebido:%d]", sinalRecebido);

      if(sinalRecebido!=SIGUSR2){
        so_error("C10","SIGUSR2 não foi recebido");
    }
    so_success("C10","SIGUSR2 recebido");
    exit(0);

    so_debug(">");
}

/**
 * @brief C11   O sinal armado SIGINT serve para que o utilizador possa cancelar o pedido do
 *              lado do Cliente, usando o atalho <CTRL+C>. Se receber esse sinal (do utilizador
 *              via Shell), o Cliente dá so_success "Shutdown Cliente", e termina o Cliente.
 *
 * @param sinalRecebido nº do Sinal Recebido (preenchido pelo SO)
 */
void trataSinalSIGINT_C11(int sinalRecebido) {
    so_debug("< [@param sinalRecebido:%d]", sinalRecebido);

     if(sinalRecebido!=SIGINT){
        so_error("C11","SIGINT não foi recebido");
    }
    so_success("C11","Shutdown Cliente");
    exit(0);
    so_debug(">");
}

/**
 * @brief C12   O sinal armado SIGALRM serve para que, se o Cliente em C6 esperou mais do que
 *              MAX_ESPERA segundos sem resposta, o Cliente dá so_error "Timeout Cliente", e
 *              termina o Cliente.
 *
 * @param sinalRecebido nº do Sinal Recebido (preenchido pelo SO)
 */
void trataSinalSIGALRM_C12(int sinalRecebido) {
    so_debug("< [@param sinalRecebido:%d]", sinalRecebido);

     if(sinalRecebido!=SIGALRM){
        so_error("C12","SIGALRM não foi recebido");
    }
        so_error("C12","Timeout Cliente");
        exit(0);

    so_debug(">");
}