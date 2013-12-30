.MODEL large
INCLUDE EXPHT.INC

.DATA
msg4 db 0dh, 0ah, "$"

.CODE
;---------------------------------------------------------
; All the data tables (HufXXXd) contains SYMBOLS
; A symbol gives the zero-run with his 4 most significant bits and gives the category (length of the value) with his 4 least significant bits.
; To understand the bit stream, we have to translate the Huffman codes (basis part of the bit stream) in symbols.
; In order to generate the Huffman code, we use the HufXXXl block, containing the number of nodes at each level of a binary tree.
; The index of the code in the generated Huffman code is than the same index as his associated symbol in the HufXXXd table.

expansionHT PROC FAR
	push bp
	mov bp, sp
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	
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

	pop		di
	pop		si
	pop		dx
	pop		cx
	pop		bx
	pop		ax
	mov sp, bp
	pop bp
	ret 0
expansionHT ENDP

;---------------------------------------------------------------------------------------
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
	push bx
		mov ds, [bp][10]
		mov es, [bp][8]
		mov di, [bp][4]		; di gives the place of the new generated value
		mov si, [bp][6]		; si gives the address of the number of leaf nodes for each row
		xor ax, ax			; ax is the generated value
		xor cx, cx			; cl will be the number of leaf nodes we have to write before changing of row
		; configure the two first row because the rule to jump to next row
		; ( add 1 and multiply by 2) don't works in those cases
			
		mov bl, 16		; Will decrease after each row,
		; we suppose that all the HufXXXl are 16 elements long
		
	firstRow:
			dec bl
			mov cl, ds:[si]
			inc si
			cmp cl, 0
			je firstRow
			jmp write
	nextRow:
			dec bl
			cmp bl, 0
			je	Done
			mov cl, ds:[si]
			inc si
			sal ax, 1
		write:
			cmp cx, 0
			je nextRow
			mov es:[di], ax
			inc ax
			add di, 2
			dec cx
			jmp write
Done:
	pop bx
	pop ax
	pop si
	pop cx
	pop di
mov sp, bp
pop bp
ret 8
generateHcode ENDP
END