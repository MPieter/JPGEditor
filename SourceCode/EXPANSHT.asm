.MODEL large
INCLUDE EXPANSHT.inc

.DATA
msg4 db 0dh, 0ah, "$"
.CODE
;---------------------------------------------------------
; All the data tables (HufXXXd) contains SYMBOLS
; A symbol gives the zero-run with his 4 most significant bits and gives the category with his 4 least significant bits.
; To understand the bit stream, we have to translate the Huffman codes (basis part of the bit stream) in symbols.
; In order to generate the Huffman code, we use the HufXXXl block.
; The index of the code in the generated Huffman code is than the same index as his associated symbol in the HufXXXd table.

expansionHT PROC FAR
	push bp
	mov bp, sp
	
	;mov ax, seg HufACLl
	; push ax
	; mov ax, seg HcodeACL
	; push ax
	; mov si, offset HufACLl
	; push si
	; mov di, offset HcodeACL
	;push di
	; call generateHcode
	
	; mov ax, seg HufACCl
	; push ax
	; mov ax, seg HcodeACC
	; push ax
	; mov si, offset HufACCl
	; push si
	; mov di, offset HcodeACC
	; push di
	; call generateHcode
	
	; mov ax, seg HufDCLl
	; push ax
	; mov ax, seg HcodeDCL
	; push ax
	; mov si, offset HufDCLl
	; push si
	; mov di, offset HcodeDCL
	; push di
	; call generateHcode

	; mov ax, seg HufDCCl
	; push ax
	; mov ax, seg HcodeDCC
	; push ax
	; mov si, offset HufDCCl
	; push si
	; mov di, offset HcodeDCC
	; push di
	; call generateHcode
	
	; mov si, 0
	; mov di, 0
	; CHECK:
		; mov dl, 42
		; mov	ah, 02h	; print one character
		; int	21h	; call DOS function

		; mov ax, HcodeDCC[si]
		; mov dl, al
		; mov	ah, 02h	; print one character
		; int	21h	; call DOS function
		; mov dl, HufDCCd[di]
		; mov	ah, 02h	; print one character
		; int	21h	; call DOS function
		
		; mov dl, 42
		; mov	ah, 02h	; print one character
		; int	21h	; call DOS function		
		; mov dl, 42
		; mov	ah, 02h	; print one character
		; int	21h	; call DOS function

		; mov ax, di
		; mov dl, al
		; mov	ah, 02h	; print one character
		; int	21h	; call DOS function
		; inc di
		
		; mov dx, offset msg4
		; mov ah, 09h
		; int 21H
		
		; add si, 2
		; cmp dI, 20
		; jne CHECK
	
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
		xor ax, ax			; ax is the generated value
		xor cx, cx			; cl will be the number of leaf nodes we have to write before changing of row
		; configure the two first row because the rule to jump to next row
		; ( add 1 and multiply by 2) don't works in those cases
		
			mov es:[di], ax
			inc ax
			inc di
			mov es:[di], ax
			
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
			mov es:[di], ax
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
END