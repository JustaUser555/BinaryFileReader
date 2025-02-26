;;;;;;;;;;;;;;;;;DISCLAIMER;;;;;;;;;;;;;;;;
;The entirety of the subsequent code adheres to
;the System V Application Binary Interface (ABI)
;compliance standards.

extern printf

section .data
    clear: db 128, 64, 32, 16, 8, 4, 2, 1
    msg: db 'I: %d', 10, 0

section .text

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; NAME: binToDec
; ARGUMENTS:
;	rdi: 'binary' string -> Max length: 2^64 / 8 - 1
;	rsi: 'size' size_t size of string
;	rdx: 'decimal' -> 8 times the length of 'binary'
; RETURN VALUE:
; 	rax: pointer to 'decimal'
; EXPLANATION:
; 	Takes a string from a binary file, converts
; 	it into a human-readable ASCII-character
; 	string. The ASCII-string must be at
;	least 8 times the length of the 'binary'
;   string and the 'binary' input must necessarily
; 	be of maximum 2^64 / 8 - 1 bytes of length.
; 	Exceeding this limit will cause an infinite
;	loop condition.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
global binToDec
binToDec:
    push rbp
	mov rbp, rsp
	sub rsp, 24				; space for two pointers and one integer

	mov [rbp - 8], rdi		; store binary pointer
	mov [rbp - 16], rdx		; store decimal pointer
	mov [rbp - 24], rsi		; store size

	; c implementation:
	; for(uint64_t i = 0; i < size; i++){
	; 	for(uint8_t = 0; j < 8; j++){
	;		decimal[i*8+j] = (binary[i] & clear[j]) >> (7-j) + 48;
	;	}
	; }
	xor rax, rax						; index i
	loop_start:
		cmp rax, [rbp - 24]				; compare with size
		jge loop_end

		xor dl, dl						; index j
		loop2_start:
			cmp dl, 8					; compare with 8
			jge loop2_end

			mov rdi, [rbp - 8]			; get 'binary' pointer
			mov sil, [rdi + rax]		; dereference 'binary' pointer and get value at index i
			lea rdi, [rel clear]		; dereference 'clear' pointer
			movzx rdx, dl
			and sil, [rdi + rdx]		; get value at index j and clear unnecessary bits
			mov cl, 7					; shift right as many times as needed
			sub cl, dl 
			shr sil, cl
			add sil, 48					; add 48 to create ASCII-Value
			mov rdi, [rbp - 16]			; get 'decimal' pointer
			add rdi, rdx
			mov [rdi + rax * 8], sil	; simple: [rdi + rax * 8 + dl]
			
			inc dl
			jmp loop2_start
		loop2_end:
			inc rax
			jmp loop_start
		
	loop_end:
	lea rax, [rbp - 16]			; return 'decimal' reference

	leave
	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; NAME: binToHex
; ARGUMENTS:
;	rdi: 'binary' string
;	rsi: 'size' size_t size of string
;	rdx: 'decimal' -> 2 times the length of 'binary'
; RETURN VALUE:
; 	rax: pointer to 'hexadecimal'
; EXPLANATION:
; 	Takes a string from a binary file, converts
; 	it into a human-readable ASCII-character
; 	string. The ASCII-string must be at
;	least 2 times the length of the 'binary'
;   string and the 'binary' input must necessarily
; 	be of maximum 2^64 / 2 - 1 bytes of length.
; 	Exceeding this limit will cause an infinite
;	loop condition.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
global binToHex
binToHex:
	push rbp
	mov rbp, rsp
	sub rsp, 24

	mov [rbp - 8], rdi		; store binary pointer
	mov [rbp - 16], rdx		; store hexadecimal pointer
	mov [rbp - 24], rsi		; store size

	; c implementation
	; uint8_t retVal, hNibble, uint8_t lNibble;
	; for(uint64_t i = 0; i < size; i++){
	; 	hNibble = (binary[i] || 11110000b) >> 4;
	;	lNibble = binary[i] || 00001111b;
	;	if(hNibble < 10){
	;		hNibble += 48;
	;	} else {
	;		hNibble += 55;
	;	}
	; 	if(lNibble < 10){
	;		lNibble += 48;
	;	} else {
	;		lNibble += 55;
	;	}
	;   hexadecimal[i*2] = hNibble;
	;	hexadecimal[i*2+1] = lNibble;
	; }
	xor rax, rax
	
	loop_in:
		cmp rax, [rbp - 24]
		jge loop_out
	
		mov rdi, [rbp - 8]
		mov dl, [rdi + rax]
		mov cl, dl
		and dl, 11110000b
		shr dl, 4
		and cl, 00001111b

		cmp dl, 10
		jl case_dl_1_9
		jmp case_dl_10_15

		case_dl_1_9:
			add dl, 48
			jmp end_dl

		case_dl_10_15:
			add dl, 55
			;jmp end_dl

		end_dl:
			cmp cl, 10
			jl case_cl_1_9
			jmp case_cl_10_15

		case_cl_1_9:
			add cl, 48
			jmp end_cl

		case_cl_10_15:
			add cl, 55
			;jmp end_cl

		end_cl:
			mov rdi, [rbp - 16]
			mov rsi, rax
			shl rsi, 1
			mov [rdi + rsi], dl
			inc rsi
			mov [rdi + rsi], cl

			inc rax
			jmp loop_in
	
	loop_out:
	;DEBUG
	lea rdi, [rel msg]
	mov rsi, rax
	call printf wrt ..plt
	;DEBUG
	
	mov rax, [rbp - 16]	; return 'hexadecimal' reference

	leave
	ret
