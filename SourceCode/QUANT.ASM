.MODEL large

include MAIN.INC
include QUANT.INC

; Constants
totalBlock equ 64000; Total values of one channel
lengthBlock equ 64; Each block contains 64 values

.CODE

; Calculates the dequantization of an MDU.
; The dequantization is applied to each block in the MDU
; Argument on the stack:
; Argument 1 = segment address of MDU (MDU contians words)
; Argument 2 = offset address of MDU
Dequantization PROC FAR
	push bp
	mov bp, sp

	push ax
	push bx
	push cx
	push dx

	; First four Y-block
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
	mov ax, seg TBQuantizationL ; Tables defined in MAIN.INC
	push ax
	mov ax, offset TBQuantizationL
	push ax
	call DequantBlock
	inc cx
	cmp cx, 4
	jne @B

	; Cb-block
	mov ax, [bp + 6][2]
	push ax
	mov ax, [bp + 6][0]
	add ax, 512 ; We need the 5-th matrix in the MDU (512 = 4 * 64 * 2)
	push ax
	mov ax, seg TBQuantizationC
	push ax
	mov ax, offset TBQuantizationC
	push ax
	call DequantBlock

	; Cr-block
	mov ax, [bp + 6][2]
	push ax
	mov ax, [bp + 6][0]
	add ax, 640 ; We need the 6-th matrix in the MDU (650 = 5 * 64 * 2)
	push ax
	mov ax, seg TBQuantizationC
	push ax
	mov ax, offset TBQuantizationC
	push ax
	call DequantBlock

	pop dx
	pop cx
	pop bx
	pop ax

	mov sp, bp
	pop bp
	ret 4
Dequantization ENDP

; Calculates the dequantization of an 8x8 matrix.
; Arguments on the stack:
; Argument 1 = segment address of data (data segment in words)
; Argument 2 = offset address of data
; Argument 3 = segment address of quantization table (quant. table in bytes)
; Argument 4 = offset address of quantization table
; The block is modified in its data segment (meaning: source and destination of 
; operation are the same).
DequantBlock PROC FAR
	push bp
	mov bp, sp

	push ax
	push bx
	push cx
	push dx
	
	; Push all values of the quantization table on the stack
	mov ds, [bp + 6][2]
	mov si, [bp + 6][0]
	add si, 63 ; increment with 63 bytes (the size of the quantization table): we start at the back
	std ; set direction flag downwards -> lodsb decrements the si register
	mov cx, 64 ; counter
	mov ah, 0 ; lodsb puts value in al
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
	lodsw
	; multiply
	pop bx ; get the element from the quantization matrix
	mul bx ; result of calculation: DX:AX = AX*Op
	stosw
	loop @B

	pop dx
	pop cx
	pop bx
	pop ax

	mov sp, bp
	pop bp
	ret 8
DequantBlock ENDP

END