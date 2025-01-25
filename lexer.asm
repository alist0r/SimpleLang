;token tyeps
%define VARIABLE 0
%define LITERAL 1
%define OPERATOR 2
%define KEYWORD 3
%define TYPE 4
%define SEMICOLON 5

;constent types/variable types/type types
%define U8 0
%define U16 1
%define U32 2
%define U64 3
%define I8 4
%define I16 5
%define I32 6
%define I64 7
%define F32 8
%define F64 9
%define STRING 10

;keyword types
%define IF 0
%define ENDIF 1
%define GOTO 2

global create_next_token

extern exit

is_lower_case:
ret

is_upper_case:
ret

is_num:
ret

alloc_token:

free_token:

;create new token and allocate memory for it
;clobers:
;inputs:
;	rax = token type
;	rdi = ptr to next
;	rsi = ptr to prv token
;	rdx = var type/operator type/keyword type/type type
;	r10 = value/ptr to item in file buffer
;	r8 = length of item in file buffer
;outputs:
;	rax = ptr to token
make_token:
	;if else block
	cmp rax, VARIABLE
	je .variable
	cmp rax, LITERAL
	je .literal
	cmp rax, OPERATOR
	je .operator
	cmp rax, KEYWORD
	je .keyword
	cmp rax, TYPE
	je .type
	cmp rax, SEMICOLON
	je .semicolon

	.variable:
	;check if rsi is 0
	;if 0 allocate memory and set token_list_head to that memory
	;if not 0 allocate memory and set ptr + 1 to that memory location
	
	;fill memory 
	ret
	.literal:
	ret
	.operator:
	ret
	.keyword:
	ret
	.type:
	ret
	.semicolon:
	ret
	;call mmap to allocate memory for next token
	;write next token and fill out ptrs
	;write to the next token slot of the previous token

;makes sure in range of buffer
;clobers r12
;inputs:
;	rax = token base
;	rdi = file buffer
;	rsi = buffer size
;outputs:
;	r12 = 1 if in range 0 if out of range
check_buffer_range:
	cmp rax, rsi ;check if greatr or equal to buffer
	jge .out_of_range ;if out of range
	mov r12, 1 ;else put 1 in r12
	ret
	.out_of_range:
	mov r12, 0 ;if out of range put 0 in r12
	ret



;skims through buffer to find the starting point and end point of next token
;clobers: rax, rdx, rbx
;inputs:
;	rax = end of last token location
;	rdi = file buffer
;	rsi = buffer size
;	rdx = previous token ptr
;outputs:
;	rax = token ptr in heap
;	r12 = token base in file buffer
;	r13 = token len in file buffer
create_next_token:
	mov rbx, rdx ;move list head into rbx for later

	.skip_whitespace:
	xor rdx, rdx ;clear rdx for cmp
	inc rax ;set rax to the next char
	call check_buffer_range
	cmp r12, 0 ;if 0 then not in range
	jne .in_range ;if not 0 then in range
	xor rdi, rdi ;reached EOF exit with code 0
	call exit

	.in_range:
	mov dl, rdi[rax] ;move the next char into dl
	cmp dl, ' ' ;compare next char to space
	je .skip_whitespace ;if there is space check next char
	cmp dl, '\t'
	je .skip_whitespace ;if there is tab check next char
	cmp dl, '\n'
	je .skip_whitespace ;if there is new line check next char

	;else if block
	cmp dl, ';' ;end of line
	je .semicolon
	cmp dl, '!' ;not
	je .bang
	cmp dl, '~' ;bitwise not
	je .tilde
	cmp dl, '+' ;add
	je .plus
	cmp dl, '-' ;sub
	je .minus
	cmp dl, '=' ;assignment
	je .equal
	cmp dl, '>' ;greater then
	je .greater_than
	cmp dl, '<' ;less then
	je .less_than
	cmp dl, '&' ;and
	je .and
	cmp dl, '|' ;or
	je .or
	cmp dl, 'u' ;unsigned
	je .unsigned
	cmp dl, 'i' ;if or integer
	je .signed
	cmp dl, 'f' ;float
	je .float
	cmp dl, 'e' ;endif
	je .endif
	cmp dl, ''' ;char literal
	je .single_quote
	cmp dl, '"' ;string
	je .double_quote
	call is_lower_case
	jc .lower_case
	call is_upper_case
	jc .upper_case
	call is_num
	jc .is_num

	;invalid input at this point
	mov rdi, 2
	call exit

	.semicolon:
	;TODO preserve in register the end of this token
	mov rax, SEMICOLON ;else make token
	call make_token
	ret

	.bang:
	;if ! then check if = is next then != else !
	ret
	.tilde:
	;if ~ then done
	ret
	.plus:
	;if + then done
	ret
	.minus:
	;if - then done
	ret
	.equal:
	;if = check for == then == else =
	ret
	.greater_than:
	;if > check for >= then >= else check for >> then >> else >
	ret
	.less_than:
	;if < check for <= then <= else check for << then << else <
	ret
	.and:
	;if & check for && then && else &
	ret
	.or:
	;if | check for || then || else |
	ret
	.unsigned:
	;if u check for 8 16 32 64
	ret
	.signed:
	;if i check for 8 16 32 64 and if
	ret
	.float:
	;if f check for 64
	ret
	.endif:
	;if e check for endif
	ret
	.single_quote:
	;if ' check for a char and then another ' after (charicter literal)
	ret
	.double_quote:
	;if " all text untill next " is a string
	ret
	.num:
	;if number make sure all adgacent chars are numbers or a . for floats
	ret
	;if a number is followed by a char then thats a syntax error
	.lower_case:
	ret
	.upper_case:
	;if char make sure wether or not its a keyword
	;if its not a keyword its a variable
	;in this case the evaluated char is not valid
	ret


;change value or pointers
modify_token:
ret

;frees memory token is useing
destroy_token:
ret
