.MODEL large ; one data and one code segment, stack and data segment are grouped

; External methods
include READ.INC
include EXPHT.INC
include ENTROPY.INC
include QUANT.INC
include QUANTT.INC
include IDCT.INC
include IDCTT.INC
include SHOW.INC
include SHOWT.INC
include HELPERS.INC
include ZIGZAG.INC
include ZIGZAGT.INC

.STACK 1024  ; stack, 1024 bytes

.DATA        ; data segment, global variables
; The data used in only one .ASM file is defined locally (not included).
; The data used in different file is defined here and can be used thanks the .INC file.

;------ DATA used among other in READ.ASM
;PUBLIC SOFHeader, TBQuantizationL, TBQuantizationC
;public HufDCCd, HufACLd, HufACCd, HufDCLd, HufDCCl, HufACLl, HufACCl, HufDCLl, Raw, BESTANDSNAAM

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
	Raw db 50000 DUP (?)				; Raw BITstream
	BESTANDSNAAM	DB "TestColo.jpg",0		; Name of the JPGFile, followed by a 0, imposed convention for the use of read function.
	; BESTANDSNAAM DB "TestW.jpg",0						; The name have to be maximum 8 chars long.	

;------ DATA used among other in EXPHT.ASM
;public HcodeACL, HcodeACC, HcodeDCL, HcodeDCC
	; Define place for code values
	HcodeACL dw 162 dup (?)
	HcodeACC dw 162 dup (?)
	HcodeDCL dw 12 dup (?)
	HcodeDCC dw 12 dup (?)
	
	
;------ DATA used among other in iDCT_Block.ASM
;public inputiDCT_Block, outputiDCT_Block
	inputiDCT dw 384 dup (?)
	msgDataCX db 'The value of CX: $'
	msg db ", $"
.CODE        ; code segment

; ----------------------------- CODE STARTS HERE -------------------------------
main:
	mov	ax, @DATA
	mov	ds, ax

	;--- Extract the data and derive the Huffman Tables (HT)
 	call readJPG
	
 	call expansionHT

	call ClearScreenBuffer
	
	;--- Translate, part by part, the raw data in image block.
 	xor cx, cx
NEWMDU:
 	call entropyDecoding 	; the 6 matrix of 64 words are updated (in inputiDCT) 
				
 	mov ax, seg inputiDCT
 	push ax
 	mov ax, offset inputiDCT
 	push ax
 	call zigzag				; the values of the 6 matrix are disposed in zigzag sequence.

	mov ax, seg inputiDCT
	push ax
	mov ax, offset inputiDCT
	push ax
	call Dequantization		; the values of the 6 matrix are multiplied by the appropriated quantization matrix

	mov ax, seg inputiDCT
	push ax
	mov ax, offset inputiDCT
	push ax
	call iDCT 				; iDCT_Block is performed on the 6 matrix

	mov ax, seg inputiDCT
	push ax		
	mov ax, offset inputiDCT
	push ax
	push cx		; number of MDU (to give the emplacement of the MDU in the image)
	call showImage
	
	inc cx
	mov ax, offset msgDataCX
	push ax
	call PrintString
	push cx
	call PrintNumber
	cmp cx, 240	 ; Our image is 320x200 pixels
				; If one MDU is 16x16 pixels it means that we will need 20x13=260 MDU to recomposed our picture.
	jne NEWMDU
		
	; TODO: last 20 MDU fall of the screen

 	call RenderScreen

	call WaitForEnter

	call RestoreScreen
	
	; Exit to DOS
EndProgram:
	mov	ax, 4c00h
	int	21h

; --- END

; _------------------------------- END OF CODE ---------------------------------
END main
