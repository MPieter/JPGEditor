.MODEL large
include ENTROPY.INC

.DATA
; Raw db 60000 DUP (?)				; Raw BITstream
; ; Define place for code values
; HcodeACL db 162 dup (?)
; HcodeACC db 162 dup (?)
; HcodeDCL db 162 dup (?)
; HcodeDCC db 162 dup (?)

.FARDATA?
; We should later try to overwrite Raw...

.CODE
entropyDecoding PROC FAR
	push bp
	mov bp, sp
	
NEXTMDU: ; One MDU is in our case (Color Space defined by YUV= 4:2:0):
			; A 16x16 pixels-block
			; Composed by 4 8x8 bytes Y-block, 1 8x8 bytes Cb-block and 1 8x8 bytes Cr-block
	;--- Let's handle the first 4 Y-blocks		
	xor si, si

	mov al, raw[si]
	inc si
	mov ah, raw[si]
	push ax			; push the word we have to compare with our code table
	call findCode ; will transform a piece of bitstream Raw to a matrix of 64 words
	
	push ; gives the tabel to use for the dequantization
	call Dequantization ; this matrix will be dequantized
	
	call iDCT	; Then we applied the iDCT on the output of Dequantization
	
	
	mov sp, bp
	pop bp
	ret 0
entropyDecoding ENDP

findCode PROC NEAR
	push bp
	mov bp, sp
	push	cx
	push	dx
	push	si
	push	di
	push	ds
	push	es
	
	mov si, bp[4]
	mov dl, bp[6]
	push dl
	push si
	call MakeCalibratedByte
	
	xor cl, cl	; cl will be used for counting the number of time we write a word in the output matrix (have to increase to 64)
	xor bh, bh	; bh will run over the number of codes there is for each possible length (ex: if there is no code of length 1 bit--> HufXXXl[ch]=0 with ch=0)
	xor	bl, bl	; bl gives the number of codes in Hcode we have to jump over because they don't have the good length.
	
	jmp DecodeAword
	DecodeAwordAgain:
	; [bl][ch] gives the index of the symbol in HufXXXd
	;---- Write zeros-length times 0's
	mov al, HufXXXd[bl][ch]
	sar al, 4	; the zeros-length is given by the 4 most significant bits of the symbol
	fillMatrix:
		cmp al, 0
		je WriteWord
		mov inputIDCT[cl], 0
		dec al
		inc cl
		jmp fillMatrix
	;---- Write the non-zero value
	WriteWord:
	mov al, HufXXXd[bl][ch]
	sal al, 4	; the length of the non-zero value is given by the 4 least significant bits of the symbol
	mov dh ,al	; put al in security
	add dl, bh	; addition of the two index, gives the total shift we have to do to find the non-zero value

	push dl
	push si
	call MakeCalibratedByte
	
	mov ch, 16
	sub ch, dh	; ch= 16 - length of the non-zero value
	sar ax, ch
	; We will shift again, dh times. Like that the part DecodeAword will perfect works.
	push dh
	push si
	call MakeCalibratedByte	
	
	
	DecodeAword:
		cmp cl, 64
		je DONE
		jmp nextLength
		nextLengthAgain:
		add bl, Hufl[bh]
		inc bh
		nextLength:
			mov ax, bp[4]
			mov ch, 15
			sub ch, bh
			sar ax, ch	; shift ax so that only the bh first bit are compared with the codes table.
			mov ch, Hufl[bh]
			cmp ch, 0
			je	nextLengthAgain
				nextCode:
					cmp ax, Hcode[bl][ch]
					je DecodeAwordAgain
					dec ch
					cmp ch, 0
					je nextLengthAgain
					jmp nextCode
				
		
	
	DONE:
	
	pop		es
	pop		ds
	pop		di
	pop		si
	pop		dx
	pop		cx
	mov sp, bp
	pop bp
	ret 2
findCode ENDP

MakeCalibratedByte PROC NEAR ; This function make a "calibration": it takes 3 bytes and a shift and makes from that a word in AX.
	push bp
	mov bp, sp
	push	cx
	push	dx
	push	si
	
				; if the shift is bigger than 7, we will inc si (byte of Raw we are reading)
		OK?:
			cmp dl, 8
			jb	shiftOK
			inc si
			sub dl, 8
			jmp OK?
		shiftOK:
			
		mov si, bp[4]	; Address of the byte that we have to "calibrate"
		mov cl, bp[6]	; Nbr of times we have to shift
		
		mov ah, [si]	; Load the first byte
		sal ah, cl		; The cl most significant bits (msb) of ah are written.
		mov dl, [si][1]	; Load the second byte
		sar dl, cl
		add ah, bl		; The other bits of ah are also written.
		
		mov al, [si][1]	; The cl most significant bits (msb) of al are written.
		sal al, cl
		mov bl, [si][2]
		sar bl, cl
		add al, bl		; The other bits of al are also written.
	
	pop		si
	pop		dx
	pop		cx
	mov sp, bp
	pop bp
	ret 4
MakeCalibratedByte ENDP

END