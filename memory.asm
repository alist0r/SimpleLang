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


global init_memory
global alloc
global free

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
;clobers rax, rdx, rsi, rcx
;inputs:
;	r12 allocation size
;	rbx page addr
;outputs:
;	rax addr
;TODO this implimentation is messy
check_bitmap:
	xor r9, r9 ;clear r9 which will be a 0 counter
	xor rsi, rsi ;prepare rsi for searching bitmap
	xor rdx, rdx ;prepare rdx for storing 1 byte from bitmap
	mov rcx, 57 ;57 * 8 = 456 which is len of bitmap, rdx can hold 8 bytes
	xor rax, rax ;prepare rax which will later store the offset of alloc

	;rsi has offset rbx has page base
	.get_next_word:
	mov r8, rcx ;save which word we were at

	mov rcx, 64 ;64 bits in a register to check
	mov rax, 0x7FFFFFFFFFFFFFFF ;used to cmpare with rdx 011111... etc
	.check_for_zero:
	mov rdx, rbx[rsi] ;put current byte of bitmap in rdx
	or rdx, rax ;check significant bit 0 nor 0 = 1
	not rdx ;negation of or produces nor
	cmp rdx, 0 ;not instruction wont set zero flag
	jnz .found_zero

	;zero not found
	xor r9, r9 ;reset counter

	.shift:
	ror rax, 1 ;check next bit of word on next loop
	loop .check_for_zero ;if not 64 then go again

	;if out of bits
	mov rcx, r8 ;get word counter back
	add rsi, 8 ;check next 64 bits
	loop .get_next_word
	
	;at this point we have reached the end of the bitmap
	;return 0 no memory to alloc	
	mov rax, 0
	ret

	.found_zero:
	cmp r9, 0 
	jnz .not_first
	;first 0
	mov rdi, rsi
	mov r10, rcx
	mov r11, r8	

	.not_first:
	inc r9
	cmp r9, r12
	je .valid_space_found
	jmp .shift

	.valid_space_found:
	;put into rax the offset of the first zero
	;page addr + 463 + (64 - r10) + ((57 - r11) * 64)
	mov rax, 64 ;get max of scale
	sub rax, r10 ;subtract counter
	push rax ;save result of calculation for later

	mov rax, 57 ;get max of scale
	sub rax, r11 ;subtract counter
	mov rdx, 64 ;need to mul by 64
	mul rdx ;multiplay rax by 64
	
	add rax, rbx ;add address of page to word offset
	pop rdx ;get bit offset
	add rax, rdx ;add bit offset
	add rax, 463 ;add offset of actual usable space
	
	mov [rax], rbx ;write bitmap addr to first 8 bytes
	add rax, 8 ;prepare for next write
	mov [rax], r12 ;write size to next 8 bytes
	add rax, 8 ;return address of the rest of allocated space

	push rax ;save addr

	;at this point we found free space and an adress we just need to flip the bits in the bitmap
	xor r9, r9 ;use r9 as a counter
	.write_map:
	mov rdx, rbx[rdi] ;data word from bitmap
	mov r8, rcx ;save word counter
	mov rcx, r10 ;bit counter

	.write_bit:
	mov rax, 0x0000000000000001 ;bit to be shifted
	mov r10, rcx ;save counter
	dec rcx ;shift left counter - 1 bits
	shl rax, cl ;shift left rax rcx times
	mov rcx, r10 ;get counter back
	or rdx, rax ;mark that 1 in the data word
	inc r9 ;++
	cmp r9, r12 ;if equal then done
	je .bitmap_written 
	loop .write_bit

	mov rbx[rdi], rdx ;put word back in memory
	add rdi, 8 ;rdi point to next word
	mov rcx, r8 ;move counter to rcx for loop
	mov r10, 64 ;setup bitcountr
	jmp .write_map

	.bitmap_written:
	mov rbx[rdi], rdx ;put word back in memory
	pop rax ;get addr

	ret

;allocates memory in a page
;if page is full calls alloc_page
;clobers rax, rbx, r12, rdx
;inputs:
;	rax allocated space in bytes
;outputs:
;	rax adress of allocated space
;NOTE currently there is no way to handel large allocations greater then
;	how much can fit on a page
alloc:
	add rax, 16 ;8 bytes reserv for size another 8 for addr of bitmap
	;TODO check if alloc request is greater then 3640
	mov rbx, [page_head] ;get address of first page
	mov r12, rax ;save allocation size, r12 should be preserved in proc/calls

	.mapcheck:
	call check_bitmap
	cmp rax, 0 ;check_bitmap will set 0 in rax on bitmap full
	je .page_full

	ret ;mapcheck returnd an addr in rax

	.page_full:
	mov rdx, rbx[455] ;grab ptr value for use in cmp, 455 is offset of link
	cmp rdx, 0 ;see if there is another page, 
	je .new_page_needed

	;page ptr is not null	
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
;inputs
;	rax = page to free
;outputs
free_page:
	mov rdi, rax ;adress to be freed
	mov rax, 11 ;munmap
	mov rsi, 4096 ;amount to be freed
	syscall

	;TODO error checking

	ret

;updates bitmap on page the token is on to indicate that memory space is free
;clobers
;inputs
;	allocated addr
;outputs
free:
	mov rcx, [rax - 8] ;get size of allocation to free
	mov rbx, [rax - 16] ;get address of bitmap of page this alloc is on

	;address - bitmap addr - 16 - 463 should be bitmap offset
	sub rax, rbx ;suntract adress of bitmap
	sub rax, 16 ;subtract offset of reserved metadata space
	sub rax, 463 ;suntract offset of memory and bitmap
	
	xor rdx, rdx ;clear rdx
	mov r9, 64 ;div by word size
	div r9 ;this division will place word containing bit in rax and
	       ;bit offset in rdx

	;setup offsets
	mov rdi, rax ;save word offset
	mov rax, rbx[rdi] ;get word at word offset
	mov r9, rdx ;save bit offset
	mov rdx, 0x8000000000000000 ;bit to shift around
	xchg r9, rcx ;need cl for shr
	shr rdx, cl ;shr
	xchg rcx, r9 ;swap back

	.write_bitmap:
	not rdx ;turn target bit to 0
	and rax, rdx ;set 1 at target bit to 0
	inc r9 ;prepare for next bit offset
	cmp r9, 64 ;if 64 we need a new data word
	je .next_word

	;same word
	not rdx ;swap for 1 shifting
	shr rdx, 1 ;shift to right for next bit
	loop .write_bitmap
	jmp .done_writing

	.next_word:
	mov rbx[rdi], rax ;put written word back in bitmap
	add rdi, 8 ;get next word index
	mov rax, rbx[rdi] ;get word
	mov rdx, 0x8000000000000000 ;bit to shift around
	mov r9, 0 ;reset bit offset
	jmp .write_bitmap	

	.done_writing:
	mov rbx[rdi], rax ;put written word back in bitmap
	
	mov rcx, 57 ;57 words in bitmap
	xor rdx, rdx ;clear rdx
	xor rdi, rdi ;reset rdi
	.check_if_page_empty:
	mov rdx, rbx[rdi] ;get current word
	cmp rdx, 0 ;check if 0
	jne .end ;if not 0 then dont free
	add rdi, 8 ;prepare to check next word
	loop .check_if_page_empty
	;at this point all words are 0 so we can free this page

	;check if only page
	mov rax, rbx ;get page adress
	xor rax, page_head ;will be 0 if first page
	or rax, rbx[455] ;will be 0 if only page
	cmp rax, 0 ;check if only page
	jz .end ;if only page dont free

	;check if first page
	cmp rbx, page_head ;if rbx == page_head then first page
	je .first_page
	jmp .middle_page

	.first_page: 
	mov rdx, rbx[455]
	mov [page_head], rdx
	mov rax, rbx
	jmp .free_call

	.middle_page:
	;find prv page
	mov rax, [page_head] ;get first page
	.find_prv_page:
	mov rdx, rax[455] ;get next page from first page
	cmp rdx, rbx ;compare next page to current page
	je .found_page
	mov rax, rax[455] ;get next page to check
	cmp rax, rax ;make sure rax isn't 0 just in case
	jz .end ;page not found (wtf)
	jmp .find_prv_page

	.found_page:
	mov rdx, rbx[455] ;get ptr to next page from freed page
	mov rax[455], rdx ;replace ptr of freed page with ptr to next page
	mov rax, rbx ;prepare for free call
	jmp .free_call

	.free_call:
	call free_page

	.end:
	ret

section .data
page_head: dq 0
