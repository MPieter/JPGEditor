.MODEL large ; one data and one code segment, stack and data segment are grouped

; External methods
; include READ.INC
; include EXPANSHT.INC
include ENTROPY.INC
include QUANT.INC
include IDCT.INC
include IDCTTEST.INC
include SHIFT.INC
include SHOW.INC
include HELPERS.INC

.STACK 1024  ; stack, 1024 bytes

.DATA        ; data segment, global variables
; The data used in only one .ASM file is defined in there.
; The data used in different file is defined here and can be used thanks the .INC file.

;	dataY dw 1000 dup (?)

;------ DATA used among other in READ.ASM
PUBLIC SOFHeader, TBQuantizationL, TBQuantizationC
; public HcodeACL, HcodeACC, HcodeDCL, HcodeDCC, 
public HufDCCd, HufACLd, HufACCd, HufDCLd, HufDCCl, HufACLl, HufACCl, HufDCLl, Raw, BESTANDSNAAM

	SOFHeader db 16 DUP (?)						; Start of Frame Baseline (SOF0) marker.
	; Contains information like Image size, Bit Precision, Data unit size...
	TBQuantizationL db 64 DUP (?)				; Quantisation Table L
	TBQuantizationC db 64 DUP (?)				; Quantisation Table C
	; Data tables allow us to find the symbols (see comments before ExpansionHT)
	; Length tables allow us to generate the code values, for translation bitstream -composed by codes- to symbols.
	HufDCLl db 16 DUP (?)				; Huffman Tables for DC values of the light intensity (lengths)
	HufDCLd db 12 DUP (?)				; Huffman Tables for DC values of the light intensity (data)
	HufDCCl db 16 DUP (?)				; Huffman Tables for DC values of the chrominance (lengths)
	HufDCCd db 12 DUP (?)				; Huffman Tables for DC values of the chrominance (data)
	HufACLl db 16 DUP (?)				; Huffman Tables for AC values of the light intensity (lengths)
	HufACLd db 162 DUP (?)				; Huffman Tables for AC values of the light intensity (data)
	HufACCl db 16 DUP (?)				; Huffman Tables for AC values of the chrominance (lengths)
	HufACCd db 162 DUP (?)			; Huffman Tables for AC values of the chrominance (data)
	Raw db 60000 DUP (?)				; Raw BITstream
	; Define place for code values
	;HcodeACL dw 162 dup (?)
	; HcodeACC dw 162 dup (?)
	;HcodeDCL dw 162 dup (?)
	; HcodeDCC dw 162 dup (?)
	BESTANDSNAAM	DB "Test32~1.jpg",0		; Name of the JPGFile, followed by a 0, imposed convention for the use of read function.
											; The name have to be maximum 8 chars long.	
;------ DATA used among other in IDCT.ASM
; public inputIDCT, outputIDCT
	; inputIDCT DW 64 dup (?)
	; outputIDCT db 64 dup (?)
		
.FARDATA?	; segment that contains the screenBuffer for mode 13h drawing
	palette			db 768 dup(0)
	screenBuffer	db 64000 dup(?)	; the 64000 bytes for the screen

.CODE        ; code segment

; ----------------------------- CODE STARTS HERE -------------------------------
main:
	mov	ax, @DATA
	mov	ds, ax

	call IDCTTEST
	
	; call readJPG
	
	; call expansionHT
	
	;call entropyDecoding
	
	; call Dequantization

	; call Dequantization
	
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
