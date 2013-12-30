.MODEL large
include READ.INC
.DATA
READBUFFER	DB 512 DUP (?)					; Reserve 512 bytes for reading,
; 512 because the computer works per sector of 512 bytes (use of DOS-buffer to communicate with the external memory)
nReadedBytes dw 0							; number of effective wrote bytes in the READBUFFER
; nReading db 0								; Will gives how much times we called LEZEN (not used)
msg1 db "File can't be open.$"
msg2 db "File can't be read.$"
msg3 db "The file has been read in $"
msg3end db " times.",0dh, 0ah,"Each time we read 512 bytes.$"
msg4 db 0dh, 0ah, "$"
.CODE
readJPG PROC FAR
	push bp
	mov bp, sp
		push ax
		push bx
		
	call OpenFile
	mov bx, ax			; Put File-Handle in bx (would be use to close the file)
	
	call LEZEN			; (AX) = number of read bytes
	
	call fillQTB_L		; AX = index of pointer in the READBUFFER
	
	push ax
	call fillQTB_C		; AX = index of pointer in the READBUFFER

	push ax
	call fillSOFheader	; AX = index of pointer in the READBUFFER

	push ax
	call readHuffmanTab	; AX = index of pointer in the READBUFFER

	push ax
	call readBits		; ax gives the length of the data in Raw.

RETURN:
; --- Sluiten van het bestand		
EINDE_BESTAND: MOV AH,3EH
		INT 21H
		pop bx
		pop ax
	mov sp, bp
	pop bp
	ret 0
readJPG ENDP

;---------------------------------------------------------------------------------------
; Fulfils the READBUFFER, gives the number of effective read bytes (ax)
LEZEN PROC NEAR
push bp
mov bp, sp
	push dx
	push cx

	; mov dl, nReading
	; inc dl
	; mov nReading, dl
	
		MOV DX, OFFSET READBUFFER		
		MOV CX, 512		
		MOV AH, 3FH			; Sequentieel lezen uit het
		INT 21H				; bestand in de READBUFFER
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

;---------------------------------------------------------------------------------------
; Opens the source file, print msg1 if an error occurs
; Gives File-Handle in AX back
OpenFile PROC NEAR
	push	bp	; save dynamic link
	mov	bp, sp	; update bp
	
push dx
			
		MOV DX,OFFSET BESTANDSNAAM		
		MOV AL,0			; Read only: al=0
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
OpenFile ENDP

;---------------------------------------------------------------------------------------
; fillQTB_L: find the QTB_L values and put them in the TBquantizationL-segment
; AX gives the index of the pointer in READBUFFER
fillQTB_L PROC NEAR
	push bp
	mov bp, sp
	push	cx
	push	dx
	push	si
	push	di
	push	ds
	push	es
	
	mov cx, [nReadedBytes] ; cx=512
	; --- Find the QTB_L		
		mov si, 0			; begin to check from byte 1
FindQTB_L:
		MOV DL,READBUFFER[SI]
		cmp DL,0FFh		; Check if we find a marker (all the markers begins with FF)
		je GoodMarker		; Check if we find the marker FF DB OO 43 OO, ie. the marker indicating the QTB_L
		inc si
		cmp cx, si
		ja	FindQTB_L
CALLLEZEN:
		Call LEZEN			; Reload READBUFFER with the 512 next bytes of the file
		MOV CX,AX			; (AX) = number of effective read bytes
		sub si, 512
		jmp FindQTB_L
		
GoodMarker:
		inc si
		cmp READBUFFER[SI][0], 0DBH
		jne FindQTB_L
		cmp READBUFFER[SI][1], 0H
		jne FindQTB_L
		cmp READBUFFER[SI][2], 43H
		jne FindQTB_L
		cmp READBUFFER[SI][3], 0H
		jne FindQTB_L
		; If this point has been reached, we have found the marker indicating the QTB_L
		; We go four bytes further (jump over the marker)
		mov ax, 4
		push ax ; number of bytes we want to jump over
		push si	; index of the pointer in READBUFFER
		call JumpBytes
		mov si, ax
		
		; We place the following 64 bytes in TBquantizationL
		mov di, offset TBquantizationL
		push di
		mov ax, 64
		push ax	
		push si	; index of the pointer in READBUFFER
		call BytesInMemory ; ax as output of BytesInMemory is the same as what we want as output

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

;---------------------------------------------------------------------------------------
; fillQTB_C: read the QTB_C values and put them in the TBquantizationC-segment
; The pushed arg is the index of the pointer in the READBUFFER
; The output is the new index of the pointer in the READBUFFER
fillQTB_C PROC NEAR
push bp
mov bp, sp
	push di
	push cx
	push si
	
	mov si, [bp][4]
	
	; We will now be busy with the QTB_	C
	; Remark that SI point to the last L_value of the QTB_L.
	; If we go 5 bytes further, we jump above the header of the QTB_C and we can directly read the values.
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
	
	mov ax, si
	pop si
	pop cx
	pop di	
mov sp, bp
pop bp
ret 2
fillQTB_C ENDP

;---------------------------------------------------------------------------------------
; fillSOFheader: put the SOFheader in his reserved segment
; The SOFheader contains information that should be used to handle more JPEG-format
; The pushed arg is the index of the pointer in the READBUFFER
; The output is the new index of the pointer in the READBUFFER
fillSOFheader PROC NEAR
push bp
mov bp, sp
	push di
	push cx
	push si
	mov si, [bp][4]

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
		
	mov ax, si
	pop si
	pop cx
	pop di
mov sp, bp
pop bp
ret 2
fillSOFheader ENDP

;---------------------------------------------------------------------------------------
; This procedure loads successively the 4 different Huffman Tables (DC vs AC and Y vs C)
; The pushed arg is the index of the pointer in the READBUFFER
; The output is the new index of the pointer in the READBUFFER
readHuffmanTab PROC NEAR
push bp
mov bp, sp
	push di
	push cx
	push si
		mov si, [bp][4]
		
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
		call BytesInMemory	; ax as output of BytesInMemory is the same as what we want as output

	pop si
	pop cx
	pop di
mov sp, bp
pop bp
ret 2
readHuffmanTab ENDP

;---------------------------------------------------------------------------------------
; readBits loads the bitstream in raw
; The pushed arg is the index of the pointer in the READBUFFER
; The output (ax) gives than the length of the data put in RAW
readBits PROC NEAR
push bp
mov bp, sp
	push di
	push cx
	push si
		mov si, [bp][4]
		
	mov cx, [nReadedBytes]
		;-- Jump over the header of the bitstream
		mov ax, 14
		push ax ; number of bytes we want to jump over
		push si
		call JumpBytes
		mov si, ax
		
	mov di, 0
	
	PutAByte:
			MOV al, READBUFFER[SI]
			mov Raw[DI], al
			INC SI			; We go further in the READBUFFER
			INC DI
			cmp cx, si		; To make possible to check if we don't have to reload the READBUFFER
			ja PutAByte
		read:
			Call LEZEN			; Reload READBUFFER with the 512 next bytes of the file,(AX) = number of effective read bytes
			cmp ax, 0
			jz Done				; Check if we have read the all file
			MOV CX,AX			
			sub si, 512	
			jmp	PutAByte
		
		Done:
			sub di, 3
			xor ax, ax
			mov ds:[DI][2], ax		; Delete the two last byte (=End Of Image Header)			
			
		mov ax, di ; ax gives than the length of the data put in RAW
	pop si
	pop cx
	pop di
mov sp, bp
pop bp
ret 2
readBits ENDP

;---------------------------------------------------------------------------------------
; Jump over some bytes ( first arg on the stack),
; Second arg gives the index of the pointer in READBUFFER
; This procedure checks that we don't have to fill the READBUFFER again.
JumpBytes PROC NEAR
push bp
mov bp, sp
	push di
	push cx
	push si
	mov si, [bp][4] ; index of the pointer in the READBUFFER
	mov ax, [bp][6]	; contains the number of bytes we have to jump over
	
		mov cx, [nReadedBytes]

			add si, ax
			cmp cx, si
			ja	gofurther
	read:
			Call LEZEN			; Reload READBUFFER with the 512 next bytes of the file
			MOV CX,AX			; (AX) = number of effective read bytes
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

;---------------------------------------------------------------------------------------
; This procedure put n bytes at a given offset
; arg1: offset of the begin of the memory location
; arg2: number of bytes we have to copy in the memory
; arg3: index of the pointer in the READBUFFER
BytesInMemory PROC NEAR
push bp
mov bp, sp
	push di
	push cx
	push si
	push dx
	mov si, [bp][4]	; index of the pointer in the READBUFFER
	mov dx, [bp][6]	; number of bytes we have to copy in the memory
	mov di, [bp][8] ; offset of the begin of the memory location
	add dx, di		; offset of the end of the memory location
	mov cx, [nReadedBytes]
	; add si, offset READBUFFER
	; add cx, offset READBUFFER
	; mov es, seg READBUFFER
	; mov ds, seg READBUFFER
	; cld
	; PutAByte:
			; MOV al, ds:[SI]
			; mov es:[DI], al
	PutAByte:
			MOV al, READBUFFER[SI]
			mov ds:[DI], al
			INC SI			; We go further in the READBUFFER
			INC DI			; We go further in the Raw segment
			cmp DI, dx		; Do we load enough bytes ? 
			je	DONE
			cmp cx, si		; Do we have to reload the READBUFFER ?
			ja	PutAByte
		read:
			Call LEZEN			; Reload READBUFFER with the 512 next bytes of the file
			MOV CX,AX			;(AX) = number of effective read bytes
			sub si, 512
			jmp PutAByte
	DONE:
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