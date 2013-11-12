.MODEL large ; one data and one code segment, stack and data segment are grouped

; External datasegments
externdef TBQuantazation:BYTE 				; Quantazation Tables
externdef TBHuffman:BYTE					; Huffman Tables
externdef TBData:BYTE						; Data 

; External methods
externdef readJPG:FAR
externdef entropyDecoding:FAR
externdef Dequantazation:FAR
externdef iDCT:FAR
externdef shiftColors:FAR
externdef showImage:FAR

.STACK 1024  ; stack, 1024 bytes

.DATA        ; data segment, global variables

.CODE        ; code segment

; ----------------------------- CODE STARTS HERE -------------------------------
main:
	mov	ax, @DATA
	mov	ds, ax

	call readJPG
	
	call entropyDecoding
	
	call Dequantazation
	
	call iDCT
	
	call shiftColors
	
	call showImage
	
	; Exit to DOS
	mov	ax, 4c00h
	int	21h

; --- END

; _------------------------------- END OF CODE ---------------------------------
END main
