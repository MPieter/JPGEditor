.MODEL large

.CODE

; print a signed integer to stdout
; value on stack
printints PROC FAR
	; argument/local variables addresses
	argBytes EQU 2
	arg1 EQU [bp + 6][0]
	; code
	push	bp	; save dynamic link
	mov	bp, sp	; update bp
	; save context on stack
	push	ax
	push	bx
	push	dx
	; load param in bx
	mov	bx, arg1	; near proc, one word return address
	; handle special case of zero and test for sign
	cmp	bx, 0
	jge	@F
	; if negative, print sign and invert
	; print sign (int 21h, function 02h)
	mov	ah, 2
	mov	dl, '-'
	int	21h
	; invert sign of bx
	neg	bx
@@:
	push	bx
	call	printint	
	; restore context (reverse pop the registers)
	pop	dx
	pop	bx
	pop	ax
	; restore sp and bp
	mov	sp, bp
	pop	bp
	; return freeing param from stack (2 bytes)
	ret	argBytes
printints ENDP

END