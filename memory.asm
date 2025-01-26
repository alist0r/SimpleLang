;Memory in this program is managed by the code below. Pages are obtained from
;the operating system and are stored in a linked list. On each page there is a
;bitmap that keeps track of used memory on that specific page. When the lexer
;or parser needs to create or consolidate a new token, all of the currently
;allocated pages will be searched linierly until a free space is found.
;(first fit) When memory is freed the bitmap of the page that memory is
;allocated on will be updated and then be searched to see if the page is empty.
;If a page is empty, that page will be freed unless it is the last remaining
;page. In that case the page will be saved for the next allocation to avoid
;another mmap call.

;The flowing is a diagram of how these pages will be allocated:
;
;NOTE the addresses on the diagram are of the first used byte of that section.
;the 4096th byte is not used by the page but marks the first address not used
;by the page in its contiguous allocation
;
;                 head
;                  |
;                  v
;offset        first page
;0     +------------------------+
;      |         bitmap         |
;512   +------------------------+
;      |          link          |  -> next page
;520   +------------------------+
;      |                        |
;      |                        |
;      |                        |
;      |       free space       |
;      |     used for tokens    |
;      |                        |
;      |                        |
;      |                        |
;4096  +------------------------+

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
;var type 1 byte
;key (where its in the heap) 8 bytes
%define VARIABLE_SIZE

;token type 1 byte
;prv token ptr 8 bytes
;next token ptr 8 bytes
;var type 1 byte
;value 8 bytes
%define LITERAL_SIZE 1

;token type 1 byte
;prv token ptr 8 bytes
;next token ptr 8 bytes
;op type 1 byte
%define OPERATOR_SIZE 2

;token type 1 byte
;prv token ptr 8 bytes
;next token ptr 8 bytes
;keyword type
%define KEYWORD_SIZE 3

;token type 1 byte
;prv token ptr 8 bytes
;next token ptr 8 bytes
%define DEFINITION_SIZE 4

;token type 1 byte
;prv token ptr 8 bytes
;next token ptr 8 bytes
;TODO ?
%define FUNCTION_SIZE 5

;token type 1 byte
;prv token ptr 8 bytes
;next token ptr 8 bytes
%define LABEL_SIZE 9

;token type 1 byte
;prv token ptr 8 bytes
%define SEMICOLON_SIZE 7

global init_memory
global alloc_token
global free_token

section .text ;initalizes page memory setting the page's bitmap and ptr ;clobers rdx, rdi, rcx ;inputs ;	rax = address of page to be initalized
;outputs
;	none
init_page:
	mov rdi, rax ;put base address in rdi
	mov rdx, 0xFFFFFFFFFFFFFFFF ;put all 1s in rdx to mark used memory
	mov rcx, 64 ;the memory map will be marked by the bitmap which uses 64*8 bytes

	;NOTE i do not 0 the rest of the memory becuse that is done by the os

	.set_mem:
	mov [rdi], rdx ;set memory to 1s
	add rdi, 8 ;change addr to next word
	loop .set_mem
	ret

;get first page used for dynamic memory from linux using mmap and set page_head
;clobers rax, rdi, rsi, rdx, r10, r8, r9
;inputs
;	none
;outputs
;	none
init_memory:
	;mmap call to get first page
	mov rax, 9 ;mmap
	xor rdi, rdi ;addr
	mov rsi, 4096 ;len
	mov rdx, 0x03 ;PROT_READ | PROT_WRITE
	mov r10, 0x22 ;MAP_ANONYMOUS
	mov r8, -1 ;file descriptor
	mov r9, 0 ;pgoff (page offset i think? i dont know what this does)
	syscall

	;TODO error checking

	mov [page_head], rax ;move address of first page into page_head
	call init_page ;sets up memory of new page

	ret

;allocates memory for a token used by lexer and parser
;if page is full calls alloc_page
;clobers
;inputs
;	token type
;outputs
alloc_token:

;gets a new page using mmap and puts it at the tail of the page link
;clobers
;inputsa
;outputs
alloc_page:

;frees the given page adress and fills in that gap in the linked list
;if the given page is the only allocated page then does nothing
;clobers
;inputsa
;outputs
free_page:

;updates bitmap on page the token is on to indicate that memory space is free
;clobers
;inputsa
;outputs
free_token:

section .data
page_head: dq 0
variable_count: dq 0
