; QUANTT.ASM
; ---------------
; Contains Test Code for all the procedures in QUANT.ASM
.MODEL large

include HELPERS.INC
include QUANT.INC

.DATA
	matrixBefore dw 64 dup(0)
	matrixAfter dw 64 dup(0)
	
	msgData db 'The data:$'
	msgDequantization db 'Executing Dequantization:$'

.CODE


DequantizationTest PROC FAR
	push bp
	mov bp, sp
	
	mov ax, seg matrixBefore
	push ax
	mov ax, offset matrixBefore
	push ax
	call initializeMatrix
	
	mov ax, offset msgData
	push ax
	call PrintString
	
	mov ax, seg matrixBefore
	push ax
	mov ax, offset matrixBefore
	push ax
	mov ax, 64
	push ax
	call PrintDataSegment
	
	mov ax, offset msgDequantization
	push ax
	call PrintString
	
	mov ax, seg matrixBefore
	push ax
	mov ax, offset matrixBefore
	push ax
	mov ax, seg matrixAfter
	push ax
	mov ax, offset matrixAfter
	push ax
	call Dequantization
	
	mov ax, seg matrixAfter
	push ax
	mov ax, offset matrixAfter
	push ax
	mov ax, 64
	push ax
	call PrintDataSegment
	
	mov sp, bp
	pop bp
	ret 0
DequantizationTest ENDP

END