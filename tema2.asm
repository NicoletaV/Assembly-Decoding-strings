extern puts
extern printf
extern strlen

section .data
filename: db "./input.dat",0
inputlen: dd 2263
fmtstr: db "Key: %d",0xa,0

section .text
global main

; TODO: define functions and helper functions

; functia print realizeaza un printf "safe", salvand anterior valorile ce se 
; aflau in registrele folosite in program; va fi apelata in loc de printf
print:
	push ebp
	mov ebp, esp

	push eax
	push ebx
	push ecx
	push edx

	mov eax, [ebp + 8]
	push eax
	push fmtstr
	call printf
	add esp, 8

	pop edx
	pop ecx
	pop ebx
	pop eax

	leave
	ret

; functia pentru Task1, ce primeste ca prim argument adresa sirului si se gaseste
; la [ebp + 8], al doilea fiind adresa cheii, aflata la [ebp + 12]
xor_strings:

	push ebp
	mov ebp, esp
	
	xor eax, eax
	xor ebx, ebx
	xor edx, edx
	xor ecx, ecx
	
	; in eax va fi adresa sirului
	mov eax, [ebp + 8]
	; in ebx va fi adresa cheii
	mov ebx, [ebp + 12] 

	; in bucla se face xor byte cu byte intre mesaj si cheie, rezultatul fiind
	; pus apoi la adresa mesajului, decodificandu-se astfel in-place
	xor_until_the_end:
		
		mov cl, byte [eax]
		cmp cl, 0
		je end_of_strings
		
		mov dl, byte [ebx]
		cmp dl, 0
		je end_of_strings
		
		xor cl, dl
		; rezultatul xor-ului, aflat in cl, se pune la adresa din sir
		mov byte [eax], cl

		; se trece la pozitiile urmatoare in ambele siruri
		inc ebx
		inc eax 
		
		jmp xor_until_the_end

	end_of_strings:
		
		leave
		ret
		
		
; functie ce primeste un sir si il decripteaza, iterand prin el si realizand
; xor intre actualul byte si cel anterior
rolling_xor:

	push ebp
	mov ebp, esp

	; in eax va fi adresa sirului de la Task2
	mov eax, [ebp + 8]

	xor edx, edx
	xor ecx, ecx

	; primul byte ramane neschimbat
	mov dl, byte [eax]
	mov bl, dl
	inc eax

	continue_until_0:
		
		mov cl, byte [eax]
		cmp cl, 0
		je found_0

		; dl e intermediar, pentru a retine rezultatul de pana atunci
		mov bl, dl
		mov dl, cl
		xor cl, bl

		; se pune la adresa rezultatul xor-ului, care e in cl
		mov byte [eax], cl
		
		inc eax 
		jmp continue_until_0

	found_0:

		leave
		ret
		

; functia pentru Task3, ce transforma cate 2 octeti in corespondentul lor in
; hexazecimal tinand cont daca e cifra sau litera (0->9, a->f), apoi realizeaza
; xor intre reprezentarile obtinute si rezultatul se pune la adresa sirului ce
; trebuie suprascris
xor_hex_strings:
	
	push ebp
	mov ebp, esp
	
	xor eax, eax
	xor ebx, ebx
	xor edx, edx
	xor ecx, ecx
	
	; in eax va fi adresa primului sir, ce va fi suprascris
	mov eax, [ebp + 8]	
	; in ebx se va afla adresa cheii (al doilea sir)
	mov ebx, [ebp + 12] ; al doilea
	; esi va puncta tot la inceputul sirului ce trebuie decriptat, fiind folosit
	; pentru a modifica sirul initial
	mov esi, eax

	continue_until_end:
		
		; pentru primul byte din primul sir
		mov cl, byte [eax]
		inc eax

		cmp cl, 0
		je final

		mov ch, byte [eax]

		cmp ch, 0
		je final

		; daca caracterul are ascii-ul mai mare ca 80, va fi litera si deci sare
		; la eticheta corespunzatoare si se scade 87, rezultatul fiind >=10, ce
		; reprezinta litera in reprezentare hexazecimala (a->10, b->11,..)
		cmp cl, 80
		jg letter

		; daca nu are ascii-ul mai mare ca 80, inseamna ca este cifra si se 
		; scade 48 (ascii-ul pt 0), ajungandu-se astfel la cifra in hexazecimal
		sub cl, 48

		jmp conversion_done

	letter:
		sub cl, 87
		
	; pentru al doilea byte din primul sir
	conversion_done:
		
		shl cl, 4

		cmp ch, 80
		jg letter_2

		sub ch, 48

		jmp conversion_done_2

	letter_2:
		
		sub ch, 87

	; pentru primul byte din al doilea sir
	conversion_done_2:
		
		add cl, ch

		mov dl, byte [ebx]
		inc ebx

		cmp dl, 0
		je final

		mov dh, byte [ebx]

		cmp dh, 0
		je final

		cmp dl, 80
		jg letter_3

		sub dl, 48

		jmp conversion_done_3

	letter_3:
		
		sub dl, 87

	; pentru al doilea byte din al doilea sir
	conversion_done_3:
		
		shl dl, 4

		cmp dh, 80
		jg letter_4

		sub dh, 48

		jmp conversion_done_4

	letter_4:
		
		sub dh, 87

	conversion_done_4:
		
		add dl, dh
		
		; se face xor si rezultatul se pune la adresa lui esi
		xor cl, dl
		mov byte [esi], cl

		; se trece la pozitia urmatoare din siruri
		inc ebx
		inc eax
		inc esi
		
		jmp continue_until_end

	final:
		
		mov byte [esi], 0
		leave
		ret


; functia de la Task4 ce realizeaza decodarea sirului primit, luand cate 40 biti
; la o iteratie a buclei "continue", formand octeti din grupari de cate 5 biti
; din reprezentarea din tabelul din enunt
base32decode:
	
	push ebp
	mov ebp, esp

	mov eax, [ebp + 8] 

	xor edx, edx
	xor ecx, ecx
	xor ebx, ebx
	xor esi, esi
	mov esi, eax
	xor edi, edi 

	continue:

		xor ebx, ebx
		xor ecx, ecx

		; in ebx vor fi primii 4 octeti din cei 5 necesari de fiecare data
		mov ebx, dword[eax]
		cmp ebx, 0
		je finally
		add eax, 4
		
		; in ecx vor fi urmatorii 4 octeti, din care se va folosi doar primul
		; la o iteratie, ca sa fie in total cate 5, adica 40 biti
		mov ecx, dword[eax]
		cmp ecx, 0
		je finally
		add eax, 4

		xor edx, edx
		mov dl, bl

		; daca valoarea e mai mare ca 65, inseamna ca e litera si trebuie sa se
		; scada 65, pentru a ajunge la valorile din tabelul din enunt pentru litere
		cmp dl, 65
		jge is_letter

		; daca e 61, inseamna ca e =, adica padding si functia se incheie
		cmp dl, 61 
		je finally

		; daca nu e litera, se scade 24 pentru a ajunge la cifra corespunzatoare,
		; conform tabelului
		sub dl, 24
		jmp output

		is_letter:
			
			sub dl, 65
	
		; in fiecare parte de "output" se separa bitii astfel incat sa se 
		; formeze grupuri de cate 8 biti, acest octet format fiind adaugat 
		; la adresa lui esi, prin intermediul indexului edi
		output:
			
			shl dl, 3

			mov byte[esi + edi], dl   

			ror ebx, 8
			mov dl, bl
						
			cmp dl, 65
			jge is_letter_2

			cmp dl, 61
			je finally

			sub dl, 24
			jmp output_2			

			is_letter_2:
				
				sub dl, 65

			output_2:
				
				mov dh, dl 
				shr dl, 2
				add byte[esi + edi], dl

				shl dh, 6
				inc edi
				mov byte[esi + edi], dh

				ror ebx, 8 
				mov dl, bl

				cmp dl, 65
				jge is_letter_3

				cmp dl, 61
				je finally

				sub dl, 24
				jmp output_3

				is_letter_3:
					
					sub dl, 65

				output_3:
					
					shl dl, 1
					add byte[esi + edi], dl

					ror ebx, 8
					mov dl, bl 
						
					cmp dl, 65
					jge is_letter_4

					sub dl, 24
					jmp output_4

					is_letter_4:
						
						sub dl, 65

					output_4:
						
						mov dh, dl
						shr dl, 4
						add byte[esi + edi], dl

						inc edi
						shl dh, 4
						mov byte[esi + edi], dh

						mov dl, cl 
						
						cmp dl, 65
						jge is_letter_5

						cmp dl, 61
						je finally

						sub dl, 24
						jmp output_5

						is_letter_5:
							
							sub dl, 65

						output_5:
							
							mov dh, dl
							shr dl, 1
							add byte[esi + edi], dl

							inc edi
							shl dh, 7
							mov byte[esi + edi], dh

							ror ecx, 8 
							mov dl, cl 
						
							cmp dl, 65
							jge is_letter_6

							cmp dl, 61
							je finally

							sub dl, 24
							jmp output_6

							is_letter_6:
								
								sub dl, 65

							output_6:
								
								shl dl, 2
								add byte[esi + edi], dl

								ror ecx, 8
								mov dl, cl 
						
								cmp dl, 65
								jge is_letter_7

								cmp dl, 61
								je finally

								sub dl, 24
								jmp output_7

								is_letter_7:
									
									sub dl, 65

								output_7:
									
									mov dh, dl
									shr dl, 3
									add byte[esi + edi], dl

									inc edi
									shl dh, 5
									mov byte[esi + edi], dh

									ror ecx, 8
									mov dl, cl 
						
									cmp dl, 65
									jge is_letter_8

									cmp dl, 61
									je finally

									sub dl, 24
									jmp output_8

									is_letter_8:
										
										sub dl, 65

									output_8:
										
										add byte[esi + edi], dl
										inc edi
										
										cmp byte[eax], 0
										je finally	

										; cand se termina adaugarea in esi a 40
										; de biti, se reia procesul, pana cand
										; se ajunge la finalul sirului
										jmp continue

	finally:
	
		; se adauga 0 la sfarsit, pentru a nu mai afisa si partea ramasa
		; din sirul initial nesuprascrisa, intrucat noul sir are o lungime
		; mai mica decat originalul
		mov byte[esi + edi], 0 
		leave
		ret

; functia gaseste cheia necesara pentru Task5, iterand prin sirul primit
; cand se gasesc consecutiv literele f, o, r, c, e, se termina functia si
; in eax se gaseste cheia aflata
find_key:
	
	push ebp
	mov ebp, esp

	mov ebx, [ebp + 8] 
	
	xor edx, edx
	xor ecx, ecx 
	; se incepe cu cheia ca fiind 0
	xor eax, eax 

	keep_searching:
		
		mov ch, byte[ebx]
		cmp ch, 0
		je inc_key
		xor ch, al
		mov dl, ch
		; daca litera e "f", dl devine 0
		sub dl, 102
		ror edx, 1

		mov ch, byte[ebx + 1]
		cmp ch, 0
		je inc_key
		xor ch, al
		mov dl, ch
		; daca litera e "o", dl devine 0
		sub dl, 111
		ror edx, 1

		mov ch, byte[ebx + 2]
		cmp ch, 0
		je inc_key
		xor ch, al
		mov dl, ch
		; daca litera e "r", dl devine 0
		sub dl, 114
		ror edx, 1

		mov ch, byte[ebx + 3]
		cmp ch, 0
		je inc_key
		xor ch, al
		mov dl, ch
		; daca litera e "c", dl devine 0
		sub dl, 99
		ror edx, 1

		mov ch, byte[ebx + 4]
		cmp ch, 0
		je inc_key
		xor ch, al
		mov cl, ch
		; daca litera e "e", cl devine 0
		sub cl, 101
		mov ch, 0

		; daca s-a gasit "force", edx si ecx ar trebui sa fie ambele 0
		cmp edx, 0
		je check_key

		xor edx, edx
		xor ecx, ecx

		; daca nu s-a gasit cheia, se incrementeaza valoarea indexului in sir si se reia
		inc ebx
		jmp keep_searching

	check_key:
		
		; daca edx si ecx sunt 0, s-a gasit cheia si se iese din functie
		cmp ecx, 0
		je found

		xor edx, edx
		xor ecx, ecx

		inc ebx
		jmp keep_searching

	inc_key:
		
		; se incrementeaza cheia din eax
		inc eax
		; se ia de la inceput iterarea prin sir
		mov ebx, [ebp + 8]
		xor ecx, ecx
		xor edx, edx
		jmp keep_searching

	found:
		
		leave
		ret


; functia de la Task5 itereaza prin sir si face xor intre fiecare byte si
; cheia determinata anterior, punand noul rezultat in locul celui vechi
bruteforce_singlebyte_xor:
	
	push ebp
	mov ebp, esp

	; in ebx va fi adresa sirului
	mov ebx, [ebp + 8] 
	; in edx se va afla cheia, calculata anterior in eax 
	mov edx, [ebp + 12] 
	
	xor eax, eax
	xor ecx, ecx

	do_xor:
		
		mov cl, byte[ebx]
		; se face xor intre byte din sir si cheie
		xor cl, dl 
		; rezultatul se pune la adresa sirului
		mov byte[ebx], cl
		
		inc ebx
		cmp byte[ebx], 0
		je end_string
		jmp do_xor
		
	end_string:
		
		leave
		ret
		

; functia calculeaza frecventele fiecarui caracter si, in functie de acestea
; aplica tabela si substituie cu caracterul corespunzator din ea
break_substitution:

	push ebp
	mov ebp, esp

	mov ecx, [ebp + 8] 
	
	xor eax, eax
	xor edx, edx
	xor esi, esi
	xor ebx, ebx

	xor eax, eax
	mov ah, 32 
	xor esi, esi
	xor edi, edi
	
	space:

		mov al, byte[ecx + esi]
		cmp al, 0
		je before_dot
		cmp al, ah
		je incr_edx
		inc esi
		jmp space

	incr_edx:
		
		inc edi
		inc esi
		jmp space

	before_dot:
	
		mov edx, edi

		; pentru a afisa frecventa spatiilor
		;push edx
		;call print 
		;pop edx

		inc edx

		xor edi, edi
		; edx e initial 0, cand numar aparitiile punctului
		mov edx, edi 
		; incepe o noua iterare prin ecx
		xor esi, esi 
		mov ah, 46 

		dot:
			
			mov al, byte[ecx + esi]
			cmp al, 0
			je before_letters
			cmp al, ah
			je incr_edx_2
			inc esi
			jmp dot

		incr_edx_2:
			
			inc edi
			inc esi
			jmp dot

		before_letters:
			
			mov edx, edi

			; pentru afisarea frecventei punctelor
			;push edx
			;call print 
			;pop edx

			inc edx
			mov ah, 97

			continue_letters:
				
				xor edi, edi
				mov edx, edi 
				xor esi, esi 
				
				letters:
					
					mov al, byte[ecx + esi]
					cmp al, 0
					je next_letter
					cmp al, ah
					je incr_edx_3
					inc esi
					jmp letters

				incr_edx_3:
					
					inc edi
					inc esi
					jmp letters

				next_letter:
					
					mov edx, edi

					; pentru afisarea frecventei fiecarei litere, in ordine
					; alfabetica
					; push edx
					; call print 
					; pop edx

					inc edx
					inc ah
					cmp ah, 122
					jg frequency_done
					; continua pentru urmatoarea litera, pana ajunge la z
					jmp continue_letters


	frequency_done:
	
		xor esi, esi

		; c se inlocuieste cu space + 100, la sfarsit scazandu-se 100 si revenind
		; astfel la space; acest lucru se repeta pentru fiecare caracter, in 
		; ordinea frecventelor
		c_309:	; c cu space
			
			cmp byte[ecx + esi], 0
			je space_207
			cmp byte[ecx + esi], 99
			jne skip_0
			mov byte[ecx + esi], 32 
			add byte[ecx + esi], 100
			skip_0:
				inc esi
				jmp c_309

		space_207:	; space cu e
			
			xor esi, esi
			space_207_do:
				
				cmp byte[ecx + esi], 0
				je k_141
				cmp byte[ecx + esi], 32
				jne skip_1
				mov byte[ecx + esi], 101 
				add byte[ecx + esi], 100
				skip_1:
					inc esi
					jmp space_207_do

		k_141:	; k cu t
			
			xor esi, esi
			k_141_do:
				
				cmp byte[ecx + esi], 0
				je q_129
				cmp byte[ecx + esi], 107
				jne skip_2
				mov byte[ecx + esi], 116 
				add byte[ecx + esi], 100
				skip_2:
					inc esi
					jmp k_141_do

		q_129:	; q cu a
			
			xor esi, esi
			q_129_do:
				
				cmp byte[ecx + esi], 0
				je g_115
				cmp byte[ecx + esi], 113
				jne skip_3
				mov byte[ecx + esi], 97 
				add byte[ecx + esi], 100
				skip_3:
					inc esi
					jmp q_129_do

		g_115:	; g cu o
			
			xor esi, esi
			g_115_do:
				
				cmp byte[ecx + esi], 0
				je l_110
				cmp byte[ecx + esi], 103
				jne skip_4
				mov byte[ecx + esi], 111 
				add byte[ecx + esi], 100
				skip_4:
					inc esi
					jmp g_115_do

		l_110:	; l cu s
			
			xor esi, esi
			l_110_do:
				
				cmp byte[ecx + esi], 0
				je i_106
				cmp byte[ecx + esi], 108
				jne skip_5
				mov byte[ecx + esi], 115 
				add byte[ecx + esi], 100
				skip_5:
					inc esi
					jmp l_110_do

		i_106:	; i cu i
			
			xor esi, esi
			i_106_do:
				
				cmp byte[ecx + esi], 0
				je dot_93
				cmp byte[ecx + esi], 105
				jne skip_6
				mov byte[ecx + esi], 105 
				add byte[ecx + esi], 100
				skip_6:
					inc esi
					jmp i_106_do

		dot_93:	; dot cu n
			
			xor esi, esi
			dot_93_do:
				
				cmp byte[ecx + esi], 0
				je s_88
				cmp byte[ecx + esi], 46
				jne skip_7
				mov byte[ecx + esi], 110 
				add byte[ecx + esi], 100
				skip_7:
					inc esi
					jmp dot_93_do

		s_88:	; s cu r
			
			xor esi, esi
			s_88_do:
				
				cmp byte[ecx + esi], 0
				je e_69
				cmp byte[ecx + esi], 115
				jne skip_8
				mov byte[ecx + esi], 114 
				add byte[ecx + esi], 100
				skip_8:
					inc esi
					jmp s_88_do

		e_69:	; e cu d
			
			xor esi, esi
			e_69_do:
				
				cmp byte[ecx + esi], 0
				je y_58
				cmp byte[ecx + esi], 101
				jne skip_9
				mov byte[ecx + esi], 100 
				add byte[ecx + esi], 100
				skip_9:
					inc esi
					jmp e_69_do

		y_58:	; y cu h
			
			xor esi, esi
			y_58_do:
				
				cmp byte[ecx + esi], 0
				je h_54
				cmp byte[ecx + esi], 121
				jne skip_10
				mov byte[ecx + esi], 104 
				add byte[ecx + esi], 100
				skip_10:
					inc esi
					jmp y_58_do

		h_54:	; h cu m
			
			xor esi, esi
			h_54_do:
				
				cmp byte[ecx + esi], 0
				je f_47
				cmp byte[ecx + esi], 104
				jne skip_11
				mov byte[ecx + esi], 109 
				add byte[ecx + esi], 100
				skip_11:
					inc esi
					jmp h_54_do

		f_47:	; f cu l
			
			xor esi, esi
			f_47_do:
				
				cmp byte[ecx + esi], 0
				je w_44
				cmp byte[ecx + esi], 102
				jne skip_12
				mov byte[ecx + esi], 108 
				add byte[ecx + esi], 100
				skip_12:
					inc esi
					jmp f_47_do

		w_44:	; w cu c
			
			xor esi, esi
			w_44_do:
				
				cmp byte[ecx + esi], 0
				je n_37
				cmp byte[ecx + esi], 119
				jne skip_13
				mov byte[ecx + esi], 99 
				add byte[ecx + esi], 100
				skip_13:
					inc esi
					jmp w_44_do

		n_37:	; n cu w
			
			xor esi, esi
			n_37_do:
				
				cmp byte[ecx + esi], 0
				je m_36
				cmp byte[ecx + esi], 110
				jne skip_14
				mov byte[ecx + esi], 119 
				add byte[ecx + esi], 100
				skip_14:
					inc esi
					jmp n_37_do

		m_36:	; m cu u
			
			xor esi, esi
			m_36_do:
				
				cmp byte[ecx + esi], 0
				je x_33
				cmp byte[ecx + esi], 109
				jne skip_15
				mov byte[ecx + esi], 117 
				add byte[ecx + esi], 100
				skip_15:
					inc esi
					jmp m_36_do
		
		x_33:	; x cu dot
			
			xor esi, esi
			x_33_do:
				
				cmp byte[ecx + esi], 0
				je u_28
				cmp byte[ecx + esi], 120
				jne skip_16
				mov byte[ecx + esi], 46 
				add byte[ecx + esi], 100
				skip_16:
					inc esi
					jmp x_33_do

		u_28:	; u cu f
			
			xor esi, esi
			u_28_do:
				
				cmp byte[ecx + esi], 0
				je d_27
				cmp byte[ecx + esi], 117
				jne skip_17
				mov byte[ecx + esi], 102 
				add byte[ecx + esi], 100
				skip_17:
					inc esi
					jmp u_28_do

		d_27:	; d cu p
			
			xor esi, esi
			d_27_do:
				
				cmp byte[ecx + esi], 0
				je z_26
				cmp byte[ecx + esi], 100
				jne skip_18
				mov byte[ecx + esi], 112 
				add byte[ecx + esi], 100
				skip_18:
					inc esi
					jmp d_27_do

		z_26:	; z cu y
			
			xor esi, esi
			z_26_do:
				
				cmp byte[ecx + esi], 0
				je t_22
				cmp byte[ecx + esi], 122
				jne skip_19
				mov byte[ecx + esi], 121 
				add byte[ecx + esi], 100
				skip_19:
					inc esi
					jmp z_26_do

		t_22:	; t cu g
			
			xor esi, esi
			t_22_do:
				
				cmp byte[ecx + esi], 0
				je j_19
				cmp byte[ecx + esi], 116
				jne skip_20
				mov byte[ecx + esi], 103 
				add byte[ecx + esi], 100
				skip_20:
					inc esi
					jmp t_22_do

		j_19:	; j cu v
			
			xor esi, esi
			j_19_do:
				
				cmp byte[ecx + esi], 0
				je r_18
				cmp byte[ecx + esi], 106
				jne skip_21
				mov byte[ecx + esi], 118 
				add byte[ecx + esi], 100
				skip_21:
					inc esi
					jmp j_19_do

		r_18:	; r cu b
			
			xor esi, esi
			r_18_do:
				
				cmp byte[ecx + esi], 0
				je p_18
				cmp byte[ecx + esi], 114
				jne skip_22
				mov byte[ecx + esi], 98 
				add byte[ecx + esi], 100
				skip_22:
					inc esi
					jmp r_18_do

		p_18:	 ; p cu k
			
			xor esi, esi
			p_18_do:
				
				cmp byte[ecx + esi], 0
				je o_6
				cmp byte[ecx + esi], 112
				jne skip_23
				mov byte[ecx + esi], 107
				add byte[ecx + esi], 100
				skip_23:
					inc esi
					jmp p_18_do
	
		o_6:	; o cu j
			
			xor esi, esi
			o_6_do:
				
				cmp byte[ecx + esi], 0
				je b_5
				cmp byte[ecx + esi], 111
				jne skip_24
				mov byte[ecx + esi], 106 
				add byte[ecx + esi], 100
				skip_24:
					inc esi
					jmp o_6_do

		b_5:	; b cu x
			
			xor esi, esi
			b_5_do:
			
			cmp byte[ecx + esi], 0
				je v_1
				cmp byte[ecx + esi], 98
				jne skip_25
				mov byte[ecx + esi], 120 
				add byte[ecx + esi], 100
				skip_25:
					inc esi
					jmp b_5_do

		v_1:	; v cu z
			
			xor esi, esi
			v_1_do:
				
				cmp byte[ecx + esi], 0
				je a_0
				cmp byte[ecx + esi], 118
				jne skip_26
				mov byte[ecx + esi], 122 
				add byte[ecx + esi], 100
				skip_26:
					inc esi
					jmp v_1_do

		a_0:	; a cu q
			
			xor esi, esi
			a_0_do:
				
				cmp byte[ecx + esi], 0
				je make_normal
				jne skip_27
				mov byte[ecx + esi], 113 
				add byte[ecx + esi], 100
				skip_27:
					inc esi
					jmp a_0_do

		make_normal:
			
			xor esi, esi
			norm_do:
				cmp byte[ecx + esi], 0
				je done_out

				sub byte[ecx + esi], 100
				inc esi
				jmp norm_do
		
	done_out:
		
		leave
		ret

main:
	push ebp
    mov ebp, esp
    sub esp, 2300
    
    ;fd = open("./input.dat", O_RDONLY);
    mov eax,5
    mov ebx, filename
    xor ecx, ecx
    xor edx, edx
    int 0x80
    
	;read(fd, ebp-2300, inputlen);
	mov ebx, eax
	mov eax, 3
	lea ecx, [ebp-2300]
	mov edx, [inputlen]
	int 0x80

	;close(fd);
	mov eax, 6
	int 0x80

	; all input.dat contents are now in ecx (address on stack)

	; TASK 1: Simple XOR between two byte streams
	; TODO: compute addresses on stack for str1 and str2
	; TODO: XOR them byte by byte
	;push addr_str2
	;push addr_str1
	;call xor_strings
	;add esp, 8
	; Print the first resulting string
	;push addr_str1
	;call puts
	;add esp, 4
	
	; lungimea primului sir va fi retinuta in eax, din apelul de strlen
	push ecx
	call strlen
	pop ecx

	; ebx va puncta la inceputul sirului ce reprezinta cheia
	mov ebx, ecx
	add ebx, eax
	inc ebx

	; se salveaza registrele
	push eax
	push edx
	
	; cheia
	push ebx
	; sirul
	push ecx
	call xor_strings
	pop ecx
	pop ebx
	
	pop edx
	pop eax

	; afisarea sirului decriptat 
	push ecx
	call puts
	add esp, 4

	; TASK 2: Rolling XOR
	; TODO: compute address on stack for str3
	; TODO: implement and apply rolling_xor function
	;push addr_str3
	;call rolling_xor
	;add esp, 4
	; Print the second resulting string
	;push addr_str3
	;call puts
	;add esp, 4

	push ebx
	call strlen
	pop ebx

	; ebx se muta astfel incat sa puncteze la inceputul stringului,
	; adica sare peste cheia de la Task1, la inceputul careia era
	add ebx, eax
	inc ebx

	; se salveaza registrele
	push eax
	push ecx
	push edx

	; se apeleaza functia cu argumentul ebx (adresa sirului)
	push ebx
	call rolling_xor
	pop ebx

	pop edx
	pop ecx
	pop eax

	; se afiseaza sirul decriptat, aflat tot la ebx, dupa ce a fost modificat
	; in interiorul functiei
	push ebx
	call puts
	pop ebx
	
	; TASK 3: XORing strings represented as hex strings
	; TODO: compute addresses on stack for strings 4 and 5
	; TODO: implement and apply xor_hex_strings
	;push addr_str5
	;push addr_str4
	;call xor_hex_strings
	;add esp, 8
	; Print the third string
	;push addr_str4
	;call puts
	;add esp, 4

	push ebx
	call strlen
	pop ebx

	; in ebx se va afla primul sir
	add ebx, eax
	inc ebx 

	mov ecx, ebx
	push ecx
	call strlen
	pop ecx

	; in ecx se va afla al doilea sir
	add ecx, eax
	inc ecx 

	push eax
	
	; se apeleaza functia cu cele 2 argumente
	push ecx
	push ebx
	call xor_hex_strings
	pop ebx
	pop ecx
	
	pop eax

	; ecx va puncta la inceputul stringului pentru Task4
	add ecx, eax
	inc ecx

	; se salveaza unde puncteaza ecx-ul
	push ecx
	
	; se afiseaza sirul decriptat, ce se afla la ebx
	push ebx
	call puts
	pop ebx
	
	pop ecx

	; TASK 4: decoding a base32-encoded string
	; TODO: compute address on stack for string 6
	; TODO: implement and apply base32decode
	;push addr_str6
	;call base32decode
	;add esp, 4
	; Print the fourth string
	;push addr_str6
	;call puts
	;add esp, 4

	; se salveaza valorile registrelor
	push eax
	push ebx
	push edx

	; in ecx va fi adresa sirului de la Task4 si se apeleaza functia
	push ecx
	call base32decode
	pop ecx

	pop edx
	pop ebx
	pop eax

	push eax
	push ebx
	push edx

	; se printeaza sirul decodat 
	push ecx
	call puts
	pop ecx

	pop edx
	pop ebx
	pop eax
	
	; TASK 5: Find the single-byte key used in a XOR encoding
	; TODO: determine address on stack for string 7
	; TODO: implement and apply bruteforce_singlebyte_xor
	;push key_addr
	;push addr_str7
	;call bruteforce_singlebyte_xor
	;add esp, 8
	; Print the fifth string and the found key value
	;push addr_str7
	;call puts
	;add esp, 4
	;push keyvalue
	;push fmtstr
	;call printf
	;add esp, 8

	until_0:
		
		mov bl, byte[ecx]
		cmp bl, 0
		je do_task5

		inc ecx
		jmp until_0

	do_task5:
		
		inc ecx
		push ecx
		call strlen
		pop ecx

		; ecx va puncta la sirul pentru Task5
		add ecx, eax
		inc ecx

		push eax
		push ebx
		push edx

		; se apeleaza functia pentru gasirea cheii, avand ca argument sirul
		push ecx
		call find_key 
		pop ecx

		pop edx
		pop ebx
		; nu se realizeaza si pop eax, intrucat cheia aflata se afla in eax
		; pe stiva
		
		push ebx
		push edx

		; se epeleaza functia cu sirul (ecx) si cheia (eax)
		push eax
		push ecx
		call bruteforce_singlebyte_xor
		pop ecx
		pop eax
		
		pop edx
		pop ebx
		

		push eax
		push ebx
		push edx
		
		; se afiseaza sirul decriptat, a carui adresa e in ecx
		push ecx
		call puts
		pop ecx
		
		pop edx
		pop ebx
		pop eax

		; se afiseaza cheia cu ajutorul lui print (ce e de fapt printf)
		push eax
		call print
		pop eax	

	; TASK 6: Break substitution cipher
	; TODO: determine address on stack for string 8
	; TODO: implement break_substitution
	;push substitution_table_addr
	;push addr_str8
	;call break_substitution
	;add esp, 8
	; Print final solution (after some trial and error)
	;push addr_str8
	;call puts
	;add esp, 4
	; Print substitution table
	;push substitution_table_addr
	;call puts
	;add esp, 4

	push ecx
	call strlen
	pop ecx

	; in ecx se afla adresa sirului pt Task6
	add ecx, eax
	inc ecx  

	push eax
	push edx
	push ebx

	; se apeleaza functia pe sir
	push ecx
	call break_substitution
	pop ecx
	
	pop ebx
	pop edx
	pop eax

	push eax
	push ebx
	push edx

	; se afiseaza sirul modificat
	push ecx
	call puts
	pop ecx

	pop edx
	pop ebx
	pop eax

	; se face push la tabela de substitutie pe stiva
	push 0
	push dword " c.x"
	push dword "yzzv"
	push dword "wnxb"
	push dword "umvj"
	push dword "sltk"
	push dword "qars"
	push dword "ogpd"
	push dword "mhn."
	push dword "kplf"
	push dword "iijo"
	push dword "gthy"
	push dword "e fu"
	push dword "cwde"
	push dword "aqbr"
	
	; se afiseaza din varf pana gaseste 0, adica toata tabela si se reface stiva
	push esp
	call puts
	add esp, 60
		
	; Phew, finally done
    xor eax, eax
    leave
    ret


