.586
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "Snake GAME",0
area_width EQU 900
area_height EQU 800
area DD 0

snake_posX dd 430
snake_posY dd 300
snake_pos1X dd 415
snake_pos1Y dd 300
snake_pos2X dd 400
snake_pos2Y dd 300
snake_pos3X dd 385
snake_pos3Y dd 300

foodX dd 720
foodY dd 300
counter dd 0
score dd 0
bestscore dd 0
died dd 0
speed dd 5


letter_width equ 10
letter_height equ 20

obstacol_width equ 30
obstacol_height equ 20

matrix_width EQU 30
matrix_height EQU 30


square_size dd 15
key_pressed dd 0

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20
arg5 equ 24


include digits.inc
include letters.inc
include obstacol.inc
include caramizi.inc


.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
; arg5 - reprezintă un pointer la un vector de pixeli care este folosit pentru a desena patratul
; într-o anumită culoare sau configurație de pixeli.
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, letter_width
	mul ebx
	mov ebx, letter_height
	mul ebx
	add esi, eax
	mov ecx, letter_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, letter_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, letter_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

;un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm


line_horizontal macro x, y, len, culoare
 local bucla_linie
   mov eax, y
    mov ebx, area_width
    mul ebx
    add eax, x
    shl eax, 2
    add eax, area
    mov ecx, len
bucla_linie:
    mov ebx, culoare
    mov dword ptr [eax], ebx
    add eax, 4
    loop bucla_linie
endm

; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x
; arg3 - y

draw_symbol proc ;procedura pt desenarea caramizilor
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]
	lea esi, obstacol	
draw_text:
	mov ebx, obstacol_width
	mul ebx
	mov ebx, obstacol_height
	mul ebx
	add esi, eax
	mov ecx, obstacol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, obstacol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, obstacol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_fundal
	
	cmp byte ptr [esi], 1
	je simbol_pixel_caramizi
	
	mov dword ptr [edi], 0ff0000h
	jmp simbol_pixel_next
	
simbol_pixel_fundal:
	mov dword ptr [edi],0FFFFCCh 
		jmp simbol_pixel_next

simbol_pixel_caramizi:
mov dword ptr [edi], 0663300h	
	jmp simbol_pixel_next
	
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
draw_symbol endp

draw_symbol_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call draw_symbol
	add esp, 16
endm

make_caramizi proc
	push ebp
	mov ebp, esp
	pusha
	lea esi, caramida
	mov ecx, matrix_height
	mov ebx,0
	mov edi,0
for1:
push ecx
mov ecx, matrix_width
for2:
cmp byte ptr [esi], 0
je color_0
cmp byte ptr [esi], 1
je color_1

draw_symbol_macro 1, area, ebx, edi
jmp continuare_for

color_0:
draw_symbol_macro 0, area, ebx, edi
jmp continuare_for

color_1:
draw_symbol_macro 1, area, ebx, edi
jmp continuare_for

continuare_for:
add ebx, obstacol_width
inc esi
loop for2
pop ecx
mov ebx, 0
add edi, obstacol_height
loop for1
popa
mov esp,ebp
pop ebp
ret
make_caramizi endp

make_caramizi_macro macro
call make_caramizi
endm

square_draw proc
    push ebp ;salvam pe stiva valoarea registrului de baza al stivei
    mov ebp, esp 
    push esi
    ; Verifică condițiile pentru desenarea patratului(food,sneak head+body)
    cmp dword ptr [ebp+arg1], 0
    jl final
    cmp dword ptr [ebp+arg2], 0
    jl final
    mov eax, area_width
    sub eax, [ebp+arg3] 
    cmp dword ptr [ebp+arg1], eax
    jg final
    mov eax, area_height
    sub eax, [ebp+arg4]
    cmp dword ptr [ebp+arg2], eax
    jg final
    xor ecx, ecx ;ecx setat la 0
    mov esi, [ebp+arg1]
bucla_linii_orizontal:
    cmp ecx, [ebp+arg4]
    jge depasire_bucla_orizontal ;val este >= inaltimea
    push ecx
    line_horizontal esi, [ebp+arg2], [ebp+arg3], [ebp+arg5]
    pop ecx
    add esi, area_width
    inc ecx
    jmp bucla_linii_orizontal
depasire_bucla_orizontal:
    xor eax, eax
    jmp final
final:
    pop esi
    pop ebp
    ret
square_draw endp

draw proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]
	 cmp eax, 1
	 jz evt_click
	 cmp eax, 2
	 jz evt_timer ; nu s-a efectuat click pe nimic
	 cmp eax,3
	 jz pressed_key
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 255
	push area
	call memset
	add esp, 12
	
	jmp afisare_litere
	
pressed_key:
		mov ecx,[ebp+arg2]
		mov key_pressed,ecx
		mov died, 0;
		
evt_click:
	
evt_timer:
		cmp key_pressed,'&'
		jne down_pressed
		;s a dat click pe tasta sageata sus
		 mov eax, snake_pos2Y
		 mov snake_pos3Y,eax
		  mov eax, snake_pos2X
		 mov snake_pos3X,eax     ;=>a 3-a parte din corpul sarpelui se misca dupa a 2-a
		
	
		 mov eax, snake_pos1Y
		 mov snake_pos2Y,eax
		  mov eax, snake_pos1X
		 mov snake_pos2X,eax     ;=>a 2-a parte din corpul sarpelui se misca dupa prima
		
		 mov eax, snake_posY
		 mov snake_pos1Y,eax
		  mov eax, snake_posX
		 mov snake_pos1X,eax     ;=> prima parte din corpul sarpelui se misca dupa 'head'
		 
		 
		sub snake_posY,15   ;sarpele urca pe linia de deasupra
		jmp afisare_litere
down_pressed:
		cmp key_pressed,'('
		jne left_pressed
		
		;s a dat click pe tasta sageata jos
		mov eax, snake_pos2Y
		 mov snake_pos3Y,eax
		  mov eax, snake_pos2X
		 mov snake_pos3X,eax     ;=>a 3-a parte din corpul sarpelui se misca dupa a 2-a
		
		 mov eax, snake_pos1Y
		 mov snake_pos2Y,eax
		  mov eax, snake_pos1X
		 mov snake_pos2X,eax   ; => a2-a parte din corpul sarpelui se misca dupa prima
		 
		 mov eax, snake_posY
		 mov snake_pos1Y,eax
		  mov eax, snake_posX
		 mov snake_pos1X,eax    ; => prima parte din corpul sarpelui se misca dupa 'head'
		 
		
		 
		add snake_posY,15  ;sarpele coboara pe linia de mai jos
		jmp afisare_litere
left_pressed:
		cmp key_pressed,'%'
		jne right_pressed
		;s a dat click pe tasta sageata stanga
		mov eax, snake_pos2Y
		 mov snake_pos3Y,eax
		  mov eax, snake_pos2X
		 mov snake_pos3X,eax    ; a 3-a parte din corpul sarpelui se misca dupa a 2-a
		
		 mov eax, snake_pos1Y
		 mov snake_pos2Y,eax
		  mov eax, snake_pos1X
		 mov snake_pos2X,eax    ; a 2-a parte din corpul sarpelui se misca dupa prima
		 
		  mov eax, snake_posY
		 mov snake_pos1Y,eax
		  mov eax, snake_posX
		 mov snake_pos1X,eax    ; prima parte din corpul sarpelui se misca dupa 'head'
		 
		  
		 
		sub snake_posX,15	 ; sarpele se muta pe randul din stanga
		jmp afisare_litere
right_pressed:
		cmp key_pressed,"'"
		jne afisare_litere
		;s a dat click pe tasta sageata dreapta
		mov eax, snake_pos2Y
		 mov snake_pos3Y,eax
		  mov eax, snake_pos2X
		 mov snake_pos3X,eax    ; a3-a parte din corpul sarpelui se misca dupa a2-a
		 
		 mov eax, snake_pos1Y
		 mov snake_pos2Y,eax
		  mov eax, snake_pos1X
		 mov snake_pos2X,eax   ;a2-a parte din corpul sarpelui se misca dupa prima
		 
		 mov eax, snake_posY
		 mov snake_pos1Y,eax
		  mov eax, snake_posX
		 mov snake_pos1X,eax   ; prima parte din corpul sarpelui se misca dupa 'head'
		 
		
		add snake_posX,15    ; sarpele se muta pe randul din dreapta
		jmp afisare_litere

afisare_litere:
	;scriem un mesaj
	make_caramizi_macro ;folosim macro ul pentru a afisa matricea cu margini si obstacole

	;afisam scorul
	mov ebx, 10
	mov eax, score
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 130, 700
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 120, 700
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 110, 700
	;cifra miilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 100, 700
	
	;afisam bestscore
	mov ebx, 10
	mov eax, bestscore
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 720, 700
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 710, 700
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 700, 700
	;cifra miilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 690, 700
	
	make_text_macro 'Y', area, 70, 640
	make_text_macro 'O', area, 80, 640
	make_text_macro 'U', area, 90, 640
	make_text_macro 'R', area, 100, 640
	make_text_macro ' ', area, 110, 640
	make_text_macro 'S', area, 120, 640
	make_text_macro 'C', area, 130, 640
	make_text_macro 'O', area, 140, 640
	make_text_macro 'R', area, 150, 640
	make_text_macro 'E', area, 160, 640
	
	
	make_text_macro 'B', area, 670, 640
	make_text_macro 'E', area, 680, 640
	make_text_macro 'S', area, 690, 640
	make_text_macro 'T', area, 700, 640
	make_text_macro ' ', area, 710, 640
	make_text_macro 'S', area, 720, 640
	make_text_macro 'C', area, 730, 640
	make_text_macro 'O', area, 740, 640
	make_text_macro 'R', area, 750, 640
	make_text_macro 'E', area, 760, 640
	
	cmp died, 0
	je dead1
	jmp dead 
dead1:
make_text_macro ' ', area, 320, 750
make_text_macro ' ', area, 330, 750
make_text_macro ' ', area, 340, 750
make_text_macro ' ', area, 350, 750
make_text_macro ' ', area, 360, 750
make_text_macro ' ', area, 370, 750
make_text_macro ' ', area, 380, 750
make_text_macro ' ', area, 390, 750
make_text_macro ' ', area, 400, 750
make_text_macro ' ', area, 410, 750
make_text_macro ' ', area, 420, 750
make_text_macro ' ', area, 430, 750
make_text_macro ' ', area, 440, 750
make_text_macro ' ', area, 450, 750
make_text_macro ' ', area, 460, 750
make_text_macro ' ', area, 470, 750
make_text_macro ' ', area, 480, 750
make_text_macro ' ', area, 490, 750
make_text_macro ' ', area, 500, 750
make_text_macro ' ', area, 510, 750
make_text_macro ' ', area, 520, 750
make_text_macro ' ', area, 530, 750
make_text_macro ' ', area, 540, 750
make_text_macro ' ', area, 550, 750
make_text_macro ' ', area, 560, 750
make_text_macro ' ', area, 570, 750
		
		
	;sneak 'head'
	push 008000h
	push square_size					
	push square_size			
	push snake_posY
	push snake_posX
	call square_draw
	add esp,20
	;sneak body:
	;1:
	push 00FF00h
	push square_size					
	push square_size			
	push snake_pos1Y
	push snake_pos1X
	call square_draw
	add esp,20
	;2:
	push 00FF00h
	push square_size					
	push square_size			
	push snake_pos2Y
	push snake_pos2X
	call square_draw
	add esp,20
	;3:
	push 00FF00h
	push square_size					
	push square_size			
	push snake_pos3Y
	push snake_pos3X
	call square_draw
	add esp,20
	
food:
	push 0FF0000h
	push square_size					
	push square_size			
	push foodY
	push foodX
	call square_draw
	add esp,20
	
	;daca se izbeste de margini moare:
	
	cmp snake_posX, 867
	jge fail
	 cmp snake_posX, 33
	jle fail
	cmp snake_posY, 570
	jge fail
	cmp snake_posY, 24
	jle fail
	
	;de zid1 =>moare
zid1:
	 cmp snake_posX, 203
	 jge zid11
	 jmp zid2
 zid11:
	 cmp snake_posX,332
	 jle zid12  
	  jmp zid2
	 
zid12:
	 cmp snake_posY, 322
	 jle zid13
	  jmp zid2

zid13:
    cmp snake_posY,138
	jge fail
	  jmp zid2
	 
;de zid2 => moare
zid2:
	  cmp snake_posX, 567
	 jge zid21
	 jmp zid3
 zid21:
	 cmp snake_posX,694
	 jle zid22  
	   jmp zid3
	 
zid22:
	 cmp snake_posY, 204
	 jle zid23
	   jmp zid3

zid23:
    cmp snake_posY,117
	jge fail
	  jmp zid3
	 
;de zid3 => moare
zid3:
 cmp snake_posX, 565
	 jge zid31
	 jmp check_food
 zid31:
	 cmp snake_posX,634
	 jle zid32  
	   jmp check_food
	 
zid32:
	 cmp snake_posY, 430
	 jge fail

	 ;verificam daca atinge mancarea
check_food:  ;=>snake_posY=[foodY,foodY+15] 15=lungimea sarpelui/a mancarii
    mov eax, foodY
    cmp eax, snake_posY
    jnle check3
    add eax, 15
    cmp eax, snake_posY
    jge check1
    jmp check3

	;e in prumul int
check1: ;  =>snakex+15=[foodx,foodx+15]
    mov eax,snake_posX
    add eax, 15
    cmp foodX,eax
    jnle check2
    mov ecx,foodX
    add ecx, 15
    cmp ecx, eax 
    jge scorul
    jmp check2

check2:    ;=> snakex=[foodx,foodx+15]
    mov eax, foodX
    cmp  eax, snake_posX
    jnle check3
    add eax, 15
    cmp eax, snake_posX
    jge scorul
    jmp check3

check3:  ;=>daca e in al doilea int sy+u=[fy,fy+15]
    mov eax,snake_posY
    add eax, 15
    cmp foodY,eax
    jnle final_draw
    mov ecx, foodY
    add ecx,15
    cmp ecx,eax
    jge check31
    jmp final_draw

check31:   ;=>sx=[fx,fx+15]
    mov eax,snake_posX
    cmp foodX,eax
    jnle check32
    mov ecx,foodX
    add ecx, 15
    cmp ecx, eax
    jge scorul
    jmp check32

check32:    ;=>sx+15=[fx,fx+15]
    mov eax, snake_posX
    add eax, 15
    cmp foodX,eax
    jnle final_draw
    mov ecx, foodX
    add ecx, 15
    cmp ecx, eax
    jge scorul
    jmp final_draw

scorul:	;sarpele mananca mancarea
     add score, 50
     mov ebx, 100
     rdtsc
     xor edx, edx
     div ebx ;in edx restul impartirii
     shl edx, 2
	 add edx,35 ;sa nu fie in peretele-margine
     mov foodX, edx
     rdtsc
     xor edx, edx
     div ebx 
     shl edx, 2
	 add edx,22 ;sa nu fie in peretele-margine de sus
     mov foodY, edx
	 jmp final_draw
	
dead:


fail:
;sarpele a murit
;resetam sarpele si mancarea la pozitia initiala
    mov snake_posX,430
    mov snake_posY,300
	mov snake_pos1X, 415
    mov snake_pos1Y, 300
    mov snake_pos2X, 400
    mov snake_pos2Y, 300
    mov snake_pos3X, 385
    mov snake_pos3Y, 300
	mov foodX,720
	mov foodY,300
	mov died, 1
	make_text_macro " ",area,385,280
	make_text_macro " ",area,395,280
	make_text_macro " ",area,405,280
	make_text_macro "G",area,415,280
	make_text_macro "A",area,425,280
	make_text_macro "M",area,435,280
	make_text_macro "E",area,445,280
	make_text_macro " ",area,455,280
	make_text_macro " ",area,465,280
	make_text_macro " ",area,475,280
	make_text_macro " ",area,395,300
	make_text_macro " ",area,405,300
	make_text_macro "O",area,415,300
	make_text_macro "V",area,425,300
	make_text_macro "E",area,435,300
	make_text_macro "R",area,445,300
	make_text_macro " ",area,455,300
	make_text_macro " ",area,465,300
make_text_macro 'P', area, 320, 750
make_text_macro 'R', area, 330, 750
make_text_macro 'E', area, 340, 750
make_text_macro 'S', area, 350, 750
make_text_macro 'S', area, 360, 750
make_text_macro ' ', area, 370, 750
make_text_macro 'A', area, 380, 750
make_text_macro 'N', area, 390, 750
make_text_macro 'Y', area, 400, 750
make_text_macro ' ', area, 410, 750
make_text_macro 'K', area, 420, 750
make_text_macro 'E', area, 430, 750
make_text_macro 'Y', area, 440, 750
make_text_macro ' ', area, 450, 750
make_text_macro 'T', area, 460, 750
make_text_macro 'O', area, 470, 750
make_text_macro ' ', area, 480, 750
make_text_macro 'T', area, 490, 750
make_text_macro 'R', area, 500, 750
make_text_macro 'Y', area, 510, 750
make_text_macro ' ', area, 520, 750
make_text_macro 'A', area, 530, 750
make_text_macro 'G', area, 540, 750
make_text_macro 'A', area, 550, 750
make_text_macro 'I', area, 560, 750
make_text_macro 'N', area, 570, 750
	mov eax, score              
	cmp eax, bestscore          
	jg best
	mov score,0
	jmp final_draw
best:
    mov bestscore,eax
	mov score,0
	
final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start
 