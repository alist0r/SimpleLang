;token tyeps
%define SYMBOL 0 ;variable function or label
%define LITERAL 1
%define OPERATOR 2
%define KEYWORD 3
%define DEFINITION 4
%define SEMICOLON 5

;constent types/variable types/type types
%define U64 0
%define I64 1
%define F64 2
%define STRING 3

;keyword types
%define IF 0
%define ENDIF 1
%define GOTO 2

;operator types
%define ADDITION 0
%define SUBTRACT 1
%define MULT 2
%define DIVISION 3
%define LOGICAL_NOT 4
%define LOGICAL_AND 5
%define LOGICAL_OR 6
%define BITWISE_NOT 7
%define BITWISE_AND 8
%define BITWISE_OR 9
%define NOT_EQUAL 10
%define EQUAL 11
%define LESS_THEN_EQUAL 12
%define GREATER_THEN_EQUAL 13
%define LESS_THEN 14
%define GREATER_THEN 15
%define ASSIGNMENT 16
%define SHIFT_LEFT 17
%define SHIFT_RIGHT 18

;token type 1 byte
;next token 8 bytes
;prv token 8 bytes
;symbol type 1 byte
;ptr to symbol name 8 bytes
%define SYMBOL_SIZE 26

;token type 1 byte
;next token 8 bytes
;prv token 8 bytes
;literal value/string ptr 8 bytes
;string len if string 8 bytes
%define LITERAL_SIZE 33

;token type 1 byte
;next token 8 bytes
;prv token 8 bytes
;operator type 1 byte
%define OPERATOR_SIZE 18

;token type 1 byte
;next token 8 bytes
;prv token 8 bytes
;keyword_type 1 byte
%define KEYWORD_SIZE 18

;token type 1 byte
;next token 8 bytes
;prv token 8 bytes
;definition_type 1 byte
%define DEFINITION_SIZE 18

;token type 1 byte
;next token 8 bytes
;prv token 8 bytes
%define SEMICOLON_SIZE 17

global lexer

extern exit
extern alloc
extern free

extern file_buffer
extern file_len

section .text
is_letter_or_number:
	cmp dh, '0'
	jb .not_num
	cmp dh, '9'
	ja .not_num

	.hit:
	mov rax, 1
	ret
	
	.not_num:
	cmp dh, 'a'
	jb .not_lower
	cmp dh, 'z'
	ja .not_lower
	jmp .hit
	
	.not_lower:
	cmp dh, 'A'
	jb .not_upper
	cmp dh, 'Z'
	ja .not_upper
	jmp .hit
	
	.not_upper:
	mov rax, 0
	ret
	


lexer:
	mov rbx, [file_buffer] ;get buffer addr
	mov rsi, [lexer_position] ;get current offset

	;locate start of next thing to tokanize
	.skip_whitespace:
	inc rsi ;prepare for next byte
	mov rdx, [file_len]
	cmp rsi, rdx ;see if we have reached eof
	jae .eof

	xor rdx, rdx ;clear rdx, will read bytes
	mov dl, rbx[rsi] ;get current byte
	cmp dl, ' ' ;check if space
	je .skip_whitespace
	cmp dl, 0x0A ;check if new line
	je .skip_whitespace
	cmp dl, 0x09 ;check if tab
	je .skip_whitespace

	;locate end of next thing to tokanize
		;if + then done
		;if - then done
		;if * then done
		;if / then done
		;if ~ then done (bitwise not)
		;if < check for < or =
		;if > check for > or =
		;if ! check for =
		;if | check for |
		;if & check for &
	cmp dl, '+'
	je .plus
	cmp dl, '-'
	je .minus
	cmp dl, '*'
	je .mult
	cmp dl, '/'
	je .div
	cmp dl, '"'
	je .string_lit
	cmp dl, "'" ;' char
	je .char_lit
	cmp dl, '~'
	je .bitwise_not
	cmp dl, '<'
	je .less_tree
	cmp dl, '>'
	je .greater_tree
	cmp dl, '!'
	je .not_tree
	cmp dl, '|'
	je .or_tree
	cmp dl, '&'
	je .and_tree
	cmp dl, ';'
	je .semi

	;at this point its none of the operators which means we need to determin the
	;dynamic length of the string 
	mov rdi, rsi ;use rdi to find len
	.find_len:
	inc rdi ;check next byte
	mov dh, rbx[rdi] ;get byte
	cmp dh, ':' ;check if collen
	je .label

	call is_letter_or_number ;check if valid char (letter or number)

	cmp rax, 1 ;check output of is letter or number
	je .find_len
	dec rdi ;if not valid char then it will be a symbol of rsi - rdi - 1 length
	jmp .int_lit

	;NOTE theres probably away to have an operator section to avoid
	;     repeated code
	.plus:
	push rsi ;avoid clobs
	push rbx

	mov rax, OPERATOR_SIZE ;get size of toke
	call alloc ;alloc space for token

	pop rbx ;restore regs
	pop rsi

	mov rdx, OPERATOR ;get token type
	mov [rax], rdx ;write type
	mov rdx, ADDITION ;get op type
	mov [rax + 17], rdx ;write op type
	
	call add_token_to_list
	jmp .skip_whitespace
	
	.minus:
	push rsi ;avoid clobers
	push rbx

	mov rax, OPERATOR_SIZE ;get size of toke
	call alloc ;alloc space for token

	pop rbx ;restore regs
	pop rsi

	mov rdx, OPERATOR ;get token type
	mov [rax], rdx ;write type
	mov rdx, SUBTRACT ;get op type
	mov [rax + 17], rdx ;write op type
	
	call add_token_to_list
	jmp .skip_whitespace

	.mult:
	push rsi ;avoid clobers
	push rbx

	mov rax, OPERATOR_SIZE ;get size of toke
	call alloc ;alloc space for token

	pop rbx ;restore regs
	pop rsi

	mov rdx, OPERATOR ;get token type
	mov [rax], rdx ;write type
	mov rdx, MULT ;get op type
	mov [rax + 17], rdx ;write op type
	
	call add_token_to_list
	jmp .skip_whitespace

	.div:
	push rsi ;avoid clobers
	push rbx

	mov rax, OPERATOR_SIZE ;get size of toke
	call alloc ;alloc space for token

	pop rbx ;restore regs
	pop rsi

	mov rdx, OPERATOR ;get token type
	mov [rax], rdx ;write type
	mov rdx, DIVISION ;get op type
	mov [rax + 17], rdx ;write op type
	
	call add_token_to_list
	jmp .skip_whitespace

	.bitwise_not:
	push rsi ;avoid clobers
	push rbx

	mov rax, OPERATOR_SIZE ;get size of toke
	call alloc ;alloc space for token

	pop rbx ;restore regs
	pop rsi

	mov rdx, OPERATOR ;get token type
	mov [rax], rdx ;write type
	mov rdx, BITWISE_NOT ;get op type
	mov [rax + 17], rdx ;write op type
	
	call add_token_to_list
	jmp .skip_whitespace

	.string_lit:
	.char_lit:
	.less_tree:
	.greater_tree:
	.not_tree:
	.or_tree:	
	.and_tree:
	.label:
	.int_lit:
	;need to check if float or int
	;to be an int must be all number chars
	;to be a float must contain decimal point
	;if not int or float then it must be some kind of symbol
	jmp .keyword
	.keyword:
	;need to check if keyword or definition
	;if not must be some kind of symbol
	jmp .symbol
	.symbol:
	.semi:
	mov [lexer_position], rsi
	ret

	;get total length of thing to tokanize
	;turn thing into a string
	;do expression matching to determin how to tokanize it
	;allocate space for a token
	;make token and write token fields
	;from lexer_position turn each symbol into a token untill semicolan
	;return
	.eof:
	mov rax, 0
	call exit

section .data
token_head: dq 0
lexer_position: dq -1 ;start of loop will inc to 0
if: db "if", 0
endif: db "endif", 0
goto: db "goto", 0
print: db "print", 0
int: db "i64", 0
floating_point: db "f64", 0
unsigned: db "u64", 0
