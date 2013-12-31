.MODEL large

include HELPERS.INC

.DATA
	msgSpace db ' $'
	msgData db 'The data:$'
		
	newline db 0dh, 0ah, '$'

.CODE

; Print a string
; Arguments on the stack:
; Argument 1 = offset of string
PrintString PROC FAR
	push bp
	mov bp, sp
	
	push ax
	push dx
	
	mov	ah, 09h		; select function 09h
	mov	dx, [bp + 6][0]	; load offset address of msg (in data segment)
	int	21h		; call DOS, function 09h, print to stdout

    ; Print new line
	mov ah, 09h
	mov dx, offset newline
	int 21h
	
	pop dx
	pop ax

	mov sp, bp
	pop bp
	ret 2
PrintString ENDP

PrintSpace PROC FAR
	push bp
	mov bp, sp
	
	push ax
	push dx
	
	mov	ah, 09h		; select function 09h
	mov	dx, offset msgSpace
	int	21h		; call DOS, function 09h, print to stdout
	
	pop dx
	pop ax
	
	mov sp, bp
	pop bp
	ret 0
PrintSpace ENDP

PrintNewLine PROC FAR
	push bp
	mov bp, sp
	
	push ax
	push dx
	
	; Print new line
	mov ah, 09h
	mov dx, offset newline
	int 21h
	
	pop dx
	pop ax
	
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

; Prints the value of the data (data are in words)
; Argument 1 = segment address of data
; Argument 2 = offset address of current data block in data
; Argument 3 = data length
; Note: inserts automatically a new line after 8 values
PrintWordSegment PROC FAR
	push bp
	mov bp, sp
	
	; Print result
	mov ax, [bp + 6][4]
	mov ds, ax
	mov si, [bp + 6][2]
	cld ; clear direction flag
	mov cx, [bp + 6][0]
	mov bx, 8
@@:
	lodsw
	push ax
	call PrintNumber
	call PrintSpace
	dec bx
	cmp bx, 0
	jne ContinueLoop
	call PrintNewLine
	mov bx, 8
ContinueLoop:
	loop @B
	
	mov sp, bp
	pop bp
	ret 6
PrintWordSegment ENDP

; Prints the value of the data (data are in bytes)
; Argument 1 = segment address of data
; Argument 2 = offset address of current data block in data
; Argument 3 = data length
; Argument 4 = insert a line break after 'x (= arg 4)' values
PrintByteSegment PROC FAR
	push bp
	mov bp, sp
	
	; Print result
	mov ax, [bp + 6][6]
	mov ds, ax
	mov si, [bp + 6][4]
	cld ; clear direction flag
	mov cx, [bp + 6][2]
	mov bx, [bp + 6][0]
	mov ah, 0
@@:
	lodsb
	push ax
	call PrintNumber
	call PrintSpace
	dec bx
	cmp bx, 0
	jne ContinueLoop
	call PrintNewLine
	mov bx, [bp + 6][0]
ContinueLoop:
	loop @B
	
	mov sp, bp
	pop bp
	ret 8
PrintByteSegment ENDP

; Blocks the program until the user presses Enter.
; No arguments on the stack
WaitForEnter PROC FAR
	push bp
	mov bp, sp

@@:
	mov ah, 00h
	int 16h ; keyboard interrupt -> ascii character in al
	
	cmp al, 0dh ; ascii code for 'carriage return' = 0dh
	jne @B
	
	
	mov sp, bp
	pop bp
	ret 0
WaitForEnter ENDP

; Initializes an array of length 8 with data (word-data)
; Arguments on the stack:
; Argument 1 = segment address of array
; Argument 2 = offset address of array
initializeWordArray PROC FAR
	push bp
	mov bp, sp
	
	mov ax, [bp + 6][2]
	mov es, ax
	mov di, [bp + 6][0]
	
	mov ax, -415
	stosw
	mov ax, -26
	stosw
	mov ax, -58
	stosw
	mov ax, 33
	stosw
	mov ax, 56
	stosw
	mov ax, -24
	stosw
	mov ax, -2
	stosw
	mov ax, 0
	stosw
	
	mov sp, bp
	pop bp
	ret 4
initializeWordArray ENDP

; Initializes an array with dummy data (byte-data)
; Arguments on the stack:
; Argument 1 = segment address of array
; Argument 2 = offset address of array
; Argument 3 = length of data
initializeByteArray PROC FAR
	push bp
	mov bp, sp
	
	mov ax, [bp + 6][4]
	mov es, ax
	mov di, [bp + 6][2]
	
	mov cx, [bp + 6][0]
@@:
	mov ax, 10
	stosb
	loop @B
	
	mov sp, bp
	pop bp
	ret 4
initializeByteArray ENDP

; Initializes byte-data in the data segment passed on the stack with dummy data (fixed, not random!) 
; Arguments on the stack:
; Argument 1 = segment address of data
; Argument 2 = offset address of data
initializeByteMatrix PROC FAR
	push bp
	mov bp, sp
	
	mov es, [bp + 6][2]
	mov di, [bp + 6][0]

	mov cx, 4
Forloop:
	push cx
	mov cx, 8
	FirstPart:
		mov ax, 2
		stosb
		loop FirstPart

	mov cx, 8
	SecondPart:
		mov ax, 3
		stosb
		loop SecondPart

	pop cx
	loop Forloop
	
	mov sp, bp
	pop bp
	ret 4
initializeByteMatrix ENDP

; Initializes word-data in the data segment passed on the stack with 
; dummy data (fixed, not random!). Data contains 64 elements. 
; Arguments on the stack:
; Argument 1 = segment address of data
; Argument 2 = offset address of data
initializeWordMatrix PROC FAR
	push bp
	mov bp, sp

	push ax
	push bx
	push cx

	; Algorithm used for initlializing the data:
	;	for (int i = 0; i < 8; i++) {
	;		for (int j = 0; j < 8; j++) {
	;			input.push_back(2*(i + 1));
	;	}
	;}
	
	mov es, [bp + 6][2]
	mov di, [bp + 6][0]

	mov cx, 0
OuterLoop:
	push cx

	mov cx, 8
	InnerLoop:
		mov ax, [bp - 8]
		add ax, 1
		mov bx, 2
		mul bx
		stosw

		loop InnerLoop

	pop cx
	inc cx
	cmp cx, 8
	jne OuterLoop
	
	pop cx
	pop bx
	pop ax

	mov sp, bp
	pop bp
	ret 4
initializeWordMatrix ENDP

; Initializes word-data in the data segment passed on the stack with dummy data (fixed, not random!) 
; Arguments on the stack:
; Argument 1 = segment address of data
; Argument 2 = offset address of data
intializeWordMatrixDCT PROC FAR
	push bp
	mov bp, sp
	
	mov es, [bp + 6][2]
	mov di, [bp + 6][0]
	
	; Row
	mov ax, -415
	stosw
	mov ax, -26
	stosw
	mov ax, -58
	stosw
	mov ax, 33
	stosw
	mov ax, 56
	stosw
	mov ax, -24
	stosw
	mov ax, -2
	stosw
	mov ax, 0
	stosw
	; Row
	mov ax, 4
	stosw
	mov ax, -16
	stosw
	mov ax, -50
	stosw
	mov ax, 11
	stosw
	mov ax, 11
	stosw
	mov ax, -7
	stosw
	mov ax, -6
	stosw
	mov ax, 4
	stosw
	; Row
	mov ax, -45
	stosw
	mov ax, 6
	stosw
	mov ax, 70
	stosw
	mov ax, -28
	stosw
	mov ax, -28
	stosw
	mov ax, 11
	stosw
	mov ax, 4
	stosw
	mov ax, -5
	stosw
	; Row
	mov ax, -59
	stosw
	mov ax, 13
	stosw
	mov ax, 39
	stosw
	mov ax, -21
	stosw
	mov ax, -12
	stosw
	mov ax, 9
	stosw
	mov ax, 2
	stosw
	mov ax, 2
	stosw
	; Row
	mov ax, 12
	stosw
	mov ax, -6
	stosw
	mov ax, -13
	stosw
	mov ax, -5
	stosw
	mov ax, -2
	stosw
	mov ax, 2
	stosw
	mov ax, -3
	stosw
	mov ax, 3
	stosw
	; Row
	mov ax, -10
	stosw
	mov ax, 3
	stosw
	mov ax, 3
	stosw
	mov ax, -9
	stosw
	mov ax, -3
	stosw
	mov ax, 1
	stosw
	mov ax, 5
	stosw
	mov ax, 2
	stosw
	; Row
	mov ax, 0
	stosw
	mov ax, 0
	stosw
	mov ax, 0
	stosw
	mov ax, -2
	stosw
	mov ax, -1
	stosw
	mov ax, -4
	stosw
	mov ax, 4
	stosw
	mov ax, -1
	stosw
	; Row
	mov ax, -1
	stosw
	mov ax, 0
	stosw
	mov ax, -1
	stosw
	mov ax, -5
	stosw
	mov ax, -1
	stosw
	mov ax, 0
	stosw
	mov ax, 0
	stosw
	mov ax, 1
	stosw
	
	mov sp, bp
	pop bp
	ret 4
intializeWordMatrixDCT ENDP

; Initializes word-data with large numbers in the data segment passed on the stack with 
; dummy data (fixed, not random!) 
; Arguments on the stack:
; Argument 1 = segment address of data
; Argument 2 = offset address of data
initializeWordMatrixLarge PROC FAR
	push bp
	mov bp, sp
	
	mov es, [bp + 6][2]
	mov di, [bp + 6][0]
	
	mov ax, -2000
	mov cx, 8 ; number of rows
@@:
	push cx
	mov cx, 8
	rep stosw
	pop cx
	add ax, 500
	loop @B
	
	mov sp, bp
	pop bp
	ret 4
initializeWordMatrixLarge ENDP

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