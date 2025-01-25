;in linux the following regs are saved
;r12, r13, r15

extern str_len
extern print_string
extern exit
extern open_file
extern read_line
extern init_memory

section .text
global _start
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

	mov rdi, 0
	call exit

section .rodata
	file: db "text.txt", 0
section .data
	token_list_head: dq 0
section .bss
	file_buffer: dq ?
	file_descriptor: dq ?
	file_len: dq ?
