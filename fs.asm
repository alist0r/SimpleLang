global open_file
global read_line

;opens a file and stores it into a buffer
;clobers rax, rdi, rsi, rdx, r6
;inputs:
;	rdi = file name
;	rsi = flags
;	rdx = mode
;outputs:
;	rax = buffer
;	r12 = file descriptor
;	r13 = file size
open_file:
	mov rax, 2 ;open
	syscall

	mov r12, rax ;save file descriptor

	;lseek should return the size of the file in bytes
	mov rdi, rax ;file descriptor
	xor rsi, rsi ;file offset
	mov rdx, 2 ;SEEK_END
	mov rax, 8 ;lseek
	syscall 	
	
	mov r13, rax ;save file size

	;lseek should move back to begining of file
	mov rdi, r12 ;file descriptor
	xor rsi, rsi ;file offset
	xor rdx, rdx ;SEEK_SET
	mov rax, 8 ;lseek
	syscall

	inc rax ;size + 1

	mov r10, 0x22 ;flags
	mov rdx, 0x03 ;prot
	mov rsi, rax ;len
	xor rdi, rdi ;addr
	mov rax, 0x09 ;mmap
	syscall

	mov r14, rax ;save buffer
	mov rdi, r12 ;file descriptor
	mov rsi, rax ;buffer addr
	mov rdx, r13 ;count
	xor rax, rax ;read
	syscall
	
	mov rax, r14
	
	ret

;read next line from file
;clobers rax
;inputs
;	rdi = file descripter, rsi = buffer, rdx = count
;outputs
read_line:
	xor rax, rax
	syscall

	;TODO error handling
	ret
