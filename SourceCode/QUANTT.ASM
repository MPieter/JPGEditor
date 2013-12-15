; QUANTT.ASM
; ---------------
; Contains Test Code for all the procedures in QUANT.ASM
.MODEL large

include HELPERS.INC
include QUANT.INC

.DATA
	matrixData dw 64 dup(0)
	matrixQuant db 64 dup(0)
	
	msgData db 'The data:$'
	msgDataQuant db 'The Quantization Table:$'
	msgDequantization db 'Executing Dequantization:$'

.CODE


DequantizationTest PROC FAR
	push bp
	mov bp, sp
	
	; The data
	mov ax, seg matrixData
	push ax
	mov ax, offset matrixData
	push ax
	call initializeWordMatrix
	
	mov ax, offset msgData
	push ax
	call PrintString
	
	mov ax, seg matrixData
	push ax
	mov ax, offset matrixData
	push ax
	mov ax, 64
	push ax
	call PrintWordSegment
	
	; The dequantization table
	mov ax, seg matrixQuant
	push ax
	mov ax, offset matrixQuant
	push ax
	call initializeByteMatrix
	
	mov ax, offset msgDataQuant
	push ax
	call PrintString
	
	mov ax, seg matrixQuant
	push ax
	mov ax, offset matrixQuant
	push ax
	mov ax, 64
	push ax
	call PrintByteSegment
	
	; The dequantization process
	mov ax, offset msgDequantization
	push ax
	call PrintString
	
	mov ax, seg matrixData
	push ax
	mov ax, offset matrixData
	push ax
	mov ax, seg matrixQuant
	push ax
	mov ax, offset matrixQuant
	push ax
	call Dequantization
	
	mov ax, seg matrixData
	push ax
	mov ax, offset matrixData
	push ax
	mov ax, 64
	push ax
	call PrintWordSegment
	
	mov sp, bp
	pop bp
	ret 0
DequantizationTest ENDP

END