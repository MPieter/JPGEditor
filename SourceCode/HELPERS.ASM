.MODEL large

include HELPERS.INC

.DATA
	msgSpace db ' $'
	newline db 0dh, 0ah, '$'

.CODE

; Print a string
; Arguments on the stack:
; Argument 1 = offset of string
PrintString PROC FAR
	push bp
	mov bp, sp
	
	mov	ah, 09h		; select function 09h
	mov	dx, [bp + 6][0]	; load offset address of msg (in data segment)
	int	21h		; call DOS, function 09h, print to stdout

    ; Print new line
	mov ah, 09h
	mov dx, offset newline
	int 21h

	mov sp, bp
	pop bp
	ret 0
PrintString ENDP

PrintSpace PROC FAR
	push bp
	mov bp, sp
	
	mov	ah, 09h		; select function 09h
	mov	dx, offset msgSpace
	int	21h		; call DOS, function 09h, print to stdout
	
	mov sp, bp
	pop bp
	ret 0
PrintSpace ENDP

PrintNewLine PROC FAR
	push bp
	mov bp, sp
	
	; Print new line
	mov ah, 09h
	mov dx, offset newline
	int 21h
	
	mov sp, bp
	pop bp
	ret 0
PrintNewLine ENDP

; print a signed integer to stdout
; value on stack
PrintNumber PROC FAR
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
PrintNumber ENDP

; print an unsigned integer to stdout
; value on stack
printint PROC NEAR
	; argument/local variables addresses
	argBytes EQU 2
	arg1 EQU [bp + 4][0]
	; code
	push	bp	; save dynamic link
	mov	bp, sp	; update bp
	; save context on stack
	push	ax
	push	bx
	push	cx
	push	dx
	push	si	
	; load param in bx
	mov	bx, arg1	; near proc, one word return address
	; handle special case of zero
	test	bx, 0FFFFh
	jnz	@F	; jmp forward to next @@ label
	mov	ah, 02h
	mov	dl, '0'
	int	21h		; print the '0' character
	jmp	@printint_done
@@:
	; prepare powers-of-ten on stack
	mov	ax, 1
	push	ax
	mov	ax, 10
	push	ax
	mov	ax, 100
	push	ax
	mov	ax, 1000
	push	ax
	mov	ax, 10000
	push	ax
	; from now on bx is strictly positive
	; determine largest power of ten smaller than bx
	; init si to point to first element of powersoften array
	; while bx < cx, pop cx 
@@:
	pop	cx
	cmp	bx, cx
	jb	@B	; jmp back to @@ label
@@:
	; ok now print digits
	mov	ax, bx
	cwd		; sign extend to DX:AX (32-bit)
	idiv	cx	; divide DX:AX by current power of ten
				; result in AX, remainder in DX
	mov	bx, dx	; move remainder to bx
	mov	ah, 02h	; print one character
	mov	dl, al	; al contains the digit, move into dl
	add	dl, 48	; add 48 to convert it to ASCII digit
	int	21h	; call DOS function
	; was this the last digit? i.e. [si] equals 1
	cmp	cx, 1
	je	@printint_done
	pop	cx	; next power of ten
	jmp	@B ; repeat for next digit
@printint_done:
	; restore context (reverse pop the registers)
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	; restore sp and bp
	mov	sp, bp
	pop	bp
	; return freeing param from stack (2 bytes)
	ret	argBytes
printint ENDP

END