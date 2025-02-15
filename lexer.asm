;token tyeps
%define SYMBOL 0 ;variable function or label
%define LITERAL 1
%define OPERATOR 2
%define KEYWORD 3
%define DEFINITION 4

;symbol types
%define VARIABLE 0
%define LABEL 1
%define FUNCTION 2

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
%define LESS_THAN_EQUAL 12
%define GREATER_THAN_EQUAL 13
%define LESS_THAN 14
%define GREATER_THAN 15
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
;literal type 1 byte
;literal value/string ptr 8 bytes
%define LITERAL_SIZE 26

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

global lexer

extern exit
extern alloc
extern free

extern strcmp
extern atoi

extern file_buffer
extern file_len

section .text
;inputs
;	rax = token
;outputs
;	none
add_token_to_list:
	mov rdx, [token_head] ;prepare for cmp
	cmp rdx, 0 ;check if list is empty
	je .empty_list

	mov rdx, [rdx] ;check token
	.goto_end_of_list:
	mov rcx, [rdx + 1] ;get ptr 
	cmp rcx, 0 ;check if null
	je .found_end

	mov rdx, [rdx + 1]
	jmp .goto_end_of_list

	.empty_list:
	mov [token_head], rax
	ret
	
	.found_end:
	mov [rdx + 1], rax ;put next link in prv
	mov [rax + 9], rdx ;put prv link in next
	ret

;clobers r8
;preservs rsi, rbx
;inputs
;	rax = token type
;	rcx = token subtype
;	rdx = token value
;outputs
;	rax = token address
make_token:
	cmp rax, SYMBOL
	je .size_big
	cmp rax, LITERAL
	je .size_big
	cmp rax, OPERATOR
	je .size_small
	cmp rax, KEYWORD
	je .size_small
	cmp rax, DEFINITION
	je .size_small
	.size_big:
	mov r8, SYMBOL_SIZE
	jmp .next_step
	.size_small:
	mov r8, OPERATOR_SIZE
	jmp .next_step

	.next_step:
	push rax
	push rcx
	push rdx
	push rsi ;avoid clobs
	push rbx

	mov rax, r8 ;get size of toke
	call alloc ;alloc space for token

	pop rbx ;restore regs
	pop rsi
	pop rdx
	pop rcx
	pop r8

	mov [rax], r8 ;write type
	mov [rax + 17], rcx ;write sub type

	cmp r8, LITERAL
	je .add_value
	cmp r8, SYMBOL
	je .add_value
	ret

	.add_value:
	mov [rax + 18], rdx
	ret

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

	.plus:
	mov rax, OPERATOR
	mov rcx, ADDITION
	call make_token;alloc space for token
	call add_token_to_list
	jmp .skip_whitespace
	
	;TODO the '-' symbol may actualy be indicating a negative number
	.minus:
	mov rax, OPERATOR
	mov rcx, SUBTRACT
	call make_token;alloc space for token
	call add_token_to_list
	jmp .skip_whitespace

	.mult:
	mov rax, OPERATOR
	mov rcx, MULT
	call make_token;alloc space for token
	call add_token_to_list
	jmp .skip_whitespace

	.div:
	mov rax, OPERATOR
	mov rcx, DIVISION 
	call make_token;alloc space for token
	call add_token_to_list
	jmp .skip_whitespace

	.bitwise_not:
	mov rax, OPERATOR
	mov rcx, BITWISE_NOT 
	call make_token;alloc space for token
	call add_token_to_list
	jmp .skip_whitespace

	.string_lit:
	mov rdi, rsi ;use rdi to find the end quote
	.string_loop:
	inc rdi ;check next byte
	mov dl, rbx[rdi] ;get byte
	cmp dl, '"' ;check if end quote
	jne .string_loop ;if not end quote then check next byte
	
	;strlen = rdi - rsi - 1
	mov rcx, rdi
	sub rcx, rsi
	dec rcx
	mov r8, rcx ;save copy of strlen for later

	mov rsi, rdi ;update lexer position to be end of str

	push 0 ;null char
	cmp rcx, 0 ;see if empty string
	je .end_of_str_loop

	xor rdx, rdx ;clear rdx just in case
	.push_str_loop:
	dec rdi ;get prv byte
	mov dl, rbx[rdi] ;get byte
	push rdx ;put byte on the stack
	loop .push_str_loop
	.end_of_str_loop:

	inc r8 ;+1 for null char
	push r8 ;len
	push rbx ;addr
	push rsi ;lexer pos

	mov rax, r8 ;strlen
	call alloc

	pop rsi ;get lexer pos
	pop rbx ;get addr 
	pop rcx ;get strlen
	
	xor rdi, rdi ;clear rdi for loop
	.pop_str_loop:
	pop rdx ;get char from stack
	mov rax[rdi], dl ;save char in memory
	inc rdi ;prepare to write next char
	loop .pop_str_loop
	
	push rax ;save str
	push rsi ;avoid clobers
	push rbx

	mov rax, LITERAL_SIZE ;get size of toke
	call alloc ;alloc space for token

	pop rbx ;restore regs
	pop rsi
	pop rdi ;get str back

	mov rdx, LITERAL ;set token type
	mov [rax], rdx ;place token type
	mov rdx, STRING ;get value of string
	mov [rax + 17], rdx ;place literal type
	mov [rax + 18], rdi ;place str addr in token 
	
	call add_token_to_list
	jmp .skip_whitespace

	.less_tree:
	mov rax, OPERATOR ;prepareing for later allocation

	mov rdi, rsi ;get lexer pos
	inc rdi ;check next byte
	mov dl, rbx[rdi] ;grab byte

	cmp dl, '='
	je .less_equal
	cmp dl, '<'
	je .bit_lshift
	jmp .less_than

	.less_equal:
	mov rcx, LESS_THAN_EQUAL 
	inc rsi ;start lexer from after this operator
	jmp .end_less_tree
	
	.bit_lshift:
	mov rcx, SHIFT_LEFT
	inc rsi ;start lexer from after this operator
	jmp .end_less_tree

	.less_than:
	mov rcx, LESS_THAN

	.end_less_tree:
	call make_token;alloc space for token
	call add_token_to_list
	jmp .skip_whitespace

	.greater_tree:
	mov rax, OPERATOR ;prepareing for later allocation

	mov rdi, rsi ;get lexer pos
	inc rdi ;check next byte
	mov dl, rbx[rdi] ;grab byte

	cmp dl, '='
	je .greater_equal
	cmp dl, '>'
	je .bit_rshift
	jmp .greater_than

	.greater_equal:
	mov rcx, GREATER_THAN_EQUAL
	inc rsi ;start lexer from after this operator
	jmp .end_greater_tree
	
	.bit_rshift:
	mov rcx, SHIFT_RIGHT
	inc rsi ;start lexer from after this operator
	jmp .end_greater_tree

	.greater_than:
	mov rcx, GREATER_THAN 

	.end_greater_tree:
	call make_token;alloc space for token
	call add_token_to_list
	jmp .skip_whitespace

	.not_tree:
	mov rax, OPERATOR ;prepareing for later allocation

	mov rdi, rsi ;get lexer pos
	inc rdi ;check next byte
	mov dl, rbx[rdi] ;grab byte

	cmp dl, '='
	je .not_equal

	;logical not
	mov rcx, LOGICAL_NOT
	jmp .end_not_tree

	.not_equal:
	mov rcx, NOT_EQUAL
	inc rsi ;start lexer from after this operator
	jmp .end_not_tree

	.end_not_tree:
	call make_token ;alloc space for token
	call add_token_to_list
	jmp .skip_whitespace

	.or_tree:
	mov rax, OPERATOR ;prepareing for later allocation

	mov rdi, rsi ;get lexer pos
	inc rdi ;check next byte
	mov dl, rbx[rdi] ;grab byte

	cmp dl, '|'
	je .logical_or

	;bitwise or
	mov rcx, BITWISE_OR
	jmp .end_or_tree

	.logical_or:
	mov rcx, LOGICAL_OR
	inc rsi ;start lexer from after this operator
	jmp .end_not_tree

	.end_or_tree:
	call make_token ;alloc space for token
	call add_token_to_list
	jmp .skip_whitespace
	
	.and_tree:
	mov rax, OPERATOR ;prepareing for later allocation

	mov rdi, rsi ;get lexer pos
	inc rdi ;check next byte
	mov dl, rbx[rdi] ;grab byte

	cmp dl, '&'
	je .logical_and

	;bitwise or
	mov rcx, BITWISE_AND
	jmp .end_and_tree

	.logical_and:
	mov rcx, LOGICAL_AND
	inc rsi ;start lexer from after this operator
	jmp .end_and_tree

	.end_and_tree:
	call make_token ;alloc space for token
	call add_token_to_list
	jmp .skip_whitespace
	
	.label:
	push rdi ;save end of label for later
	mov rdx, 0 ;null char
	push rdx ;put on 0 the stack

	mov rcx, rdi ;strlen
	sub rcx, rsi
	mov r8, rcx ;save strlen for later
	dec rcx ;dont need null char in loop
	
	.label_push_loop:
	dec rdi ;get prv byte
	mov dl, rbx[rdi] ;bring byte into regs
	push rdx ;put byte on the stack
	loop .label_push_loop

	mov rax, r8 ;get size of string
	push r8
	call alloc ;allocate bytes for string
	
	pop rcx ;get size back
	xor rdi, rdi ;prepare rdi for offset
	.label_pop_loop:
	pop rdx ;get char off the stack
	mov dl, rax[rdi] ;move it to the heap
	inc rdi ;prepare for next byte
	loop .label_pop_loop
	mov rdx, rax ;put str in rdx for maketoken call
	mov rax, SYMBOL ;put token type for token call
	mov rcx, LABEL ;put symbol subtype
	call make_token
	pop r8 ;get end of label back
	mov [lexer_position], r8 ;save lexer poition as we go to the parser
	ret ;allow parser to save the label in the symbol map

	;TODO add float support
	.int_lit:
	;save buffer ptrs
	mov r10, rdi

	;str len 
	mov rcx, rdi
	sub rcx, rsi
	dec rcx

	mov r11, rcx ;need to pop off stack later

	push 0 ;null char
	;TODO i do this pattern in 3 different places i can refactore this with
	;     a proc
	;put string on the stack
	xor rdx, rdx
	.lit_push:
	dec rdi ; prv byte
	mov dl, rbx[rdi]
	push rdx	
	loop .lit_push

	mov rax, rsp ;stack ptr is pointing to my string
	call atoi ;turn str to int
	cmp rdx, 0 ;see if error
	jne .keyword ;if error then not int
	
	mov rax, LITERAL ;put token type for token call
	mov rcx, U64 ;put literal subtype
	mov rdx, rax ;value to put in token
	call make_token
	call add_token_to_list

	mov rcx, r11 ;get str len back
	inc rcx ;need to pop null char
	.lit_pop:
	pop rdx ;clear stack
	loop .lit_pop

	mov rsi, r10 ;put lexer pos at end of string
	jmp .skip_whitespace
	
	.keyword:
	mov r9, rsi ;save string
	mov rdi, if ;check if if
	call strcmp
	cmp rax, 1
	je .if

	mov rsi, r9 ;string on stack
	mov rdi, endif ;check if endif
	call strcmp
	cmp rax, 1
	je .endif

	mov rsi, r9 ;string on stack
	mov rdi, goto ;check if goto
	call strcmp
	cmp rax, 1
	je .goto

	mov rsi, r9 ;string on stack
	mov rdi, unsigned ;check if unsigned
	call strcmp
	cmp rax, 1
	je .unsigned
	jmp .symbol ;not a keyword

	.if:
	mov rcx, IF
	jmp .end_keyword

	.endif:
	mov rcx, ENDIF
	jmp .end_keyword

	.goto:
	mov rcx, GOTO
	jmp .end_keyword

	.unsigned:
	mov rax, DEFINITION
	mov rcx, U64
	call make_token
	call add_token_to_list
	mov rsi, r10
	jmp .skip_whitespace
	
	.end_keyword:
	mov rax, KEYWORD
	call make_token
	call add_token_to_list
	mov rsi, r10
	jmp .skip_whitespace

	.symbol:
	mov rax, r11 ;get strlen
	inc rax ;include null char
	push rax ;save len
	push rbx ;buffer
	push r10 ;end of str
	call alloc
	pop rsi ;lexer pos
	pop rbx ;buffer
	pop rcx ;get len back

	xor rdi, rdi
	.sym_pop:
	pop rdx ;clear stack
	mov rax[rdi], dl
	inc rdi
	loop .sym_pop

	mov rax, SYMBOL ;put token type for token call
	mov rcx, VARIABLE ;put literal subtype
	mov rdx, rax ;value to put in token
	call make_token
	jmp .skip_whitespace

	.semi:
	mov [lexer_position], rsi
	ret

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
