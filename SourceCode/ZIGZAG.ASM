.MODEL large

include HELPERS.INC
include ZIGZAG.INC

.DATA
	tempMatrix dw 64 dup(?)
	zigzagU db 	0, 1, 0, 0, 1, 2, 3, 2, 1, 0, 0, 1, 2, 3, 4, 5
			db	4, 3, 2, 1, 0, 0, 1, 2, 3, 4, 5, 6, 7, 6, 5, 4
			db	3, 2, 1, 0, 1, 2, 3, 4, 5, 6, 7, 7, 6, 5, 4, 3
			db	2, 3, 4, 5, 6, 7, 7, 6, 5, 4, 5, 6, 7, 7, 6, 7
	zigzagV db 	0, 0, 1, 2, 1, 0, 0, 1, 2, 3, 4, 3, 2, 1, 0, 0
			db	1, 2, 3, 4, 5, 6, 5, 4, 3, 2, 1, 0, 0, 1, 2, 3
			db 	4, 5, 6, 7, 7, 6, 5, 4, 3, 2, 1, 2, 3, 4, 5, 6
			db	7, 7, 6, 5, 4, 3, 4, 5, 6, 7, 7, 6, 5, 6, 7, 7
.CODE

; Applies the zigzagging algorithm to an MDU.
; The zigzagging algorithm is applied to each block in the MDU.
; Argument on the stack:
; Argument 1 = segment address of MDU (MDU contians words)
; Argument 2 = offset address of MDU
zigzag PROC FAR
	push bp
	mov bp, sp

	push ax
	push cx
	push dx

	xor cx, cx ; counter loop
@@:
	mov dx, [bp + 6][2]
	push dx
	mov dx, [bp + 6][0]
	mov ax, 128 ; 64 words per matrix
	push dx 	; save dx for multiplication operation
	mul cx
	pop dx
	add dx, ax ; add offset according to current count index
	push dx
	call zigzagBlock
	inc cx
	cmp cx, 6
	jne @B

	pop dx
	pop cx
	pop ax

	mov sp, bp
	pop bp
	ret 4
zigzag ENDP

; Applies the zigzagging algorithm to one block in an MDU.
; The output is placed at the location of the input.
; Argument on the stack:
; Argument 1 = segment address of block in MDU (MDU contians words)
; Argument 2 = offset address of block in MDU
zigzagBlock PROC FAR
	push bp
	mov bp, sp

	push ax
	push bx
	push cx
	push dx

	mov ax, [bp + 6][2]
	mov es, ax
	mov ds, ax

	; Index bijhouden
	mov cx, 0
ForLoop:
	; Positie in matrix ophalen
	xor ah, ah
	mov si, offset zigzagU ; columnIndex
	add si, cx ; Offset in zigzagU-matrix is in bytes
	lodsb
	push ax ; save variable on the stack
	mov si, offset zigzagV ; rowIndex
	add si, cx ; Offset in zigzagV-matrix is in bytes
	lodsb

	; Element stockeren in tempMatrix : Index bepalen
	; Index = rowIndex * sizeWidth + columnIndex
	mov bx, 8
	mul bx ; AX = AL * 8 = rowIndex * 8
	pop bx ; columnIndex in bx
	add ax, bx ; Result of calculation : ax = rowIndex * 8 + columnIndex
	push ax ; save index on the stack

	mov si, [bp + 6][0]
	mov ax, cx
	mov bx, 2
	mul bx ; AX = 2*CX (offset in input data in in words)
	add si, ax
	mov di, offset tempMatrix
	pop ax
	mov bx, 2
	mul bx ; ax = 2*index (offset in tempMatrix is in words)
	add di, ax
	movsw

	; Herhalen
	inc cx
	cmp cx, 64
	jne ForLoop

	; Copy tempMatrix to data in MDU
	mov si, offset tempMatrix
	mov di, [bp + 6][0]
	mov cx, 64
	rep movsw

	pop dx
	pop cx
	pop bx
	pop ax

	mov sp, bp
	pop bp
	ret 4
zigzagBlock ENDP



END