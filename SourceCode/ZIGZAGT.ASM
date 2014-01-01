.MODEL large

include HELPERS.INC
include ZIGZAG.INC
include ZIGZAGT.INC

.DATA
	msgDataZigZag db 'Used Data to dezigzig: $'
	msgZigzag db 'Executing zigzagging: $'
	testData dw 384 dup(?)
.CODE

; Test code for the procedure zigzag.
; No arguments on the stack
zigzagTest PROC FAR
	push bp
	mov bp, sp

	; Create 6 byte-matrices stored after each other in the MDU
	xor cx, cx ; counter loop
@@:
	mov dx, seg testData
	push dx
	mov dx, offset testData
	mov ax, 128 ; 64 words per matrix
	push dx
	mul cx
	pop dx
	add dx, ax ; add offset according to current count index
	push dx
	call initializeWordMatrix
	inc cx
	cmp cx, 6
	jne @B

	mov ax, offset msgZigzag
	push ax
	call PrintString

	mov ax, seg testData
	push ax
	mov ax, offset testData
	push ax
	call zigzag

	mov ax, seg testData
	push ax
	mov ax, offset testData
	push ax
	mov ax, 64
	push ax
	call PrintWordSegment

	mov sp, bp
	pop bp
	ret 0
zigzagTest ENDP

END