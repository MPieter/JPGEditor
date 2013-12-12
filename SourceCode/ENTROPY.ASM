.MODEL large
include ENTROPY.INC

.DATA


index dw 0	; Index representing the address of the byte we are working on in Raw
shift db 0	; Shift gives the bit of the byte we are working on
CalibratedWord dw 0 ; Output of makeCalibratedWord

Hufd dw 0
Hufl dw 0
Hcode dw 0
HufDCd dw 0
HufDCl dw 0
HcodeDC dw 0

PreviousDC dw 0
PreviousDCL dw 0
PreviousDCCr dw 0
PreviousDCCb dw 0

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
	; We initialize the parameters for the luminance(Y) case
	mov Hufl, offset HufACLl
	mov Hufd, offset HufACLd
	mov Hcode, offset HcodeACL
	mov HufDCd, offset HufDCLd
	mov HufDCl, offset HufDCLl
	mov HcodeDC, offset HcodeDCL
	
	mov ax, [PreviousDCL]
	mov [PreviousDC], ax
	mov cx, 4
Yblock:
	dec cx
	call findCode ; will transform a piece of bitstream Raw to a matrix of 64 words
	mov ax, offset inputIDCT
	push ax	; gives the address of the tabel to use for the dequantization
	call Dequantization ; this matrix will be dequantized
	mov ax, offset inputIDCT
	push ax	; gives the tabel to use for the dequantization
	call iDCT	; Then we applied the iDCT on the output of Dequantization
	;; TODO : Replace the output in memory (FARDATA ? )
	jnz	Yblock
	mov ax, [PreviousDC]
	mov [PreviousDCL], ax
	
	;--- Handle now the 2 dirominance-blocks (Cb and Cr)
	mov Hufl, offset HufACCl
	mov Hufd, offset HufACCd
	mov Hcode, offset HcodeACC
	mov HufDCd, offset HufDCCd
	mov HufDCl, offset HufDCCl
	mov HcodeDC, offset HcodeDCC
	
	mov ax, [PreviousDCCb]
	mov [PreviousDC], ax
	mov cx, 1
Cbblock:
	dec cx
	call findCode ; will transform a piece of bitstream Raw to a matrix of 64 words
	mov ax, offset inputIDCT
	push ax	; gives the address of the tabel to use for the dequantization
	call Dequantization ; this matrix will be dequantized
	mov ax, offset inputIDCT
	push ax	; gives the tabel to use for the dequantization
	call iDCT	; Then we applied the iDCT on the output of Dequantization
	;; TODO : Replace the output in memory (FARDATA ? )
	jnz	Cbblock	
	mov ax, [PreviousDC]
	mov [PreviousDCCb], ax
	
	mov ax, [PreviousDCCr]
	mov [PreviousDC], ax
	mov cx, 1
Crblock:
	dec cx
	call findCode ; will transform a piece of bitstream Raw to a matrix of 64 words
	mov ax, offset inputIDCT
	push ax	; gives the address of the tabel to use for the dequantization
	call Dequantization ; this matrix will be dequantized
	mov ax, offset inputIDCT
	push ax	; gives the tabel to use for the dequantization
	call iDCT	; Then we applied the iDCT on the output of Dequantization
	;; TODO : Replace the output in memory (FARDATA ? )
	jnz	Crblock	
	mov ax, [PreviousDC]
	mov [PreviousDCCr], ax
	
	mov sp, bp
	pop bp
	ret 0
entropyDecoding ENDP
 ; -----------------------------------------------------------
findCode PROC NEAR
	push bp
	mov bp, sp
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	ds
	push	es
	
	call MakeCalibratedWord	; CalibratedWord is up to date
	
	xor di, di	; di will be used for counting the number of time we write a word in the output matrix (have to increase until 64)
	xor bx, bx	; bx will run over the number of codes there is for each possible code length (ex: if there is no code of length 1 bit--> HufXXXl[bx]=0 with bx=0)
	xor si, si	; si gives the number of codes in Hcode we have to jump over because they don't have the good length.
	xor cx, cx	; cx runs about the codes of one length, but is also later use for shift-functions (cl and 1 are the only admitted parameters)
	
	; -- First word: the DC-value
	jmp nextLengthDC
	nextLengthAgainDC:
		xor ah, ah
		mov al, [HufDCl][bx]
		add si, ax
		inc bx
		nextLengthDC:
			mov ax, [CalibratedWord]
			mov cl, 15
			sub cl, bl
			sar ax, cl	; shift ax so that only the bl first bit are compared with the codes tasie.
			mov cl, HufDCl[bx]
			cmp cl, 0
			je	nextLengthAgainDC
				nextCodeDC:
					cmp ax, HcodeDC[si][cx]
					je DecodeDCvalue
					dec cl
					cmp cl, 0
					je nextLengthAgainDC
					jmp nextCodeDC
	DecodeDCvalue:
			mov al, HufDCd[si][cx]
			mov cl, 4
			sal al, cl	; the length of the non-zero value is given by the 4 least significant bits of the symbol
			mov dh, al	; put al in security cause ax will be the output of MakeCalibratedWord
			mov dl, [shift]
			add dl, bl	; dl gives the total shift we have to do to find the non-zero value. ( previous shift + shift over the code (bx) )
			mov [shift], dl
			call MakeCalibratedWord
			; we are only interessed in the number formed by the dh (=length of the non-zero value) most significant bits.
			mov cl, 16
			sub cl, dh	; cl= 16 - length of the non-zero value
			sar ax, cl
			mov bx, [previousDC]
			add ax, bx
			mov [previousDC], ax
			mov inputIDCT[di], ax
			inc di		; a word has been written in the inputIDCT
			; We will shift again, dh times. Like that shall the part DecodeAword correctly works.
			mov dl, [shift]
			add dl, dh
			mov [shift], dl
			call MakeCalibratedWord
					
	; -- We handle now the 63 AC-values
	jmp DecodeAword
	DecodeAwordAgain:
		; [si][cl] gives the index of the symbol in Hufd
		;---- Write zeros-length times 0's
		mov al, Hufd[si][cx]
		mov cl, 4
		sar al, cl	; the zeros-length is given by the 4 most significant bits of the symbol
		fillMatrix:
			cmp al, 0
			je WriteWord
			mov inputIDCT[di], 0
			dec al
			inc di		; a word has been written in the inputIDCT
			jmp fillMatrix
		;---- Write the non-zero value
		WriteWord:
			mov al, Hufd[si][cx]
			mov cl, 4
			sal al, cl	; the length of the non-zero value is given by the 4 least significant bits of the symbol
			mov dh ,al	; put al in security cause ax will be the output of MakeCalibratedWord
			mov dl, [shift]
			add dl, bl	; dl gives the total shift we have to do to find the non-zero value. ( previous shift + shift over the code (bx) )
			mov [shift], dl
			call MakeCalibratedWord
			; we are only interessed in the number formed by the dh (=length of the non-zero value) most significant bits.
			mov cl, 16
			sub cl, dh	; cl= 16 - length of the non-zero value
			sar ax, cl
			mov inputIDCT[di], ax
			inc di		; a word has been written in the inputIDCT
			; We will shift again, dh times. Like that shall the part DecodeAword correctly works.
			mov dl, [shift]
			add dl, dh
			mov [shift], dl
			call MakeCalibratedWord
	
	DecodeAword:
		xor bx, bx
		cmp di, 64
		je DONE
		jmp nextLength
		nextLengthAgain:
		xor ah, ah
		mov al, HufDCl[bx]
		add si, ax
		inc bx
		nextLength:
			mov ax, [CalibratedWord]
			mov cl, 15
			sub cl, bl
			sar ax, cl	; shift ax so that only the bl first bit are compared with the codes tasie.
			mov cl, Hufl[bx]
			cmp cl, 0
			je	nextLengthAgain
				nextCode:
					cmp ax, Hcode[si][cx]
					je DecodeAwordAgain
					dec cl
					cmp cl, 0
					je nextLengthAgain
					jmp nextCode
		DONE:

	pop		es
	pop		ds
	pop		di
	pop		si
	pop		dx
	pop		cx
	pop		bx
	pop		ax
	mov sp, bp
	pop bp
	ret
findCode ENDP
; -----------------------------------------------------------
MakeCalibratedWord PROC NEAR ; This function make a shifted word: it takes 3 bytes and a shift and makes from that a word in AX (also put in CalibratedWord).
	push bp
	mov bp, sp
	push	cx
	push	dx
	push	si
	
	mov cl, [shift]	; Nbr of times we have to shift
	mov si, [index]	; address of the byte we have to shift
				; if the shift is bigger than 7, we will inc si (byte of Raw we are reading)
		OK?:
			cmp cl, 8
			jb	shiftOK
			inc si
			sub cl, 8
			jmp OK?
		shiftOK:
		
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
		
	mov [shift], cl
	mov [index], si
	
	mov [CalibratedWord], ax; Output of makeCalibratedWord
	
	pop		si
	pop		dx
	pop		cx
	mov sp, bp
	pop bp
	ret
MakeCalibratedWord ENDP

END