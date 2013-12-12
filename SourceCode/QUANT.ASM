.MODEL large
include QUANT.INC

; Constants
totalBlock equ 64000; Total values of one channel
lengthBlock equ 64; Each block contains 64 values

.CODE

; Calculates the dequantization of an 8x8 matrix.
; Arguments on the stack:
; Argument 1 = segment address of data
; Argument 2 = offset address of data
; Argument 3 = segment address of quantization table
; Argument 4 = offset address of quantization table
; The block is modified in its data segment (meaning: source and destination of 
; operation are the same).
Dequantization PROC FAR
	push bp
	mov bp, sp
	
	; Push all values of the quantization table on the stack
	mov ds, [bp + 6][2]
	mov si, [bp + 6][0]
	add si, 64 ; increment with 64 bytes (the size of the quantization table)
	std ; set direction flag downwards -> lodsb decrements the si register
	mov cx, 64 ; counter
@@:
	lodsb
	push ax
	loop @B
	
	cld ; set direction flag upwards
	; set ds, es, si and di: output comes directly in the same data segment
	mov ds, [bp + 6][6]
	mov es, [bp + 6][6]
	mov si, [bp + 6][4]
	mov di, [bp + 6][4]
	mov cx, 64 ; counter
	
@@:
	lodsb
	; multiply
	pop bx ; get the element from the quantization matrix
	mul bx ; result of calculation: DX:AX = AX*Op
	stosb
	loop @B

	mov sp, bp
	pop bp
	ret 8
Dequantization ENDP

END