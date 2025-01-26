;Memory in this program is managed by the code below. Pages are obtained from
;the operating system and are stored in a linked list. On each page there is a
;bitmap that keeps track of used memory on that specific page. When the lexer
;or parser needs to create or consolidate a new token, all of the currently
;allocated pages will be searched linierly until a free space is found.
;(first fit) When memory is freed the bitmap of the page that memory is
;allocated on will be updated and then be searched to see if the page is empty.
;If a page is empty, that page will be freed unless it is the last remaining
;page. In that case the page will be saved for the next allocation to avoid
;another mmap call. The tokens will also be ptr to each ther in a double linked
;list to make resolving them while parsing easier to program

;The flowing is a diagram of how these pages will be allocated:
;
;                 head
;                  |
;                  v
;offset        first page
;0     +------------------------+ the space the bitmap takes up is implicit
;      |         bitmap         | and thus unmaped saving 57 bytes
;455   +------------------------+ the first bit marks 463 and then so on
;      |          link          |  -> next page
;463   +------------------------+
;      |                        |
;      |                        |
;      |                        |
;      |       free space       |
;      |     used for tokens    |
;      |                        |
;      |                        |
;      |                        |
;4095  +------------------------+

%define VARIABLE 0
%define LITERAL 1
%define OPERATOR 2
%define KEYWORD 3
%define DEFINITION 4
%define FUNCTION 5
%define LABEL 6
%define SEMICOLON 7


;sizes of tokens in bytes
;token type 1 byte
;prv token ptr 8 bytes
;next token ptr 8 bytes
;var type 1 byte
;key (where its in the heap) 8 bytes
%define VARIABLE_SIZE 26

;token type 1 byte
;prv token ptr 8 bytes
;next token ptr 8 bytes
;var type 1 byte
;value/ptr if string 8 bytes
;length of string if string 8 bytes
%define LITERAL_SIZE 34

;token type 1 byte
;prv token ptr 8 bytes
;next token ptr 8 bytes
;op type 1 byte
%define OPERATOR_SIZE 18

;token type 1 byte
;prv token ptr 8 bytes
;next token ptr 8 bytes
;keyword type 1 byte
%define KEYWORD_SIZE 18

;token type 1 byte
;prv token ptr 8 bytes
;next token ptr 8 bytes
;def type 1 byte
%define DEFINITION_SIZE 18

;token type 1 byte
;prv token ptr 8 bytes
;next token ptr 8 bytes
;TODO ?
%define FUNCTION_SIZE 9

;token type 1 byte
;prv token ptr 8 bytes
;next token ptr 8 bytes
;label file offset/position 8 bytes
%define LABEL_SIZE 25

;token type 1 byte
;prv token ptr 8 bytes
%define SEMICOLON_SIZE 9

global init_memory
global alloc_token
global free_token

section .text
;get first page used for dynamic memory and places the addr at page_head
;clobers rax, rdi, rsi, rdx, r10, r8, r9
;inputs:
;	none
;outputs:
;	none
init_memory:
	call alloc_page

	;the page does not need to be initialized as for security reasons the os
	;should 0 everything

	mov [page_head], rax ;move address of first page into page_head

	ret
;search bitmap for free space and set bitmap on a success
;clobers
;inputs:
;	r12 token type
;	rbx page addr
;outputs:
;	rax addr

check_bitmap:
	;find first 0
	;mark bit of first 0
	;find congruent bits equ to size
	;mark bits in bitmap
	;return address on success
	;return 0 on fail
	ret

;allocates memory for a token used by lexer and parser
;if page is full calls alloc_page
;clobers rax, rbx, r12
;inputs:
;	rax token type
;outputs:
;	rax adress of token space
;	r12 token type
alloc_token:
	mov rbx, [page_head] ;get address of first page
	mov r12, rax ;save token type, r12 should be preserved in proc/calls

	.mapcheck:
	call check_bitmap
	cmp rax, 0 ;check_bitmap will set 0 in rax on bitmap full
	je .page_full

	ret ;mapcheck returnd an addr in rax

	.page_full:
	cmp rbx[455], 0 ;see if there is another page, 455 is offset of link
	je .new_page_needed

	mov rbx, rbx[455] ;setup check of next page
	jmp .mapcheck

	.new_page_needed:
	push rbx ;save current page
	call alloc_page

	pop rbx ;get page back
	mov rbx[455], rax ;set ptr to new page addr
	mov rbx, rax ;set rbx to new page addr
	jmp .mapcheck ;reuse code, should always succeed since new page empty

;gets a new page using mmap
;clobers rax, rdi, rsi, rdx, r10, r8, r9, rbx
;inputs
;	rax = prv page addr
;	
;outputs
;	rax = new page addr
alloc_page:
	;mmap call to get new page
	mov rax, 9 ;mmap
	xor rdi, rdi ;addr
	mov rsi, 4096 ;len
	mov rdx, 0x03 ;PROT_READ | PROT_WRITE
	mov r10, 0x22 ;MAP_ANONYMOUS
	mov r8, -1 ;file descriptor
	mov r9, 0 ;pgoff (page offset i think? i dont know what this does)
	syscall

	;TODO error checking

	ret
	
;frees the given page adress and fills in that gap in the linked list
;if the given page is the only allocated page then does nothing
;clobers
;inputsa
;outputs
free_page:
	;munmap given page
	;chage ptr to pointer of head if freeing first page
	;change ptr of last page to page after if middle page
	;change ptr of last page to 0 if last page
	ret

;updates bitmap on page the token is on to indicate that memory space is free
;clobers
;inputs
;	token addr
;outputs
free_token:
	;change bitsin bitmap of token addr to 0
	;change pts of neibour tokens
	;if page token is on is empty free page
	ret

section .data
page_head: dq 0
token_head: dq 0
variable_count: dq 0
