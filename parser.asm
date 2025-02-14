global parser
global init_symbol_map

extern token_head
extern alloc
extern free

section .text
;clobers
;inputs:
;	none
;outputs:
;	none
init_symbol_map:

hash:

lookup:

put:

;clobers
;inputs:
;	none
;outputs
;	none
parser:
	ret

section .data
symbol_map: dq 0
