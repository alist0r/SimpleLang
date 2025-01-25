global exit
;stops process
;clobers rax
;inputs
;	rdi = exit code
exit:
	mov rax, 60 ;sys_exit
	syscall
