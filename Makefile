make: 
	nasm -g -f elf64 _start.asm
	nasm -g -f elf64 string.asm
	nasm -g -f elf64 lexer.asm
	nasm -g -f elf64 os.asm
	nasm -g -f elf64 fs.asm
	nasm -g -f elf64 memory.asm
	nasm -g -f elf64 parser.asm
	ld string.o _start.o os.o fs.o memory.o parser.o lexer.o -o SimpleLang
clean:
	rm *.o
