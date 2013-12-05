.MODEL large
include READ.INC
.DATA
PUBLIC TBQuantizationL, TBQuantizationC, HcodeACL, HcodeACC, HcodeDCL, HcodeDCC, HufDCCd, HufACLd, HufACCd, HufDCLd, Raw

SOFHeader db 16 DUP (?)					; Start of Frame Baseline (SOF0) marker.
; Contains information like Image size, Bit Precision, Data unit size...
TBQuantizationL db 64 DUP (?)				; Quantisation Table L
TBQuantizationC db 64 DUP (?)				; Quantisation Table C
nReadedBytes dw 0			; number of read bytes, thanks to that we don't have to give ax as parameter when we call a procedure
; Data tables allow us to find the symbols (see comments before ExpansionHT)
; Length tables allow us to generate the code values, for translation bitstream -composed by codes- to symbols.
HufDCLl db 16 DUP (?)				; Huffman Tables for DC values of the light intensity (lengths)
HufDCLd db 12 DUP (?)				; Huffman Tables for DC values of the light intensity (data)
HufDCCl db 16 DUP (?)				; Huffman Tables for DC values of the chrominance (lengths)
HufDCCd db 12 DUP (?)				; Huffman Tables for DC values of the chrominance (data)
HufACLl db 16 DUP (?)				; Huffman Tables for AC values of the light intensity (lengths)
HufACLd db 162 DUP (?)				; Huffman Tables for AC values of the light intensity (data)
HufACCl db 16 DUP (?)				; Huffman Tables for AC values of the chrominance (lengths)
HufACCd db 162 DUP (?)				; Huffman Tables for AC values of the chrominance (data)
Raw db 60000 DUP (?)				; Raw BITstream
; Define place for code values
HcodeACL db 162 dup (?)
HcodeACC db 162 dup (?)
HcodeDCL db 162 dup (?)
HcodeDCC db 162 dup (?)
BESTANDSNAAM	DB "Test32~1.jpg",0		; Name of the JPGFile, followed by a 0, imposed convention for the use of read function.
											; The name have to be maximum 8 chars long.	
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
	
	call MakeFileOpen	; Gives File-Handle in AX back
	mov bx, ax			; File-Handle in BX veiligstellen

	call LEZEN			; (AX) = Aantal gelezen bytes
	;CMP AX,0			; Einde van het bestand?
	;JE EINDE_BESTAND
	
	call fillQTB_L		; AXinput = Aantal gelezen bytes
						; AXoutput = index of pointer in the LEESBUFFER
	mov si, ax			; make ax secure
	
	push si
	call fillQTB_C
	mov si, ax			; make ax secure

	push si
	call fillSOFheader
	mov si, ax			; make ax secure

	push si
	call readHuffmanTab
	mov si, ax
	
	push si
	call readBits		; ax gives the length of the data in Raw.
	mov si, ax
		mov di, si	

		; sub di, 20
		; add si, 3
		mov DI, 0
CHECK:
		mov dl, 43
		mov	ah, 02h	; print one character
		int	21h	; call DOS function

		mov dl, HufACCl[di]
		mov	ah, 02h	; print one character
		int	21h	; call DOS function
		inc DI
		cmp DI, 12
		jne CHECK
		

	; mov dx, offset msg3
	; mov ah, 09H
	; int 21H
	; mov dl, [nReading]
	; add dl, 48
	; mov	ah, 02h	; print one character
	; int	21h	; call DOS function
	; mov dx, offset msg3end
	; mov ah, 09H
	; int 21H

RETURN:
; --- Sluiten van het bestand		
EINDE_BESTAND: MOV AH,3EH
		INT 21H	
	mov sp, bp
	pop bp
	ret 0

readJPG ENDP
;---------------------------------------------------------
; All the data tables (HufXXXd) contains SYMBOLS
; A symbol gives the zero-run with his 4 most significant bits and gives the category with his 4 least significant bits.
; To understand the bit stream, we have to translate the Huffman codes (basis part of the bit stream) in symbols.
; In order to generate the Huffman code, we use the HufXXXl block.
; The index of the code in the generated Huffman code is than the same index as his associated symbol in the HufXXXd table.

expansionHT PROC FAR
	push bp
	mov bp, sp
	
	mov ax, seg HufACLl
	push ax
	mov ax, seg HcodeACL
	push ax
	mov si, offset HufACLl
	push si
	mov di, offset HcodeACL
	push di
	call generateHcode
	
		mov ax, seg HufACCl
	push ax
	mov ax, seg HcodeACC
	push ax
	mov si, offset HufACCl
	push si
	mov di, offset HcodeACC
	push di
	call generateHcode
	
	mov ax, seg HufDCLl
	push ax
	mov ax, seg HcodeDCL
	push ax
	mov si, offset HufDCLl
	push si
	mov di, offset HcodeDCL
	push di
	call generateHcode

	mov ax, seg HufDCCl
	push ax
	mov ax, seg HcodeDCC
	push ax
	mov si, offset HufDCCl
	push si
	mov di, offset HcodeDCC
	push di
	call generateHcode
	
	mov si, 0
	mov di, 0
	CHECK:
		mov dl, 42
		mov	ah, 02h	; print one character
		int	21h	; call DOS function

		mov dl, HcodeDCC[si]
		mov	ah, 02h	; print one character
		int	21h	; call DOS function
		mov dl, HufDCCd[si]
		mov	ah, 02h	; print one character
		int	21h	; call DOS function
		
				mov dl, 42
		mov	ah, 02h	; print one character
		int	21h	; call DOS function		mov dl, 42
		mov	ah, 02h	; print one character
		int	21h	; call DOS function

		mov ax, di
		mov dl, al
		mov	ah, 02h	; print one character
		int	21h	; call DOS function
		inc di
		
		mov dx, offset msg4
		mov ah, 09h
		int 21H
		
		inc sI
		cmp sI, 20
		jne CHECK
	
	mov sp, bp
	pop bp
	ret 0
expansionHT ENDP


; The Huffman code is generated following a binary tree "from the top down".
; Please refer you to the paragraph 'Expansion of DHT Table into binary bit strings' from
; http://www.impulseadventure.com/photo/jpeg-huffman-coding.html
; for more information
generateHcode PROC NEAR
push bp
mov bp, sp
	push di
	push cx
	push si
	push ax
		mov ds, [bp][10]
		mov es, [bp][8]
		mov di, [bp][4]		; di gives the place of the new generated value
		mov si, [bp][6]		; si gives the address of the number of leaf nodes for each row
		xor ax, ax			; al is the generated value
		xor cx, cx			; cl will be the number of leaf nodes we have to write before changing of row
		; configure the two first row because the rule to jump to next row
		; ( add 1 and multiply by 2) don't works in those cases
		
			mov es:[di], al
			inc ax
			inc di
			mov es:[di], al
			
		mov bl, 14		; Will decrease after each row,
		; we suppose that all the HufXXXl are 16 elements long (2 first raw are already passed bl=14)
		add si, 2
		inc di
	nextRow:
			cmp bl, 0
			je	Done
			dec bl
			mov cl, ds:[si]
			inc si
			inc ax
			sal ax, 1
		write:
			cmp cx, 0
			je nextRow
			mov es:[di], al
			inc ax
			inc di
			dec cx
			jmp write
Done:
	pop ax
	pop si
	pop cx
	pop di
mov sp, bp
pop bp
ret 8

generateHcode ENDP

;------------------------- Lezen van het volgend stuk
LEZEN PROC NEAR
push bp
mov bp, sp
	push dx
	push cx
	
	; mov dl, 42
	; mov ah, 02h
	; int 21h

	mov dl, nReading
	inc dl
	mov nReading, dl
	
; --- Bestand lezen
		MOV DX,OFFSET LEESBUFFER		
		MOV CX,512		
		MOV AH,3FH			; Sequentieel lezen uit het
		INT 21H				; bestand in de leesbuffer
		jnc RETURN
		mov dx, offset msg2
		mov ah, 09H
		int 21H
		mov	ax, 4c00h
		int	21h
RETURN:
	mov [nReadedBytes], ax	; Save the number of read bytes
	pop cx
	pop dx
	mov sp, bp
	pop bp
ret
LEZEN ENDP

;----------------------------- Make the source file open, print msg1 if an error occurs
MakeFileOpen PROC NEAR
	push	bp	; save dynamic link
	mov	bp, sp	; update bp
	
push dx
; --- Bestand openen			
		MOV DX,OFFSET BESTANDSNAAM		
		MOV AL,0			; Bestand openen om het te lezen
		MOV AH,3DH		
		INT 21H		
		JNC RETURN
		mov dx, offset msg1
		mov ah, 09H
		int 21H
		mov	ax, 4c00h
		int	21h
RETURN:
		pop dx
	mov bp, sp	
	pop bp
		RET 0
MakeFileOpen ENDP

;----------------------------- fillQTB_L: find the QTB_L values 
;----------------------------- and put them in the TBquantizationL--segment
fillQTB_L PROC NEAR ; AX as output gives the index of the pointer in LEESBUFFER
	push bp
	mov bp, sp
	push	cx
	push	dx
	push	si
	push	di
	push	ds
	push	es
	
	;mov cx, [nReadedBytes] ; cx=512
	; --- Find the QTB_L		
		mov si, 0			; begin to check from byte 1
FindQTB_L:
		MOV DL,LEESBUFFER[SI]
		cmp DL,0FFh		; Check if we find a marker (all the markers begins with FF)
		je GoodMarker		; Check if it is wel FF DB OO 43 OO, the marker indicating the QTB_L
		inc si
		cmp cx, si
		jbe CALLLEZEN
		jmp	FindQTB_L
CALLLEZEN:
		Call LEZEN			; Volgende blok van 512 bytes lezen
		MOV CX,AX			; (AX) = Aantal gelezen bytes
		sub si, 512
		jmp FindQTB_L
		
GoodMarker:
		inc si
		cmp LEESBUFFER[SI][0], 0DBH
		jne FindQTB_L
		cmp LEESBUFFER[SI][1], 0H
		jne FindQTB_L
		cmp LEESBUFFER[SI][2], 43H
		jne FindQTB_L
		cmp LEESBUFFER[SI][3], 0H
		jne FindQTB_L
		; If this point has been reached, you have found the marker indicating the QTB_L
		; add si, 4		; We go four bytes further
		; cmp cx, si
		; jbe CALLLEZEN1
		; jmp	further1
; CALLLEZEN1:
		; Call LEZEN			; Volgende blok van 512 bytes lezen
		; MOV CX,AX			; (AX) = Aantal gelezen bytes
		; sub si, 512
; further1:
		; mov DI, 0
		; je PUTinQTB_L

; PUTinQTB_L:
		; ; We place the following 64 bytes in TBquantizationL
		; MOV al, LEESBUFFER[SI]
		; mov TBquantizationL[DI], al
		; INC SI			; We go further in the LEESBUFFER
		; INC DI			; We write further in the TBQantisationL
		; ; Check now if we don't have to reload the LEESBUFFER
		; cmp cx, si
		; jbe CALLLEZEN2
		; jmp	further2
; CALLLEZEN2:
		; Call LEZEN			; Volgende blok van 512 bytes lezen
		; MOV CX,AX			; (AX) = Aantal gelezen bytes
		; sub si, 512
; further2:
		; cmp DI, 64
		; jne PUTinQTB_L
		
		mov ax, 4
		push ax ; number of bytes we want to jump over
		push si
		call JumpBytes
		mov si, ax

		mov di, offset TBquantizationL
		push di
		mov ax, 64
		push ax
		push si
		call BytesInMemory
		mov si, ax		

		mov	ax, si
	pop		es
	pop		ds
	pop		di
	pop		si
	pop		dx
	pop		cx
	mov sp, bp
	pop bp
ret 0
fillQTB_L ENDP

;----------------------------- fillQTB_C
; First parameter is the number of bytes we can read before that we have to load a new LEESBUFFER (call lezen)
; Second parameter is an index that points to the first value of QTB_C in LEESBUFFER
; The return args take the place of the two parameters.
fillQTB_C PROC NEAR
push bp
mov bp, sp
	push di
	push cx
	push si
	
	mov si, [bp][4] ; near proc, one word return address
	;mov cx, [nReadedBytes] ; cx=512
	
	; We will now be busy with the QTB_	C
	; Remark that SI point to the last L_value of the QTB_L.
	; If we go 5 bytes further, we jump above the header of the QTB_C and can directly read the values.
	
		mov ax, 5
		push ax ; number of bytes we want to jump over
		push si
		call JumpBytes
		mov si, ax
	
		mov di, offset TBquantizationC
		push di
		mov ax, 64
		push ax
		push si
		call BytesInMemory
		mov si, ax
		
	; add si, 5
		; cmp cx, si
		; jbe CALLLEZEN5
		; jmp	further5
; CALLLEZEN5:
		; Call LEZEN			; Volgende blok van 512 bytes lezen
		; MOV CX,AX			; (AX) = Aantal gelezen bytes
		; sub si, 512
; further5:
	
; mov di, 0 ; initialize di, will be the index for TBQantisationC
		
; PUTinQTB_C:
		; ; We place the following 64 bytes in TBquantizationL
		; MOV al, LEESBUFFER[SI]
		; mov TBquantizationC[DI], al
		; INC SI			; We go further in the LEESBUFFER
		; INC DI			; We write further in the TBQantisationL
		; cmp cx, si
		; jbe CALLLEZEN3
		; jmp	further3
; CALLLEZEN3:
		; Call LEZEN			; Volgende blok van 512 bytes lezen
		; MOV CX,AX			; (AX) = Aantal gelezen bytes
		; sub si, 512
; further3:
		; cmp DI, 64
		; jne PUTinQTB_C
	
	mov ax, si
	pop si
	pop cx
	pop di	
mov sp, bp
pop bp
ret 2
fillQTB_C ENDP

fillSOFheader PROC NEAR
push bp
mov bp, sp
	push di
	push cx
	push si
	mov si, [bp][4]
		;mov cx, [nReadedBytes] ; cx=512

		; We will now take the SOF header in memory, but we will jump over FF C0 and the first byte of the header length (00h)
		mov ax, 3
		push ax		; number of bytes we want to jump over
		push si
		call JumpBytes
		mov si, ax
		
		mov di, offset SOFheader
		push di
		mov ax, 16
		push ax
		push si
		call BytesInMemory
		mov si, ax
		
	; mov di, 0 ; initialize di, will be the index for PUTinSOFheader
; PUTinSOFheader:
		; ; We keep the SOFheader in memory because it should be useful ( contains Bit Precision, Image height, Image width, Components...)
		; MOV al, LEESBUFFER[SI]
		; mov SOFheader[DI], al
		; INC SI			; We go further in the LEESBUFFER
		; INC DI			; We write further in the TBQantisationL
		; cmp cx, si			; To make possible to check if we don't have to reload the LEESBUFFER
		; jbe CALLLEZEN4
		; jmp	further4
; CALLLEZEN4:
		; Call LEZEN			; Volgende blok van 512 bytes lezen
		; MOV CX,AX			; (AX) = Aantal gelezen bytes
		; sub si, 512
; further4:
		; cmp DI, 16			; We take only the 16 bytes with important information
		; jne PUTinSOFheader
		
	mov ax, si
	pop si
	pop cx
	pop di
mov sp, bp
pop bp
ret 2
fillSOFheader ENDP

readHuffmanTab PROC NEAR
push bp
mov bp, sp
	push di
	push cx
	push si
		mov si, [bp][4]

		;mov cx, [nReadedBytes]
	
		mov ax, 5
		push ax ; number of bytes we want to jump over
		push si
		call JumpBytes
		mov si, ax
		
		mov di, offset HufDCLl
		push di
		mov ax, 16
		push ax
		push si
		call BytesInMemory
		mov si, ax
		
		mov di, offset HufDCLd
		push di
		mov ax, 12
		push ax
		push si
		call BytesInMemory
		mov si, ax
		
		mov ax, 5
		push ax ; number of bytes we want to jump over
		push si
		call JumpBytes
		mov si, ax
		
		mov di, offset HufACLl
		push di
		mov ax, 16
		push ax
		push si
		call BytesInMemory
		mov si, ax
		
		mov di, offset HufACLd
		push di
		mov ax, 162
		push ax
		push si
		call BytesInMemory
		mov si, ax
		
		mov ax, 5
		push ax ; number of bytes we want to jump over
		push si
		call JumpBytes
		mov si, ax
		
		mov di, offset HufDCCl
		push di
		mov ax, 16
		push ax
		push si
		call BytesInMemory
		mov si, ax
		
		mov di, offset HufDCCd
		push di
		mov ax, 12
		push ax
		push si
		call BytesInMemory
		mov si, ax
		
		mov ax, 5
		push ax ; number of bytes we want to jump over
		push si
		call JumpBytes
		mov si, ax
		
		mov di, offset HufACCl
		push di
		mov ax, 16
		push ax
		push si
		call BytesInMemory
		mov si, ax
		
		mov di, offset HufACCd
		push di
		mov ax, 162
		push ax
		push si
		call BytesInMemory
		mov si, ax
		
	mov ax, si
	pop si
	pop cx
	pop di
mov sp, bp
pop bp
ret 2
readHuffmanTab ENDP

readBits PROC NEAR
push bp
mov bp, sp
	push di
	push cx
	push si
		mov si, [bp][4]
		
	mov cx, [nReadedBytes]
	mov di, 0
	
	PutAByte:
			MOV al, LEESBUFFER[SI]
			mov Raw[DI], al
			INC SI			; We go further in the LEESBUFFER
			INC DI
			cmp cx, si			; To make possible to check if we don't have to reload the LEESBUFFER
			jbe read
			jmp	PutAByte
		read:
			Call LEZEN			; Volgende blok van 512 bytes lezen,(AX) = Aantal gelezen bytes
			cmp ax, 0
			jz Done				; Check if we have read the all file
			MOV CX,AX			
			sub si, 512	
			jmp	PutAByte
		
		Done:
			sub di, 3
			xor al, al
			mov ds:[DI][1], al		; Delete the two last byte (=End Of Image Header)
			mov ds:[DI][2], al			
			
		mov ax, di ; ax gives than the length of the data placed in RAW
	pop si
	pop cx
	pop di
mov sp, bp
pop bp
ret 2
readBits ENDP

JumpBytes PROC NEAR ; Jump over some bytes, checking that we don't have to fill the LEESBUFFER again
push bp
mov bp, sp
	push di
	push cx
	push si
	mov si, [bp][4]
	mov ax, [bp][6]	; contains the number of bytes we have to jump over
	
		mov cx, [nReadedBytes]

			add si, ax
			cmp cx, si
			jbe read
			jmp	gofurther
	read:
			Call LEZEN			; Volgende blok van 512 bytes lezen
			MOV CX,AX			; (AX) = Aantal gelezen bytes
			sub si, 512
	gofurther:

	mov ax, si
	pop si
	pop cx
	pop di
mov sp, bp
pop bp
ret 4
JumpBytes ENDP

BytesInMemory PROC NEAR
push bp
mov bp, sp
	push di
	push cx
	push si
	push dx
	mov si, [bp][4]
	mov dx, [bp][6]	; number of bytes we have to copy in the memory
	mov di, [bp][8] ; offset of the begin of the memory location
	add dx, di		; offset of the end of the memory location
	mov cx, [nReadedBytes]

	PutAByte:
			MOV al, LEESBUFFER[SI]
			mov ds:[DI], al
			INC SI			; We go further in the LEESBUFFER
			INC DI
			cmp cx, si			; To make possible to check if we don't have to reload the LEESBUFFER
			jbe read
			jmp	jump
		read:
			Call LEZEN			; Volgende blok van 512 bytes lezen
			MOV CX,AX			;(AX) = Aantal gelezen bytes
			sub si, 512
		jump:
				cmp DI, dx			; We take only the 16 bytes with important information
				jne PutAByte
	
		mov ax, si
	pop dx
	pop si
	pop cx
	pop di
mov sp, bp
pop bp
ret 6
BytesInMemory ENDP
END