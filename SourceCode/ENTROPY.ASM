.MODEL large
include ENTROPY.INC
include IDCT.INC
include QUANT.INC

.DATA
index dw offset raw	; Index representing the address of the byte we are working on in Raw
shift db 0			; Shift gives the bit of the byte we are working on
CalibratedWord dw 0 ; Output of makeCalibratedWord

; Hufd dw 0
; Hufl dw 0
; Hcode dw 0
; HufDCd dw 0
; HufDCl dw 0
; HcodeDC dw 0
; OffsetOut dw offset inputIDCT

; PreviousDC dw 0
PreviousDCL dw 0
PreviousDCCr dw 0
PreviousDCCb dw 0
msg4 db 0dh, 0ah, "$"
msgNewMDU db "  New MDU ! :$"

.CODE
entropyDecoding PROC FAR
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
	
NEXTMDU: ; One MDU is in our case (Color Space defined by YUV= 4:2:0):
			; A 16x16 pixels-block
			; Composed by 4 8x8 bytes Y-block, 1 8x8 bytes Cb-block and 1 8x8 bytes Cr-block
		
mov dx, offset msgNewMDU
mov ah, 09H
int 21H
		
		
		mov bx, offset inputIDCT 
	
	;--- Let's handle the first 4 Y-blocks
	; We initialize the parameters for the luminance(Y) case
	mov ax, [PreviousDCL]
		mov cx, 4
	Yblock:
		push bx		; offsetOut
		push ax		; PreviousDC
		mov ax, offset HufACLl
		push ax
		mov ax, offset HufACLd
		push ax
		mov ax, offset HcodeACL
		push ax
		mov ax, offset HufDCLd
		push ax
		mov ax, offset HufDCLl
		push ax
		mov ax, offset HcodeDCL
		push ax
		call findCode ; will transform a piece of bitstream Raw to a matrix of 64 words
					mov dx, offset msg4
					mov ah, 09H
					int 21H
					mov si, 0
					Check:
						mov dx, [bx][si]
						mov ah, 02h
						int 21h
						add si, 2
						cmp si, 128
						jne Check
		pop ax		; PreviousDC
		pop bx		; offset Out
		add bx, 128
		dec cx
		jnz	Yblock
	mov [PreviousDCL], ax

	;--- Handle now the 2 dirominance-blocks (Cb and Cr)
	
	mov ax, [PreviousDCCb]
		mov cx, 1
	Cbblock:
		push bx		; offsetOut
		push ax		; PreviousDC
		mov ax, offset HufACCl
		push ax
		mov ax, offset HufACCd
		push ax
		mov ax, offset HcodeACC
		push ax
		mov ax, offset HufDCCd
		push ax
		mov ax, offset HufDCCl
		push ax
		mov ax, offset HcodeDCC
		push ax
		call findCode ; will transform a piece of bitstream Raw to a matrix of 64 words
					mov dx, offset msg4
					mov ah, 09H
					int 21H
					mov si, 0
					@@:
						mov dx, [bx][si]
						mov ah, 02h
						int 21h
						add si, 2
						cmp si, 128
						jne @b
		pop ax		; PreviousDC
		pop bx		; offset Out
		add bx, 128
		dec cx
		jnz	Cbblock	
	mov [PreviousDCCb], ax
	
	mov ax, [PreviousDCCr]
		mov cx, 1
	Crblock:
		push bx		; offsetOut
		push ax		; PreviousDC
		mov ax, offset HufACCl
		push ax
		mov ax, offset HufACCd
		push ax
		mov ax, offset HcodeACC
		push ax
		mov ax, offset HufDCCd
		push ax
		mov ax, offset HufDCCl
		push ax
		mov ax, offset HcodeDCC
		push ax
		call findCode ; will transform a piece of bitstream Raw to a matrix of 64 words
					mov dx, offset msg4
					mov ah, 09H
					int 21H
					mov si, 0
					@@:
						mov dx, [bx][si]
						mov ah, 02h
						int 21h
						add si, 2
						cmp si, 128
						jne @b
		pop ax		; PreviousDC
		pop bx		; offset Out
		add bx, 128
		dec cx
		jnz	Crblock	
	mov [PreviousDCCr], ax
	
			mov dx, offset msg4
			mov ah, 09H
			int 21H
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
	ret 0
entropyDecoding ENDP

;---------------------------------------------------------------------------------------
; findCode translate a part of the bitstream (composed of codes) in 64 values forming a matrix (inputIDCT)
; This matrix represents one of the 6 blocks forming our MDU. ( we use 4:2:0 colorspace)
; findCode have to recognize codes: it checks first one bit of the bitstream and compare this with the existing code of one bit,
; If no one are equals, the same is tried with 2 bits, then 3, 4, ... until we find the code that the bitstream represents.
; The index of the code in Hcode is the same as the one in HufXXXd (the symbols table).
; The symbol contains the zeros-length and the length of the non-zero value.
; Finally: We put the zeros and the non-zero value in inputIDCT.
; The arguments have to follow this example:
		; arg1: offsetOut
		; arg2: PreviousDC
		; arg3: offset HufACLl
		; arg4: offset HufACLd
		; arg5: offset HcodeACL
		; arg6: offset HufDCLd
		; arg7: offset HufDCLl
		; arg8: offset HcodeDCL
; Two values stay on the stack after returning:
		; arg1: offsetOut (new value)
		; arg2: PreviousDC (new value)
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
	
	xor di, di	; di gives principally the length of the codes with witch we have to check.
				; it also can contain the offset of the output.
	xor bx, bx	; bx will run over all the codes of length di
				; it shall also be used as temporary memory
				; cl is used for shift-functions (cl and 1 are the only admitted parameters)
				; ch is not used.
	xor dh, dh	; dh have to equal 0 (for a correct use of dx)
	; dl will be used for counting the number of time we write a word in the output matrix (have to increase until 128 (64 words) )
	
	; -- First word: the DC-value
	mov si, [bp][4]	; si gives the offset for directly accessing the codes with the good length.
						; HcodeDC
	mov di, [bp][6]	; di gives principally the offset to find the length of the codes with witch we have to check.
						; it also can contain the offset of the output-segment
						; HufDCl
	jmp nextLengthDC
	nextLengthAgainDC:
		mov al, [di]
		xor ah, ah
		shl al, 1
		add si, ax				; si contains the number of not-equal codes (too short length)
		inc dh					; we will compare the bitstream with codes of length dh+1
		inc di
		nextLengthDC:
			mov ax, [CalibratedWord]
			mov bl, 15
			sub bl, dh
			mov cl, bl
			shr ax, cl			; shift ax so that only the bl first bit are compared with the codes table.
			mov cl, [di]	; cl gives the number of code with length di+1
			cmp cl, 0
			je	nextLengthAgainDC
			shl cl, 1			; the offset is multiplied by 2 because we works with words
			xor bx, bx
				nextCodeDC:
					cmp ax, [si][bx]
					je DecodeDCvalue
					add bl, 2
					cmp bl, cl
					je nextLengthAgainDC
					jmp nextCodeDC
	DecodeDCvalue:
			sub si, [bp][4]	; HcodeDC
			; ; [si][bx] gives the index of the symbol in Hufd
			inc dh
			mov cl, [shift]
			add cl, dh	; cl gives the total shift we have to do to find the non-zero value. ( previous shift + shift over the code (di) )
			mov [shift], cl
			shr bx, 1
			shr si, 1
			inc si
			add si, [bp][8]	; HufDCd
			mov bl, [si][bx]	; put the symbol in bl ( always 4 bits 0 and then 4 bits that give the length of the DC-value)
			call MakeCalibratedWord
			; we are only interested in the number formed by the bl (=length of the non-zero value) most significant bits.
			mov cl, 16
			sub cl, bl	; cl= 16 - length of the non-zero value
			shr ax, cl
			mov di, [bp][16]	; PreviousDC
			add ax, di
			mov [bp][16], ax
			mov di, [bp][18]	; offsetOut
			mov [di], ax
			mov dl, 2		; the first word has been written in the inputIDCT
			; We will shift again, bl times. Like that shall the part DecodeAword correctly works.
			mov cl, [shift]
			add cl, bl
			mov [shift], cl
			call MakeCalibratedWord
					
	; -- We handle now the 63 AC-values
	mov di, [bp][14]		; HufACl
	mov si, [bp][10]		; HcodeAC
	xor dh, dh
	jmp nextLength
	DecodeAwordAgain:
		sub si, [bp][10]		; HcodeAC
		sub di, [bp][14]		; HufACl
		; ; Check if we find End Of Block symbol (in al)
		shr bx, 1
		shr si, 1
		add si, [bp][12]	; HufACd
		mov al, [si][bx]
		cmp al, 0
		je EOB2
		; [si][bx] gives the index of the symbol in Hufd
		; ; Prepare the shift for call MakeCalibratedByte (we can than overwrite di)
		inc dh
		mov cl, [shift]
		add cl, dh	; cl gives the total shift we have to do to find the non-zero value. ( previous shift + shift over the code (di) )
		mov [shift], cl
		; ;---- Write zeros-length times 0's
		mov cl, 4
		shr al, cl	; the zeros-length is given by the 4 most significant bits of the symbol
		xor dh, dh
		mov di, [bp][18]	; offsetOut
		add di, dx
		xor dx, dx
		fillMatrix:
			cmp al, 0
			je WriteWord
			mov [di], dx
			dec al
			add di, 2		; a word has been written in the inputIDCT
			jmp fillMatrix
		
		; ;---- Write the non-zero value
		WriteWord:
			sub di, [bp][18]	; offsetOut
			mov dx, di
			mov bl, [si][bx]
			mov cl, 4
			sal bl, cl	; the length of the non-zero value is given by the 4 least significant bits of the symbol
			ror bl, cl	; We have now 4 zeros and then the length of the AC value given by the 4 least sign. bits.
			call MakeCalibratedWord
			; we are only interested in the number formed by the bl (=length of the non-zero value) most significant bits.
			mov cl, 16
			sub cl, bl	; cl= 16 - length of the non-zero value
			shr ax, cl
			mov di, [bp][18]	; offsetOut
			add di, dx
			mov [di], ax
			add dl, 2
			; We will shift again, bl times. Like that shall the part DecodeAword correctly works.
			mov cl, [shift]
			add cl, bl
			mov [shift], cl
			call MakeCalibratedWord
		cmp dl, 128		; check index running over inputIDCT
		je DONE
		mov si, [bp][10]		; HcodeAC
		mov di, [bp][14]		; HufACl
		jmp nextLength
		
		DecodeAwordAgain2:
			jmp DecodeAwordAgain
		EOB2:
			jmp EOB
			
		nextLengthAgain:
		xor ah, ah
		mov al, [di]
		shl al, 1
		add si, ax
		inc di
		inc dh
		nextLength:
			mov ax, [CalibratedWord]
			mov bl, 15
			sub bl, dh
			mov cl, bl
			shr ax, cl	; shift ax so that only the bl first bit are compared with the codes table.
			mov cl, [di]
			cmp cl, 0
			je	nextLengthAgain
			shl cl, 1
			xor bx, bx
				nextCode:
					cmp ax, [si][bx]
					je DecodeAwordAgain2
					add bl, 2		
					cmp bl, cl
					je nextLengthAgain
					jmp nextCode
		EOB:
				xor dh, dh
				mov di, dx
				add di, [bp][18]	; offsetOut
				xor cx, cx
				write0:
					mov [di], cx
					add dx, 2
					cmp dx, 128		; check index running over inputIDCT
					jne write0
				mov cl, [shift]
				add cl, 4
				mov [shift], cl
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
	ret 12
findCode ENDP

; -----------------------------------------------------------
; This procedure extract from a 24-word 16 of his bits, forming a 16-word with witch the procedure findCode works.
; This procedure use 2 args (defined above):
; 	- index:	input: address of the 24-word
;				output: address of the byte in witch begins the 16-word
; 	- shift:	input: shift given the begin of the 16-word
;				output: normalized shift given the begin of the 16-word
; ax gives the 16-word back, also update in CalibratedWord
MakeCalibratedWord PROC NEAR
	push bp
	mov bp, sp
	push	cx
	push	dx
	push	si
	
	mov cl, [shift]	; Nbr of times we have to shift
	mov si, [index]	; address in Raw of the 24-word we have to shift
		; --- Normalizing shift ---
		; If the shift is bigger than 7, we will inc si (byte of Raw we are reading)
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
		mov ch, 8
		sub ch, cl
		mov cl, ch ; cl = 8 - cl , we transform cl to know how much bits of the second byte we need.
			shr dl, cl
		mov ch, cl
		mov cl, 8
		sub cl, ch ; cl = 8 - cl , we find back cl = shift
		add ah, dl		; The other bits of ah are also written.
		
		mov al, [si][1]	; The cl most significant bits (msb) of al are written.
			sal al, cl
		mov dl, [si][2]
		mov ch, 8
		sub ch, cl
		mov cl, ch ; cl = 8 - cl , we transform cl to know how much bits of the second byte we need.
			shr dl, cl
		mov ch, cl
		mov cl, 8
		sub cl, ch ; cl = 8 - cl , we find back cl = shift
		add al, dl		; The other bits of al are also written.
		
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

; Other possibility: Defined findCodeY, findCodeCr and findCodeCb like this. Then you only have to give the offset of the output values as arg. 
; findCodeY PROC NEAR
	; push bp
	; mov bp, sp
	; push	ax
	; push	bx
	; push	cx
	; push	dx
	; push	si
	; push	di
	; push	ds
	; push	es
	
	; call MakeCalibratedWord	; CalibratedWord is up to date
	
	; xor di, di	; di gives principally the length of the codes with witch we have to check.
	; xor bx, bx	; bx will run over the codes there is for one length
	; xor si, si	; si gives the number of codes in Hcode we have to jump over because they don't have the good length.
	; xor cx, cx	; cx is principally used for shift-functions (cl and 1 are the only admitted parameters)
	; xor dh, dh	; dh have to equal 0
	; ; dl will be used for counting the number of time we write a word in the output matrix (have to increase until 128 (64 words) )
	
	; ; -- First word: the DC-value
	; jmp nextLengthDC
	; nextLengthAgainDC:
		; mov al, HufDCLl[di]
		; xor ah, ah
		; shl al, 1
		; add si, ax				; si contains the number of not-equal codes (too short length)
		; inc di					; we will compare the bitstream with codes of length di+1
		; nextLengthDC:
			; mov ax, [CalibratedWord]
			; mov bx, 15
			; sub bx, di
			; mov cl, bl
			; shr ax, cl			; shift ax so that only the bl first bit are compared with the codes table.
			; mov cl, HufDCLl[di]	; cl gives the number of code with length di+1
			; cmp cl, 0
			; je	nextLengthAgainDC
			; shl cl, 1			; the offset is multiplied by 2 because we works with words
			; xor bx, bx
				; nextCodeDC:
					; cmp ax, HcodeDCL[si][bx]
					; je DecodeDCvalue
					; add bl, 2
					; cmp bl, cl
					; je nextLengthAgainDC
					; jmp nextCodeDC
	; DecodeDCvalue:
			; ; ; [si][bx] gives the index of the symbol in Hufd
			; inc di
			; mov cl, [shift]
			; add cx, di	; cx gives the total shift we have to do to find the non-zero value. ( previous shift + shift over the code (di) )
			; mov [shift], cl
			; shr bx, 1
			; shr si, 1
			; inc si
			; mov bl, HufDCLd[si][bx]	; put the symbol in bl ( always 4 bits 0 and then 4 bits that give the length of the DC-value)
			; call MakeCalibratedWord
			; ; we are only interested in the number formed by the bl (=length of the non-zero value) most significant bits.
			; mov cl, 16
			; sub cl, bl	; cl= 16 - length of the non-zero value
			; shr ax, cl
			; mov di, [PreviousDCL]
			; add ax, di
			; mov [previousDCL], ax
			; mov inputIDCT[0], ax
			; mov dl, 2		; the first word has been written in the inputIDCT
			; ; We will shift again, bl times. Like that shall the part DecodeAword correctly works.
			; mov cl, [shift]
			; add cl, bl
			; mov [shift], cl
			; call MakeCalibratedWord
					
	; ; -- We handle now the 63 AC-values
	; xor di, di
	; xor si, si
	; jmp nextLength
	; DecodeAwordAgain:
		; ; ; Check if we find End Of Block symbol (in al)
		; shr bx, 1
		; shr si, 1
		; mov al, HufACLd[si][bx]
		; cmp al, 0
		; je EOB2
		; ; [si][bx] gives the index of the symbol in Hufd
		; ; ; Prepare the shift for call MakeCalibratedByte (we can than overwrite di)
		; inc di
		; mov cl, [shift]
		; add cx, di	; ch gives the total shift we have to do to find the non-zero value. ( previous shift + shift over the code (di) )
		; mov [shift], cl
		; ; ;---- Write zeros-length times 0's
		; mov cl, 4
		; shr al, cl	; the zeros-length is given by the 4 most significant bits of the symbol
		; mov di, dx
		; fillMatrix:
			; cmp al, 0
			; je WriteWord
			; mov inputIDCT[di], 0
			; dec al
			; add di, 2		; a word has been written in the inputIDCT
			; jmp fillMatrix
		; mov dx, di
		; ; ;---- Write the non-zero value
		; WriteWord:
			; mov bl, HufACLd[si][bx]
			; mov cl, 4
			; sal bl, cl	; the length of the non-zero value is given by the 4 least significant bits of the symbol
			; ror bl, cl	; We have now 4 zeros and then the length of the AC value given by the 4 least sign. bits.
			; call MakeCalibratedWord
			; ; we are only interested in the number formed by the bl (=length of the non-zero value) most significant bits.
			; mov cl, 16
			; sub cl, bl	; cl= 16 - length of the non-zero value
			; shr ax, cl
			; mov di, dx
			; mov inputIDCT[di], ax
			; add dl, 2
			; ; We will shift again, bl times. Like that shall the part DecodeAword correctly works.
			; mov cl, [shift]
			; add cl, bl
			; mov [shift], cl
			; call MakeCalibratedWord
		; cmp dl, 128		; check index running over inputIDCT
		; je DONE
		; xor si, si
		; xor di, di
		; jmp nextLength
		
		; DecodeAwordAgain2:
			; jmp DecodeAwordAgain
		; EOB2:
			; jmp EOB
			
		; nextLengthAgain:
		; xor ah, ah
		; mov al, HufACLl[di]
		; shl al, 1
		; add si, ax
		; inc di
		; nextLength:
			; mov ax, [CalibratedWord]
			; mov bx, 15
			; sub bx, di
			; mov cl, bl
			; shr ax, cl	; shift ax so that only the bl first bit are compared with the codes table.
			; mov cl, HufACLl[di]
			; shl cl, 1
			; xor bx, bx
			; cmp cl, 0
			; je	nextLengthAgain
				; nextCode:
					; cmp ax, HcodeACL[si][bx]
					; je DecodeAwordAgain2
					; add bl, 2		
					; cmp bl, cl
					; je nextLengthAgain
					; jmp nextCode
		; EOB:
			; mov di, dx
		; write0:
			; mov inputIDCT[di], 0
			; add dx, 2
			; cmp dx, 128		; check index running over inputIDCT
			; jne write0
		; DONE:

	; pop		es
	; pop		ds
	; pop		di
	; pop		si
	; pop		dx
	; pop		cx
	; pop		bx
	; pop		ax
	; mov sp, bp
	; pop bp
	; ret
; findCodeY ENDP

END