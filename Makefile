make: 
	nasm -g -f elf64 _start.asm
	nasm -g -f elf64 string.asm
	nasm -g -f elf64 os.asm
	nasm -g -f elf64 fs.asm
	ld string.o _start.o os.o fs.o -o SimpleLang
