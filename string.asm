global print_string
global str_len

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

;converts string to int
;clobers
;inputs
;outputs
string_to_int:
;converts int to string
;inputs:
;	inputs
;outputs:
;	outputs
int_to_string:
;gets length of string (must have null char)
;clobers rax, rdx 
;inputs:
;	rsi = string addr
;outputs:
;	rax = length
str_len:
	mov rax, -1 ;init rax
	xor rdx, rdx ;clear rdx
	.loop:
		inc rax ;increase offset by 1
		mov dl, [rsi + rax] ;put char in rdx
		test dl, dl ;if null char
		jnz .loop ;loop if not null char
	ret
