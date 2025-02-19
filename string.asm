global print_string
global atoi
global strcmp

extern exit

;prints to stdout
;clobers rax, rdi
;inputs:
;	rsi = str addr, rdx = strlen
;outputs:
;	rax = bytes or -1 on error
print_string:
	mov rax, 1 ;sys_write
	mov rdi, 1 ;destination stdout
	syscall

	cmp rax, -1 ;check for err
	je .error
	.no_error:
		ret
	.error:
		mov rdi, 1
		call exit ;TODO error handling

;converts string to float
;inputs
;	rsi = string
;output
;	rax = float
atof:
;checks if all members of a string are numbers
;inputs
;	rsi = string
;output
;	rax = true false value
is_int:
	mov dl, [rsi] ;get char
	cmp dl, 0 ;see if null char
	je .is_num
	cmp dl, '0' ;see if below 0
	jb .not_num
	cmp dl, '9' ;see if above 9
	ja .not_num
	inc rsi ;prepare to get next byte
	jmp is_int

	.not_num:
	mov rax, 0 ;return false
	ret
	
	.is_num:
	mov rax, 1 ;return true
	ret

;converts string to int
;clobers rax, rsi, rcx, r8, rdx
;inputs
;	rax = string
;outputs
;	rax = int
;	rdx = error
atoi:
	mov rsi, rax ;prepare for call
	mov r8, rsi ;save the string
	call is_int ;check if int
	cmp rax, 0
	je .error ;if not int then error

	;improptu str len bc is_int moved rsi to null char
	mov rcx, rsi
	sub rcx, r8 

	mov rsi, r8 ;replace string
	xor r8, r8 ;use r8 to stor res

	.get_num:
	push rcx ;save strlen


	mov rax, 10 ;base 10
	mov r9, 10
	.loop:
	mul r9 ;get 10^rcx
	loop .loop
	mov rax, r9 ;save result
	
	pop rcx ;get strlen

	mov rdx, [rsi] ;get char
	sub rdx, '0' ;get dig
	mul rdx  ;multiply power of 10 by dig
	add r8, rax ;store res
	
	cmp rcx, 0
	dec rcx
	jne .get_num

	mov rax, r8 ;caller expects res in rax

	.success:
	mov rdx, 0
	ret
	.error:
	mov rdx,1 
	ret


;converts int to string
;inputs:
;	inputs
;outputs:
;	outputs
itoa:
;gets length of string (must have null char)
;clobers rax, rdx 
;inputs:
;	rsi = string addr
;outputs:
;	rax = length
strlen:
	mov rax, -1 ;init rax
	xor rdx, rdx ;clear rdx
	.loop:
		inc rax ;increase offset by 1
		mov dl, [rsi + rax] ;put char in rdx
		test dl, dl ;if null char
		jnz .loop ;loop if not null char
	ret

;clobers rax, rdx, rsi, rdi
;inputs:
;	rsi = string 1
;	rdi = string 2
;outputs:
;	rax = 1 if match 0 if no match
strcmp:
	xor rdx, rdx ;clear rdx

	.loop:
	mov dl, [rsi] ;get current byte of str1
	mov dh, [rdi] ;get current byte of str2
	inc rsi ;prepare for next byte
	inc rdi ;prepare for next byte
	cmp dl, dh ;compare byte
	je .match ;if same goto match

	;not match
	mov rax, 0 ;0 means no match
	ret

	.match:
	cmp dl, 0 ;check if null char
	jne .loop ;if not check next byte

	;match and null char
	mov rax, 1 ;1 means match
	ret
