.MODEL large


; Constants
totalBlock equ 64000; Total values of one channel
lengthBlock equ 64; Each block contains 64 values

.CODE

; Executes the dequantization of one channel
; Arguments on the stack:
; Argument 1 = segment address of data
; Argument 2 = offset address of data
; Argument 3 = segment address of quantization table
; Argument 4 = offset address of quantization table
Dequantization PROC FAR
	push bp
	mov bp, sp
	
	mov bx, 0 ; Keeps track of current block
	mov dx, [bp + 6][4]
LoopBlocks:
	mov dx, [bp + 6][6]
	push dx
	add dx, bx
	push dx
	mov dx, [bp + 6][2]
	push dx
	mov dx, [bp + 6][0]
	push dx
	call DequantBlock
	
	add bx, lengthBlock
	cmp cx, totalBlock
	jne LoopBlocks
	
LoopEnd:
	mov sp, bp
	pop bp
	ret 8
Dequantization ENDP

; Excecutes the dequantazation of one block.
; Arguments on the stack: 
; Argument 1 = segment address of data
; Argument 2 = offset address of current data block in data
; Argument 3 = segment address of quantization table
; Argument 4 = offset address of quantization table
; The block is modified in its data segment (meaning: source and destination of 
; operation are the same).
DequantBlock PROC NEAR
	push bp
	mov bp, sp
	
	mov cx, 0
LoopStart:
	; Get Quantazation element
	; TODO ds en es door elkaar gebruiken. Hierdoor moeten we minder van segment veranderen
	; En si en di gebruiken. Dan kijken naar de instructie welke default die juist pakt.
	; Bijvoorbeeld met lodsb en movsb
	mov ax, [bp + 4][2]
	mov es, ax
	mov di, [bp + 4][0]
	add di, cx
	mov dx, es:[di]
	
	; Get Value of block
	mov ax, [bp + 4][6]
	mov es, ax
	mov di, [bp + 4][4]
	add di, cx
	mov ax, es:[di]
	
	; Multiply value of DCT with Quantazition value, result in DX:AX
	imul dx
	mov es:[di], ax
	inc cx
	cmp cx, lengthBlock
	jne LoopStart

LoopEnd:
	mov sp, bp
	pop bp
	ret 2
DequantBlock ENDP

END