; QUANTT.ASM
; ---------------
; Contains Test Code for all the procedures in QUANT.ASM
.MODEL large

include HELPERS.INC
include QUANT.INC

.DATA
	matrixData dw 64 dup(0)
	matrixQuant db 64 dup(0)
	
	msgDataQuant db 'The Quantization Table:$'
	msgDequantization db 'Executing DequantBlock:$'

.CODE

; Test code for the procedure DequantBlock
; No arguments on the stack
DequantizationTest PROC FAR
	push bp
	mov bp, sp
	
	; The data
	mov ax, seg matrixData
	push ax
	mov ax, offset matrixData
	push ax
	call intializeWordMatrixDCT
	
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
	call DequantBlock
	
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