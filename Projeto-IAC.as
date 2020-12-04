
;                           Projeto IAC

;ist199333(Tiago Santos)                  ist1100120 (Alexandre Coelho)


;===============================================================================
; CONSTANTS
;===============================================================================
; 7 segment display
DISP7_D0        EQU     FFF0h
DISP7_D1        EQU     FFF1h
DISP7_D2        EQU     FFF2h
DISP7_D3        EQU     FFF3h
DISP7_D4        EQU     FFEEh
DISP7_D5        EQU     FFEFh
; timer
TIMER_CONTROL   EQU     FFF7h
TIMER_COUNTER   EQU     FFF6h
TIMER_SETSTART  EQU     1
TIMER_SETSTOP   EQU     0h
SWITCHES        EQU     FFF9h
;terminal
TERM_READ       EQU     FFFFh
TERM_WRITE      EQU     FFFEh
TERM_STATUS     EQU     FFFDh
TERM_CURSOR     EQU     FFFCh
TERM_COLOR      EQU     FFFBH
; interruptions
INT_MASK        EQU     FFFAh
INT_MASK_VAL    EQU     80FFh ; 1000 0000 0000 0011 b
;Tabuleiro
DINO_COLUMN     EQU     10 ; Coluna do terreno onde fica o dinossauro
DIM             EQU     80
STACKBASE       EQU     7000h 
FLOOR_LEVEL     EQU     15 ; Altura da plataforma em relacao ao final do terminal 
SCORE_INCREMENT EQU     13; for good luck

;Posicoes de escrita
CURSOR_POSFINAL EQU     0001011100100001b; Linha: 23 | Coluna: 33  -> 0F28H

;Cores de escrita
RGB_FLOOR       EQU     92H; Cor da plataforma de jogo
RGB_CACTUS      EQU     35H; Cor dos obstaculos
RGB_DINO        EQU     FEH; Cor do dinossauro
DINO_CHAR       EQU     'ß';Simbolo que representa o dinossauro no terminal.
HARDMODE        EQU     2000; Valor que determina a partir de que valor
;                             de score o jogo entra no hardmode

;===============================================================================
; Variables
;===============================================================================

ORIG            6000h

TABULEIRO       TAB     DIM; Inicializacao de um vetor com DIM posicoes
ALTURA_DINO     WORD    FLOOR_LEVEL ; Altura inicial do dinosauro e zero em relacao a plataforma
SCORE           WORD    0h; Valor do score
SCORE_DISPLAY   TAB     5; Numero de digitos que representarao score
POWERS_TEN      STR     10000, 1000, 100, 10, 1
INITIAL_MESSAGE STR     'W E L C O M E !0'; Mensagem de inicio de jogo
FINAL_MESSAGE   STR     'G A M E O V E R0'; Mensagem de final de jogo
WIN_MESSAGE     STR     'Y O U   W O N !0'; Mensagem de vitoria de jogo
SEED            WORD    5; Valor que permite obter padroes de obstaculos diferentes
ACELERACAO_Y    WORD    4H ;Aceleracao > 0, dinossauro comeca o jogo a saltar
FLOOR_CHAR      WORD    '█'; Caracter que representa a plataforma
BACKGROUND_CHAR WORD    '█'; Caracter que representa o fundo de jogo
CACTUS_CHAR     WORD    '▒'; Caracter que representa os obstaculos
BACKGROUND      WORD    33h; Cor de fundo de jogo
TIMER_COUNTVAL  WORD    1; Velocidade de jogo
ALTURAMAX       WORD    4 ;Altura maxima de cacto e de salto



ORIG            0000h
Main:           
                ;Necessario para que, num recomeco, volte ao easy mode
                MVI     R1, 33h
                MVI     R2, BACKGROUND
                STOR    M[R2], R1
                MVI     R1, 2
                MVI     R2, TIMER_COUNTVAL
                STOR    M[R2], R1
                MVI     R1, ALTURAMAX
                MVI     R2, 4
                STOR    M[R1], R2
                
                MVI     R1, 10 ;Intervalo temporal maior para que o jogador tenha tempo para se preparar 
                MVI     R2, TIMER_COUNTER
                STOR    M[R2], R1
                MVI     R1, TIMER_CONTROL
                MOV     R2, R0 
                STOR    M[R1], R2 ;Para o timer, no caso de este estar ligado
                
                ;Repor valor inicial das variaveis
                MVI     R6, STACKBASE
                MVI     R2, INT_MASK_VAL
                MVI     R1, INT_MASK
                STOR    M[R1], R2
                
                ;Fazer o dinossauro saltar no inicio
                MVI     R1, ACELERACAO_Y
                MVI     R2, 4H ;(NECESSARIO senao dinossauro so salta no inicio do primeiro jogo)
                STOR    M[R1], R2
                
                MVI     R1, SCORE
                STOR    M[R1], R0 ; score = 0 
                MVI     R1, ALTURA_DINO
                MVI     R2, FLOOR_LEVEL
                STOR    M[R1], R2 ; Dinossauro comeca ao nivel do chao
                
                
                MOV     R1, R0
                
                ENI

LOOP:
                MVI     R2, INT_MASK_VAL; Espera que o jogador inicie o jogo ao clicar no botao '0'
                AND     R1, R1, R2
                CMP     R1, R0
                BR.Z    LOOP
                
                MVI     R1, CURSOR_POSFINAL
                MVI     R2, INITIAL_MESSAGE; Print da mensagem inicial
                JAL     WRITE_TERM
                JAL     PRINT_FLOOR; Representacao visual da plataforma de jogo
                     
                ;Inicia o timer
                MVI     R1, TIMER_CONTROL
                MVI     R2, TIMER_SETSTART
                STOR    M[R1], R2
     
;As funcoes de jogo sao chamadas pela rotina de interrupcao do temporizador
Jogo:
                BR      Jogo
                
;===============================================================================
;PRINT_DINO:
;===============================================================================
;Esta funcao escreve o dinossauro no terminal
;Parametros de entrada: R1- Altura a que o dinossauro se encontra
;

PRINT_DINO:     
                DEC     R6
                STOR    M[R6], R4
                DEC     R6
                STOR    M[R6], R5
                DEC     R6
                STOR    M[R6], R7
                
                ;Linha onde esta o dinossauro
                MVI     R2, 0100H; Valor que se deve subtrair para obter a linha anterior
                MVI     R5, 2C00H; Valor da linha inicial
GET_LINE_LOOP:  
                CMP     R1, R0
                BR.Z    GET_COLUMN; Se o dinossauro esta no chao
                SUB     R5, R5, R2
                DEC     R1
                BR      GET_LINE_LOOP

GET_COLUMN:     
                ;Set color = BACKGROUND
                MVI     R1, TERM_COLOR
                MVI     R2, BACKGROUND
                LOAD    R2, M[R2]
                STOR    M[R1], R2
                MVI     R1, BACKGROUND_CHAR ; R1 = caracter a usar na limpeza
                LOAD    R1, M[R1]
                DEC     R6
                STOR    M[R6], R1 ;Caracter e passado pela pilha
                MVI     R1, DINO_COLUMN ; R1 = Primeira posicao a limpar
                MVI     R4, FLOOR_LEVEL
                MVI     R2, 45
                SUB     R2, R2, R4 ;Numero linhas a limpar = num. total - floor
                
                JAL     WRITE_COLUMN
                
                ;Set: color = RGB_DINO | background color = RGB_BACKGROUND 
                MVI     R2, TERM_COLOR
                MVI     R1, BACKGROUND
                LOAD    R1, M[R1]
                JAL     SHIFT_LEFT_8; Cor background do caracter
                MVIL    R1, RGB_DINO
                STOR    M[R2], R1
                ;Obtain cursor position for bottom part of Dino
                MVI     R1, DINO_COLUMN
                ADD     R5, R5, R1
                MVI     R1, TERM_CURSOR
                STOR    M[R1], R5
                MVI     R1, TERM_WRITE ;Print Dino bottom
                MVI     R2, DINO_CHAR
                STOR    M[R1], R2
                ;Obtain cursor position for top part of Dino
                MVI     R2, 0100H
                SUB     R5, R5, R2
                MVI     R1, TERM_CURSOR
                STOR    M[R1], R5
                MVI     R1, TERM_WRITE ;Print Dino Top
                MVI     R2, DINO_CHAR
                STOR    M[R1], R2   
                
                LOAD    R7, M[R6]
                INC     R6
                LOAD    R5, M[R6]
                INC     R6
                LOAD    R4, M[R6]
                INC     R6
                
                JMP     R7
;===============================================================================
;PRINT_CACTUS:
;===============================================================================
;Escreve, no terminal, os cactus do jogo.
;Recebe como parametro de entrada: R2- Tabuleiro
;
PRINT_CACTUS:   
                DEC     R6 
                STOR    M[R6], R4
                DEC     R6
                STOR    M[R6], R5
                DEC     R6
                STOR    M[R6], R7
                
                ;Set color = RGB_CACTUS
                MVI     R1, TERM_COLOR
                MVI     R4, RGB_CACTUS
                STOR    M[R1], R4
                
                MOV     R1, R0 ; R1 = coluna onde sera escrito o cato
                
LOOP_CACTO:     
                ;Obter altura do cato na coluna R1
                MVI     R2, TABULEIRO
                ADD     R2, R2, R1
                LOAD    R2, M[R2]
                CMP     R2, R0
                BR.Z    NO_CACTUS ; R2 = altura cacto se R2=0 -> proxima coluna
                ;Salvaguardar R1 (coluna atual)
                DEC     R6
                STOR    M[R6], R1
                MVI     R4, 45
                MVI     R5, FLOOR_LEVEL 
                SUB     R4, R4, R5
                SUB     R4, R4, R2;R4 = linha a partir da qual sera escrito cato
                MOV     R1, R4
                JAL     SHIFT_LEFT_8 ;Coloca numero linha nos 8 bits + signif.
                LOAD    R4, M[R6] ;Recuperar numero da coluna atual
                ADD     R1, R1, R4 ; R1 = (no. linha)(no. coluna)
                MVI     R4, CACTUS_CHAR ;Obter  
                LOAD    R4, M[R4]; R4 = caracter a usar para escrever cato
                DEC     R6
                STOR    M[R6], R4 ;Caracter do cato e passado pela pilha
                JAL     WRITE_COLUMN ;R2 = altura do cato
                ;WRITE_COLUMN posiciona R6 acima do argumento passado na pilha
                LOAD    R1, M[R6] 
                INC     R6
NO_CACTUS:      
                ;Verificar se ultimo cato foi escrito
                INC     R1
                MVI     R2, 80
                CMP     R1, R2 ;Se R1 = 80 todo o tabuleiro foi iterado
                BR.NZ   LOOP_CACTO

                LOAD    R7, M[R6]
                INC     R6
                LOAD    R5, M[R6]
                INC     R6
                LOAD    R4, M[R6]
                INC     R6
                
                JMP     R7
                
;===============================================================================
;SHIFT_LEFT_8:
;===============================================================================
;Realiza 8 SHL a R1 (00aah -> aa00h)
;Parametro de entrada: R1- Valor a ser alterado

SHIFT_LEFT_8:   
                SHL     R1
                SHL     R1
                SHL     R1
                SHL     R1
                SHL     R1
                SHL     R1
                SHL     R1
                SHL     R1
                
                JMP     R7

;===============================================================================
;PRINT_BACKGROUND:
;===============================================================================
;Esta funcao escreve o fundo de jogo
;A funcao nao possui parametros de entrada 

PRINT_BACKGROUND:
                DEC     R6
                STOR    M[R6], R7
                ;Set color = RGB_BACKGROUND
                MVI     R1, TERM_COLOR
                MVI     R2, BACKGROUND
                LOAD    R2, M[R2]
                STOR    M[R1], R2
                MOV     R1, R0; R1 = coluna a alterar = posicao cursor (linha=0)
BACKGROUND_LOOP:
                MVI     R2, DINO_COLUMN
                CMP     R1, R2
                BR.Z    SKIP_DINO ;Se for a coluna do dino nao faz alteracoes
                DEC     R6
                STOR    M[R6], R1 ;Salvaguardar o valor de R1 (coluna atual)
                MVI     R3, BACKGROUND_CHAR ;Caracter para escrever o background
                LOAD    R3, M[R3]
                DEC     R6
                STOR    M[R6], R3 ; Caracter e passado pela pilha 
                MVI     R2, 45 
                MVI     R3, FLOOR_LEVEL
                SUB     R2, R2, R3 ; Numero de linhas a escrever
                JAL     WRITE_COLUMN
                LOAD    R1, M[R6]; POP de R1
                INC     R6
SKIP_DINO:    
                INC     R1
                MVI     R2, 80 ;Quando R1 = 80 todas as linhas foram limpas
                CMP     R1, R2
                BR.N    BACKGROUND_LOOP
                
                LOAD    R7, M[R6]
                INC     R6
                
                JMP     R7

;===============================================================================
;WRITE_COLUMN:
;===============================================================================
;Esta funcao escreve no terminal
;Parametros de entrada: R1- endereco da primeira posicao do terminal a tratar
;                       R2- o numero de linhas a limpar a contar do topo
;                       valor pilha- caracter a usar para a 'limpeza'


WRITE_COLUMN:
                DEC     R6 ; R6i-1
                STOR    M[R6], R5
                INC     R6 ; R6i
                LOAD    R5, M[R6] ;R5 = valor pilha
                MVI     R3, 2
                SUB     R6, R6, R3
                STOR    M[R6], R4
                
                MVI     R3, 0100H
                
CLEAR_COLUMN_LOOP:
                
                CMP     R2, R0
                BR.Z    STOP
                MVI     R4, TERM_CURSOR
                STOR    M[R4], R1 ;Posicionar cursor
                MVI     R4, TERM_WRITE
                STOR    M[R4], R5 ;Escrever caracter
                ADD     R1, R1, R3 ;Obter posicao do caracter da proxima linha
                DEC     R2 ;Decrementar contador
                BR      CLEAR_COLUMN_LOOP
STOP:           
                LOAD    R4, M[R6]
                INC     R6
                LOAD    R5, M[R6]
                INC     R6
                INC     R6 ;Posicionar R6 acima do argumento na pilha
                
                JMP     R7
                
;===============================================================================
;ATUALIZAJOGO:
;===============================================================================
;Esta funcao recorre a funcao GeraCacto e gera, infinitamente, tabuleiros 
;de jogo consecutivamente diferentes
;
;Parametros de entrada: R1- Tabuleiro de jogo
;                       R2- Dimensao do tabuleiro
;
;Retorno: Altera a variavel em R1.

AtualizaJogo:   
                DSI
                MOV     R5, R2
                MOV     R2, R1
                INC     R2 ;R2 = endereco segunda posicao tabuleiro
                DEC     R5 ;R5 = 79 (numero de translacoes de elementos)
LOOP_Atualiza:  
                LOAD    R2, M[R2]
                STOR    M[R1], R2
                INC     R1
                MOV     R2, R1
                INC     R2
                DEC     R5
                CMP     R5, R0
                BR.Z    ultimo ;Apos 79 translacoes gera um novo elemento
                BR      LOOP_Atualiza

ultimo:
                DEC     R6
                STOR    M[R6], R7
                ;Salvaguardar a posicao do tabuleiro onde sera gerado cacto
                DEC     R6
                STOR    M[R6], R1
                DEC     R6
                STOR    M[R6], R2
                ;Obter altura do cacto
                MVI     R1, SEED
                LOAD    R1, M[R1] ;R1 = SEED
                MVI     R2, ALTURAMAX
                LOAD    R2, M[R2]
                JAL     GeraCacto
                ;Guardar o valor da altura do cacto gerado na ultima pos do tab
                LOAD    R2, M[R6]
                INC     R6
                LOAD    R1, M[R6] ;Recupera posicao do tabuleiro
                INC     R6
                STOR    M[R1], R3 ;Guarda altura do cato nessa posicao
                ;Retorna para funcao "Jogo"
                LOAD    R7, M[R6]
                INC     R6
                ENI
                JMP     R7
;===============================================================================
;GERACACTO:
;===============================================================================
;A funcao retorna um valor pseudo-aleatorio em funcao do valor de R1
;Parametros de entrada: R1- valor da seed
;                       R2- altura maxima dos cactus
;Retorna um valor R3

GeraCacto:
                ;Salvaguardar valor de R4
                DEC     R6
                STOR    M[R6], R4
                MOV     R4, R2
                MVI     R2, 1
                AND     R2, R1, R2 ;bit = x & 1
                SHR     R1 ;Dividir seed por dois
                CMP     R2, R0
                BR.Z    ZERO ; if !bit: nao fazer XOR
                MVI     R2, b400h
                XOR     R1, R1, R2 ;Altera potencialmente todos os bits da seed

ZERO:
                MVI     R2, 62258d ;numero muito grande -> numero (pouco) negativo
                CMP     R1, R0
                BR.N    NEGATIVO ;Se seed e nao negativa nao e gerado cato
                MOV     R3, R0
                BR      FIM_GERACACTO

NEGATIVO:
                CMP     R1, R2 
                BR.NC   POSITIVO ;Se R1 for maior ou igual que R2 gerar cacto
                MOV     R3, R0
                BR      FIM_GERACACTO

POSITIVO:
                ;Gerar cacto -> formula providenciada no enunciado
                DEC     R4 
                AND     R3, R4, R1
                INC     R3
                BR      FIM_GERACACTO

FIM_GERACACTO:  
                ;Guardar o valor alterado da seed
                MVI     R4, SEED
                STOR    M[R4], R1
                ;Repor o valor dos registos R4 e R5
                LOAD    R4, M[R6]
                INC     R6
                ;Volta para atualizajogo
                JMP     R7
                
;===============================================================================
;CHECK_DINO:
;===============================================================================
;Verifica se o dinossauro esta numa posicao de continuar o jogo.
;Parametros de entrada: R2- Tabuleiro
;                       R1- Coluna do Dinossauro
;
CHECK_DINO:     
                ;Determinar o estado da coluna de terreno do dinossauro
                ADD     R1, R2, R1 ;R1 = endereco memoria da coluna dinossauro
                LOAD    R2, M[R1] ;R2 = altura do cato da coluna dinossauro
                CMP     R2, R0
                ;Se altura cacto == 0 dinossauro nao pode colidir
                BR.Z    CONTINUA_JOGO 
                MVI     R1, ALTURA_DINO
                LOAD    R1, M[R1] ;R1 = altura do dinossauro
                MVI     R3, FLOOR_LEVEL ;R3 = nivel do chao
                SUB     R1, R1, R3 ;R1 = altura do dinossauro relativa ao chao
                CMP     R1, R2 ;Comparar altura relativa ao chao com altura cato
                BR.NP   END_OF_GAME;Se altura > 0 nao ha colisao

CONTINUA_JOGO:  
                JMP     R7
;===============================================================================
;END_OF_GAME:
;===============================================================================
;Esta e a funcao terminal do jogo, e chamada quando o jogo acaba.
;A funcao mete o terminal no estado terminal e prepara para voltar ao
;estado de espera por um novo jogo
;Esta funcao nao possui parametros de entrada.
END_OF_GAME:
                DSI     ;Disable interruptions -> game is over

                ;Reset background color
                DSI
                MVI     R2, BACKGROUND
                MVI     R1, 33h
                STOR    M[R2], R1

                ;Clear terminal
                MVI     R1, FFFFH
                MVI     R2, TERM_CURSOR
                STOR    M[R2], R1

                ;Reset terminal color
                MVI     R1, TERM_COLOR
                MVI     R2, FFH
                STOR    M[R1], R2

                ;Limpa o terminal para um jogo novo
                MOV     R2, R0
                MVI     R3, DIM
                DEC     R3
                JAL     CLEAR_BOARD

                ;Verifica o score
                MVI     R1, SCORE
                LOAD    R1, M[R1]
                MVI     R2, 7FFFH ;Score maximo em complemento para 2

                ;Se R1 > R2 em binario, R1 e negativo em Cp2.
                ;positive number -> R1 - R2 will overflow
                CMP     R1, R2
                BR.O    WIN ;Se der overflow, player ganhou

                ; Escreve "G A M E O V E R" no terminal
                MVI     R1, CURSOR_POSFINAL
                MVI     R2, FINAL_MESSAGE
                JAL     WRITE_TERM
                BR      NEW_GAME

WIN:
                ; Escreve "Y O U   W O N !" no terminal.
                MVI     R1, CURSOR_POSFINAL
                MVI     R2, WIN_MESSAGE
                JAL     WRITE_TERM

NEW_GAME:
                JMP     Main
;===============================================================================
;CLEAR_BOARD:
;===============================================================================
;Funcao auxiliar de END_OF_GAME, limpa o tabuleiro e o terminal

CLEAR_BOARD:
                MVI     R1, TABULEIRO
                ADD     R1, R1, R2
                STOR    M[R1], R0
                INC     R2
                CMP     R2, R3
                BR.N    CLEAR_BOARD

                JMP     R7

;===============================================================================
;WRITE_TERM:
;===============================================================================
;Escreve uma mensagem no terminal
;Parametros de entrada: R1- Posicao no terminal
;                       R2- Mensagem pretendida

WRITE_TERM:     
                DEC     R6
                STOR    M[R6], R4
                DEC     R6
                STOR    M[R6], R5

                ;Colocar o cursor em posicao
                MVI     R5, TERM_CURSOR
                STOR    M[R5], R1
                MVI     R5, TERM_WRITE

                ;Escrever a mensagem
WRITE_TERM_LOOP:
                ;Obter caracter a escrever no terminal
                LOAD    R1, M[R2]
                INC     R2
                ;Verificar caso terminal
                MVI     R4, '0'
                CMP     R1, R4
                BR.Z    TERM_END
                ;Apresentar caracter
                STOR    M[R5], R1
                
                BR      WRITE_TERM_LOOP
                
TERM_END:       
                LOAD    R5, M[R6]
                INC     R6
                LOAD    R4, M[R6]
                INC     R6
                
                JMP     R7
;===============================================================================
;PRINT_SCORE:
;===============================================================================
;Escreve o score no mostrador de 7 segmentos num dado momento do jogo
;Parametros de entrada: R1- Score
;
PRINT_SCORE:    
                ;Salvaguardar o valor de R4 e R5
                DEC     R6 
                STOR    M[R6], R4
                DEC     R6 
                STOR    M[R6], R5
                
                ;O score max = 5fffh, logo so usa 5 segmentos
                MVI     R2, DISP7_D5
                STOR    M[R2], R0 ;Certificar que o sexto segmento apresenta 0
                
                ;Verificar se score esta dentro dos limites
                MVI     R2, 7FFFH ;Maior valor positivo em complemento para dois
                CMP     R1, R2
                BR.O    END_OF_GAME
                ;Display a partir do qual serao apresentados os digitos
                MVI     R2, DISP7_D4
                MVI     R4, POWERS_TEN
                ;Subtrair sucessivamente potencias de 10 ao valor de score para
                ;obter os digitos em base 10 a apresentar
LOOP_SCORE:     
                MOV     R3, R0 ;Inicialmente subtraimos 0 vezes R5 de R1
                ;Colocar a potencia de 10 em R5 (o e o caso terminal)
                LOAD    R5, M[R4]
                
SUBTRACTIONS:   
                CMP     R1, R5
                BR.N    DISPLAY_DIGIT;Se R1<R5 guardar R3 (numero de subtracoes)
                ;Se R1 > R5 subtrair R5 a R1
                SUB     R1, R1, R5
                INC     R3
                ;Repetir o processo ate R1 < R5
                BR      SUBTRACTIONS
                
DISPLAY_DIGIT:   
                ;Display do digito no local adequado
                STOR    M[R2], R3
                
                ;Verificar se R2 = DISP7_D4
                MVI     R5, FFEEH
                CMP     R2, R5
                BR.NZ   NOT_DISP7_D4
                MVI     R2, FFF3H ; R2 = DISP7_D3
                INC     R4
                BR      LOOP_SCORE
                
NOT_DISP7_D4:   
                ;Verificar se display do score esta terminado
                MVI     R5, FFF0H
                CMP     R2, R5
                BR.Z    END_SCORE
                ;Preparar display do proximo digito
                DEC     R2 
                INC     R4 ;Preparar proxima potencia de 10
                BR      LOOP_SCORE


END_SCORE:      
                LOAD    R5, M[R6]
                INC     R6
                LOAD    R4, M[R6]
                INC     R6
                JMP     R7      
;===============================================================================
;PRINT_FLOOR:
;===============================================================================
;Esta funcao escreve o chao do jogo no terminal


PRINT_FLOOR:     
                DEC     R6
                STOR    M[R6],R4
                DEC     R6
                STOR    M[R6], R7
                ;Set color = RGB_FLOOR
                MVI     R1, TERM_COLOR
                MVI     R2, RGB_FLOOR
                STOR    M[R1], R2
                ;Escreve chao
                MVI     R1, FLOOR_LEVEL ;Obter primeira linha a tratar
                MVI     R2, 45
                SUB     R1, R2, R1 ;R1 = primeira linha a tratar
                JAL     SHIFT_LEFT_8 ;Colocar linha nos 8 bits + significativos
                
FLOOR_COLUMN_LOOP: 
                MVI     R4, FFh
                AND     R4, R1, R4;Numero da coluna tratada na iteracao anterior
                MVI     R3, 80d 
                CMP     R4, R3 ;Se R4 = 80 -> o chao esta escrito
                BR.Z    FLOOR_WRITTEN 
                DEC     R6
                STOR    M[R6], R1 ; Guardar a posicao da coluna atual
                MVI     R2, FLOOR_CHAR
                LOAD    R2, M[R2]; Caracter a usar
                DEC     R6
                STOR    M[R6], R2 ;Caracter passado atraves da pilha
                MVI     R2, FLOOR_LEVEL ;Numero de linhas a escrever
                JAL     WRITE_COLUMN
                LOAD    R1, M[R6]
                INC     R6
                INC     R1 ;Passar a coluna seguinte
                BR      FLOOR_COLUMN_LOOP
                
FLOOR_WRITTEN:; Funcao acabou, retorno dos valores e salto de volta
                LOAD    R7, M[R6]
                INC     R6
                LOAD    R4, M[R6]
                INC     R6
                
                JMP     R7

;===============================================================================
;ACCELERATION:
;===============================================================================
;Esta função trata da altura do dinossauro em relação a aceleração que 
;este tem, proveniente dos saltos efetuados
;Parametros de entrada: R1- AceleracaoY atual do dinossauro
;
ACCELERATION:     
                DEC     R6
                STOR    M[R6], R4
                
                CMP     R1, R0
                BR.Z    END_ACCELERATION ; se aceleracao == 0 nao se realizam alteracoes
                ;Acelaracao != 0, altura = altura + aceleracao
                MVI     R4, ALTURA_DINO
                LOAD    R2, M[R4]
                ADD     R2, R2, R1
                STOR    M[R4], R2
                ;Atualizacao valor aceleracao
                MVI     R2, 1
                CMP     R1, R2 
                BR.Z    UM; Se aceleracao == 1 a aceleracao fica negativa
                BR.N    NEGATIVE; Se aceleracao < 1 tratamento de acel. neg.                
                
                SHR     R1; Divide R1 por 2 -> fica menos positivo
                MVI     R2, ACELERACAO_Y
                STOR    M[R2], R1
                BR      END_ACCELERATION

UM:             
                NEG     R1
                MVI     R2, ACELERACAO_Y
                STOR    M[R2], R1 ; aceleracao = -1
                BR      END_ACCELERATION
                
NEGATIVE:       
                ;Se aceleracao == - ALTURAMAX o dinossauro chega ao solo
                MVI     R2, ALTURAMAX
                LOAD    R2, M[R2]
                NEG     R2
                CMP     R1, R2
                BR.NP   ZERO_ACCELERATION
                ;Caso aceleracao nao seja maior que -4 diminuir aceleracao
                SHL     R1 ;Multiplica R1 por 2 -> fica mais negativo
                MVI     R2, ACELERACAO_Y
                STOR    M[R2], R1 
                BR      END_ACCELERATION
                
ZERO_ACCELERATION:     
                MVI     R1, ACELERACAO_Y
                STOR    M[R1], R0 ; aceleracaoY = 0
                ;Dinossauro fica no solo
                MVI     R1, FLOOR_LEVEL
                MVI     R2, ALTURA_DINO
                STOR    M[R2], R1
                BR      END_ACCELERATION
                
END_ACCELERATION: 
                LOAD    R4, M[R6]
                INC     R6
                
                JMP     R7
                
;===============================================================================
;TIMER_AUX:
;===============================================================================
;Funcao auxiliar da rotina de tratamento da interrupao do temporizador
                
TIMER_AUX:      

                DEC     R6
                STOR    M[R6], R1
                DEC     R6
                STOR    M[R6], R2
                DEC     R6
                STOR    M[R6], R4
                DEC     R6
                STOR    M[R6], R7
                
                MVI     R1, TIMER_COUNTVAL
                LOAD    R1, M[R1]
                MVI     R2, TIMER_COUNTER
                STOR    M[R2], R1 ;Definir o tamanho do interalo de tempo

                MVI     R1, TABULEIRO
                MVI     R2, DIM
                JAL     AtualizaJogo
                
                MVI     R1, ACELERACAO_Y
                LOAD    R1, M[R1]
                JAL     ACCELERATION
                
                MVI     R2, TABULEIRO
                MVI     R1, DINO_COLUMN
                JAL     CHECK_DINO
                
                MVI     R1, ALTURA_DINO
                LOAD    R1, M[R1]
                JAL     PRINT_DINO
                
                JAL     PRINT_BACKGROUND
                
                MVI     R2, TABULEIRO
                JAL     PRINT_CACTUS
                
                MVI     R1, SCORE
                LOAD    R1, M[R1]
                JAL     PRINT_SCORE
                
                ;Incrementar score
                MVI     R1, SCORE
                LOAD    R1, M[R1]
                MVI     R2, SCORE_INCREMENT
                ADD     R1, R1, R2
                MVI     R2, SCORE
                STOR    M[R2], R1
                
                ; Verifica se ja se pode por no HARDMODE
                MVI     R2, HARDMODE
                CMP     R1, R2
                BR.N    EASY; Se a condicao for verificada, passa para o hardmode, velocidadex2 e background de jogo diferente(simulando planeta diferente)
                MVI     R1, 45h
                MVI     R2, BACKGROUND
                STOR    M[R2], R1
                MVI     R1, 1
                MVI     R2, TIMER_COUNTVAL
                STOR    M[R2], R1
                MVI     R1, ALTURAMAX
                MVI     R2, 8
                STOR    M[R1], R2
                
                
EASY:
                
                MVI     R1, TIMER_CONTROL;Start timer
                MVI     R2, TIMER_SETSTART
                STOR    M[R1], R2
                
                LOAD    R7, M[R6]
                INC     R6
                LOAD    R4, M[R6]
                INC     R6
                LOAD    R2, M[R6]
                INC     R6
                LOAD    R1, M[R6]
                INC     R6 
                
                JMP     R7


;===============================================================================
;UP_AUX:
;===============================================================================
;Funcao auxiliar da rotina de tratamento da interrupcao do botao up

UP_AUX:    
                DEC     R6
                STOR    M[R6], R1
                DEC     R6
                STOR    M[R6], R2
                
                ;Verificar se o dinossauro esta no chao
                MVI     R1, ALTURA_DINO
                LOAD    R1, M[R1]
                MVI     R2, FLOOR_LEVEL
                CMP     R1, R2
                BR.NZ   NO_JUMP
                
                MVI     R1, ALTURAMAX
                LOAD    R1, M[R1]
                MVI     R2, ACELERACAO_Y
                STOR    M[R2], R1
                
NO_JUMP:        
                LOAD    R2, M[R6]
                INC     R6
                LOAD    R1, M[R6]
                INC     R6
                JMP     R7
                
                
;Tratamento interrupcao switch
                
ORIG            7F00h

                MVI     R1, FFFFH
                MVI     R2, TERM_CURSOR
                STOR    M[R2], R1
                MVI     R1, 10h; Altera o valor do switch 0 para 0
                RTI
                
ORIG            7F30H

                DEC     R6
                STOR    M[R6], R7
                JAL     UP_AUX
                LOAD    R7, M[R6]
                INC     R6
                RTI
                

;Tratamento interrupcao timer
                
ORIG            7FF0H
                
                DEC     R6
                STOR    M[R6], R7
                JAL     TIMER_AUX
                LOAD    R7, M[R6]
                INC     R6
                
                RTI