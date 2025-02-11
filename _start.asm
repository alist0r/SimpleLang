;in linux the following regs are saved
;r12, r13, r15

global _start

global file_buffer
global file_len

extern str_len
extern print_string

extern open_file
extern read_line

extern init_memory

extern lexer

extern parser


section .text
_start:
	call init_memory ;place a page adress at page_head

	mov rdi, file ;file name
	xor rsi, rsi ;flags
	xor rdx, rdx ;mode
	call open_file

	mov [file_buffer], rax
	mov [file_descriptor], r12
	mov [file_len], r13

	mov rsi, [file_buffer]
	mov rdx, [file_len]
	call print_string

	.main_loop:
	call lexer
	call parser
	jmp .main_loop

section .rodata
	file: db "text.txt", 0
section .data
	token_list_head: dq 0
section .bss
	file_buffer: dq ?
	file_descriptor: dq ?
	file_len: dq ?
