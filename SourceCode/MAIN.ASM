.MODEL large ; one data and one code segment, stack and data segment are grouped

; External datasegments
include DATA.INC

; External methods
include READ.INC
include ENTROPY.INC
include QUANT.INC
include IDCT.INC
include SHIFT.INC
include SHOW.INC

.STACK 1024  ; stack, 1024 bytes

.DATA        ; data segment, global variables
	dataY dw 1000 dup (?)

.FARDATA
	dataCb dw 1000 dup (?)
	
.FARDATA
	dataCr dw 1000 dup (?)
	
.CODE        ; code segment

; ----------------------------- CODE STARTS HERE -------------------------------
main:
	mov	ax, @DATA
	mov	ds, ax

	call readJPG

	; mov ax, seg dataY
	; mov ax, seg dataCb
	; mov ax, seg dataCr
	
	;call expansionHT
	
	;call entropyDecoding
	
	; mov ax, seg TBDataY
	; push ax
	; mov ax, offset TBDataY
	; push ax
	; mov ax, seg TBQuantization
	; push ax
	; mov ax, offset TBQuantization
	; push ax
	; call Dequantization
	
	; mov ax, seg TBDataCb
	; push ax
	; mov ax, offset TBDataCb
	; push ax
	; mov ax, seg TBQuantization
	; push ax
	; mov ax, offset TBQuantization
	; push ax
	; call Dequantization
	
	; mov ax, seg TBDataCr
	; push ax
	; mov ax, offset TBData Cr
	; push ax
	; mov ax, seg TBQuantization
	; push ax
	; mov ax, offset TBQuantization
	; push ax
	; call Dequantization
	
	; mov ax, seg TBDataY
	; push ax
	; mov ax, offset TBDataY
	; push ax
	; call iDCT
	
	; mov ax, seg TBDataCb
	; push ax
	; mov ax, offset TBDataCb
	; push ax
	; call iDCT
	
	; mov ax, seg TBDataCr
	; push ax
	; mov ax, offset TBData Cr
	; push ax
	; call iDCT
	
	; call shiftColors
	
	; call showImage
	
	; Exit to DOS
	mov	ax, 4c00h
	int	21h

; --- END

; _------------------------------- END OF CODE ---------------------------------
END main
