.MODEL large

.DATA

PUBLIC TBHuffman, TBQuantizationL, TBQuantizationC

SOFHeader db 16 DUP (?)					; Start of Frame Baseline (SOF0) marker.
; Contains information like Image size, Bit Precision, Data unit size...
TBQuantizationL db 64 DUP (?)				; Quantisation Table L
TBQuantizationC db 64 DUP (?)				; Quantisation Table C
TBHuffman db 0				; Huffman Tables
BESTANDSNAAM	DB "Test32~1.jpg",0		; Name of the JPGFile, followed by a 0, imposed convention for the use of read function.
											; The name have to be maximum 8 chars long.	
LEESBUFFER	DB 512 DUP (?)					; Reserve 512 bytes for reading,
; 512 because the computer works per sector of 512 bytes (use of DOS-buffer to communicate with the external memory)

msg1 db "File can't be open.$"
msg2 db "File can't be read.$"
BitPrecision db (?)
ImageH dw (?)
ImageW dw (?)
Component db (?)


.CODE

readJPG PROC FAR
	push bp
	mov bp, sp
	
	call MakeFileOpen	; Gives File-Handle in AX back
	mov bx, ax			; File-Handle in BX veiligstellen

	call LEZEN			; (AX) = Aantal gelezen bytes
	
	call FULLQTB_L		; AXinput = Aantal gelezen bytes
						; AXoutput = index of pointer in the LEESBUFFER
	mov si, ax			; make ax secure
		
; We will now be busy with the QTB_	C
; Remark that SI point to the last L_value of the QTB_L.
; If we go 5 bytes further, we jump above the header of the QTB_C and can directly read the values.
	add si, 5
	sub cx, 5
	push si
	push cx
	call FULLQTB_C
	pop cx
	pop si

	push si
	push cx		
	call fullSOFheader
	pop cx
	pop si
		mov DI, 0
CHECK:
		mov dl, 43
		mov	ah, 02h	; print one character
		int	21h	; call DOS function

		mov dl, TBQuantisationC[DI]
		mov	ah, 02h	; print one character
		int	21h	; call DOS function
		inc DI
		cmp DI, 64
		jne CHECK
		


RETURN:
; --- Sluiten van het bestand		
EINDE_BESTAND: MOV AH,3EH
		INT 21H	
	mov sp, bp
	pop bp
	ret

readJPG ENDP

;------------------------- Lezen van het volgend stuk
LEZEN PROC NEAR
	push bp
	mov bp, sp
	push dx
	push cx
	
	mov dl, 42
	mov ah, 02h
	int 21h

; --- Bestand lezen
		MOV DX,OFFSET LEESBUFFER		
		MOV CX,512		
		MOV AH,3FH			; Sequentieel lezen uit het
		INT 21H				; bestand in de leesbuffer
		jnc RETURN
		mov dx, offset msg2
		mov ah, 09H
		int 21H
		;CMP AX,0			; Einde van het bestand?
		;JE EINDE_BESTAND
RETURN:
	pop cx
	pop dx
	mov sp, bp
	pop bp
ret
LEZEN ENDP

;----------------------------- Make the source file open, print msg1 if an error occurs
MakeFileOpen PROC NEAR
push dx
; --- Bestand openen			
		MOV DX,OFFSET BESTANDSNAAM		
		MOV AL,0			; Bestand openen voor lezen
		MOV AH,3DH		
		INT 21H		
		JNC RETURN
		mov dx, offset msg1
		mov ah, 09H
		int 21H
RETURN:
		pop dx
		RET
MakeFileOpen ENDP

;----------------------------- FULLQTB_L: find the QTB_L values 
;----------------------------- and put them in the TBQuantisationL--segment
FULLQTB_L PROC NEAR ; AX as output gives the index of the pointer in LEESBUFFER
; AX as input gives the number of bytes we have to read (normally 512)
	push bp
	mov bp, sp
	push	cx
	push	dx
	push	si
	push	di
	push	ds
	push	es
	
	mov cx, ax
	; --- Find the QTB_L		
		mov si, 0			; begin to check from byte 1
FindQTB_L:
		MOV DL,LEESBUFFER[SI][0]
		cmp DL,0FFh		; Check if we find a marker (all the markers begins with FF)
		je GoodMarker		; Check if it is wel FF DB OO 43 OO, the marker indicating the QTB_L
		inc si
		dec cx
		cmp cx, 0
		jbe CALLLEZEN
		jmp	further
CALLLEZEN:
		Call LEZEN			; Volgende blok van 128 bytes lezen
		MOV CX,AX			; (AX) = Aantal gelezen bytes
		mov si, 0
further:
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
		add si, 4		; We go four bytes further
		sub cx, 4		; We go four bytes further
		cmp cx, 0
		jbe CALLLEZEN1
		jmp	further1
CALLLEZEN1:
		Call LEZEN			; Volgende blok van 128 bytes lezen
		MOV CX,AX			; (AX) = Aantal gelezen bytes
		mov si, 0
further1:
		mov DI, 0
		je PUTinQTB_L

PUTinQTB_L:
		; We place the following 64 bytes in TBQuantisationL
		MOV DL, LEESBUFFER[SI]
		mov TBQuantisationL[DI], dl
		INC SI			; We go further in the LEESBUFFER
		INC DI			; We write further in the TBQantisationL
		dec cx			; To check if we don't have to reload the LEESBUFFER
		cmp cx, 0
		jz CALLLEZEN2
		jmp	further2
CALLLEZEN2:
		Call LEZEN			; Volgende blok van 128 bytes lezen
		MOV CX,AX			; (AX) = Aantal gelezen bytes
		mov si, 0
further2:
		cmp DI, 64
		jne PUTinQTB_L
	
	mov	ax, si
	pop		es
	pop		ds
	pop		di
	pop		si
	pop		dx
	pop		cx
	mov sp, bp
	pop bp
ret
FULLQTB_L ENDP

;----------------------------- FULLQTB_C
; First parameter is the number of bytes we can read before that we have to load a new LEESBUFFER (call lezen)
; Second parameter is an index that points to the first value of QTB_C in LEESBUFFER
; The return args take the place of the two parameters.
FULLQTB_C PROC NEAR
	push bp
	mov bp, sp
	mov cx, [bp][4] ; near proc, one word return address
	mov si, [bp][6]
	push di
	
mov di, 0 ; initialize di, will be the index for TBQantisationC
		
PUTinQTB_C:
		; We place the following 64 bytes in TBQuantisationL
		MOV DL, LEESBUFFER[SI]
		mov TBQuantisationC[DI], dl
		INC SI			; We go further in the LEESBUFFER
		INC DI			; We write further in the TBQantisationL
		dec cx			; To make possible to check if we don't have to reload the LEESBUFFER
		cmp cx, 0
		jz CALLLEZEN3
		jmp	further3
CALLLEZEN3:
		Call LEZEN			; Volgende blok van 128 bytes lezen
		MOV CX,AX			; (AX) = Aantal gelezen bytes
		mov SI, 0
further3:
		cmp DI, 64
		jne PUTinQTB_C
	
	pop di
	mov [bp][4],cx
	mov [bp][6],si
	mov sp, bp
	pop bp
ret 0

FULLQTB_C ENDP

	push bp
	mov bp, sp
	mov cx, [bp][4] ; near proc, one word return address
	mov si, [bp][6]
	push di
	
	mov di, 0 ; initialize di, will be the index for TBQantisationC
	inc si		; we don't need to take the 2 marker bytes in memory
	dec cx
	
PUTinSOFheader:
		; We place the following 64 bytes in TBQuantisationL
		MOV DL, LEESBUFFER[SI]
		mov SOFheader[DI], dl
		INC SI			; We go further in the LEESBUFFER
		INC DI			; We write further in the TBQantisationL
		dec cx			; To make possible to check if we don't have to reload the LEESBUFFER
		cmp cx, 0
		jbe CALLLEZEN4
		jmp	further4
CALLLEZEN4:
		Call LEZEN			; Volgende blok van 128 bytes lezen
		MOV CX,AX			; (AX) = Aantal gelezen bytes
		mov SI, 0
further4:
		cmp DI, 16
		jne PUTinSOFheader
		
	pop di
	mov [bp][4],cx
	mov [bp][6],si
	mov sp, bp
	pop bp
ret 0

fullSOFheader ENDP
END