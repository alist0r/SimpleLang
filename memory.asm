;in order for this program to work
;i need to write a memory allocator
;to manage the space tokens are useing
;this allocater will check to see if theres
;enough room on the current page
;if there is not enough a new page will be
;requested 
;if there is enough or on the new page
;then the next token will be placed in the
;first free area thats large enough to fit it
;allocated space will be kept track with a
;bitmap of the page which will be the first
;item on the page
