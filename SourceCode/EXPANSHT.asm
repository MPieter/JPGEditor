.MODEL large

.DATA
;PUBLIC HufDCLl, HufDCLd, HufDCCl, HufDCCd, HufACLl, HufACLd, HufACCl, HufACCd				; HT

;Hcode db 162 dup (?)
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
	
	mov di, offset Hcode
	mov si, offset HufACLl
	push si
	push di
	call generateHcode
	
	mov si, 0
	CHECK:
		mov dl, 43
		mov	ah, 02h	; print one character
		int	21h	; call DOS function

		mov dl, Hcode[si]
		mov	ah, 02h	; print one character
		int	21h	; call DOS function
		inc sI
		cmp sI, 16
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
		mov di, [bp][4]		; di gives the place of the new generated value
		mov si, [bp][6]		; si gives the address of the number of leaf nodes for each row
		xor ax, ax			; ax is the generated value
		
		; configure the two first row because the rule to jump to next row
		; ( add 1 and multiply by 2) don't works in those cases
		
			mov [di], ax
			inc ax
			inc di
			mov [di], ax
			
		mov bl, 14		; Will decrease after each row
		add si, 2
		inc di
	nextRow:
			cmp bl, 0
			je	Done
			dec bl
			mov cx, [si]
			inc si
			inc ax
			sal ax, 1
		write:
			cmp cx, 0
			je nextRow
			mov [di], ax
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
ret 4

generateHcode ENDP

END