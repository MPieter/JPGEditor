.MODEL large
include READ.INC
.DATA
; PUBLIC TBQuantizationL, TBQuantizationC, HcodeACL, HcodeACC, HcodeDCL, HcodeDCC, HufDCCd, HufACLd, HufACCd, HufDCLd, Raw

; SOFHeader db 16 DUP (?)					; Start of Frame Baseline (SOF0) marker.
; ; Contains information like Image size, Bit Precision, Data unit size...
; TBQuantizationL db 64 DUP (?)				; Quantisation Table L
; TBQuantizationC db 64 DUP (?)				; Quantisation Table C
; ; Data tables allow us to find the symbols (see comments before ExpansionHT)
; ; Length tables allow us to generate the code values, for translation bitstream -composed by codes- to symbols.
; HufDCLl db 16 DUP (?)				; Huffman Tables for DC values of the light intensity (lengths)
; HufDCLd db 12 DUP (?)				; Huffman Tables for DC values of the light intensity (data)
; HufDCCl db 16 DUP (?)				; Huffman Tables for DC values of the chrominance (lengths)
; HufDCCd db 12 DUP (?)				; Huffman Tables for DC values of the chrominance (data)
; HufACLl db 16 DUP (?)				; Huffman Tables for AC values of the light intensity (lengths)
; HufACLd db 162 DUP (?)				; Huffman Tables for AC values of the light intensity (data)
; HufACCl db 16 DUP (?)				; Huffman Tables for AC values of the chrominance (lengths)
; HufACCd db 162 DUP (?)				; Huffman Tables for AC values of the chrominance (data)
; Raw db 60000 DUP (?)				; Raw BITstream
; ; Define place for code values
; HcodeACL db 162 dup (?)
; HcodeACC db 162 dup (?)
; HcodeDCL db 162 dup (?)
; HcodeDCC db 162 dup (?)
; BESTANDSNAAM	DB "Test32~1.jpg",0		; Name of the JPGFile, followed by a 0, imposed convention for the use of read function.

nReadedBytes dw 0							; number of read bytes, thanks to that we don't have to give ax as parameter when we call a procedure
											; ; The name have to be maximum 8 chars long.	
LEESBUFFER	DB 512 DUP (?)					; Reserve 512 bytes for reading,
; 512 because the computer works per sector of 512 bytes (use of DOS-buffer to communicate with the external memory)
nReading db 0						; Will gives how much times we have to call LEZEN
msg1 db "File can't be open.$"
msg2 db "File can't be read.$"
msg3 db "The file has been read in $"
msg3end db " times.",0dh, 0ah,"Each time we read 512 bytes.$"
msg4 db 0dh, 0ah, "$"
.CODE
readJPG PROC FAR
	push bp
	mov bp, sp
	

	mov sp, bp
	pop bp
	ret 0

readJPG ENDP





END