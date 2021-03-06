.MODEL large

include IDCT.INC

; Constants
blockDim equ 8
blockEl equ 64

.DATA
	c0 dw 8 dup(?); c coefficients
	c1 dw 8 dup(?)
	c2 dw 8 dup(?)
	c3 dw 8 dup(?)
	c4 dw 8 dup(?)
	c5 dw 8 dup(?)
	c6 dw 8 dup(?)
	c7 dw 8 dup(?)
	d0 dw 8 dup(?) ; d coefficients
	d1 dw 8 dup(?)
	d2 dw 8 dup(?)
	d3 dw 8 dup(?)
	d4 dw 8 dup(?)
	d5 dw 8 dup(?)
	d6 dw 8 dup(?)
	d7 dw 8 dup(?)
	b0 dw 8 dup(?) ; b coefficients
	b1 dw 8 dup(?)
	b2 dw 8 dup(?)
	b3 dw 8 dup(?)
	b4 dw 8 dup(?)
	b5 dw 8 dup(?)
	b6 dw 8 dup(?)
	b7 dw 8 dup(?)
	a0 dw 8 dup(?) ; a coefficients
	a1 dw 8 dup(?) 
	a2 dw 8 dup(?)
	a3 dw 8 dup(?)
	a4 dw 8 dup(?)
	a5 dw 8 dup(?)
	a6 dw 8 dup(?)
	a7 dw 8 dup(?)
	
	temp1 dw 8 dup(?) ; used for interim results
	temp2 dw 8 dup(?)
	temp3 dw 8 dup(?)
	
	tempIDCT1 dw 64 dup(?) ; used for interim matrices during the calculation of the IDCT
	tempIDCT2 dw 64 dup(?)
	
.CODE

; Calculates the inverse discrete cosine transform of an MDU.
; The IDCT is applied to each block in the MDU
; Argument on the stack:
; Argument 1 = segment address of MDU (MDU contians words)
; Argument 2 = offset address of MDU
iDCT PROC FAR
	push bp
	mov bp, sp

	push ax
	push cx
	push dx

	xor cx, cx ; counter loop
@@:
	mov dx, [bp + 6][2]
	push dx
	mov dx, [bp + 6][0]
	mov ax, 128 ; 64 words per matrix
	push dx 	; save dx for multiplication operation
	mul cx
	pop dx
	add dx, ax ; add offset according to current count index
	push dx 	
	mov dx, [bp + 6][2] ; 3th and 4th argument are the same as first and second
	push dx
	mov dx, [bp + 6][0]
	mov ax, 128 ; 64 words per matrix
	push dx 	; save dx for multiplication operation
	mul cx
	pop dx
	add dx, ax ; add offset according to current count index
	push dx
	call iDCT_Block
	inc cx
	cmp cx, 6
	jne @B

	pop dx
	pop cx
	pop ax

	mov sp, bp
	pop bp
	ret 4
iDCT ENDP

; Calculates the inverse discrete cosine transform of an 8x8 matrix
; Arguments on the stack:
; Argument 1 = segment address of data
; Argument 2 = offset address of data
; Argument 3 = segment address for output
; Argument 4 = offset address for output
; Note: It is possible that input and output point to the same data segment
iDCT_Block PROC FAR
	push bp
	mov bp, sp

	push ax
	
	mov ax, [bp +6][6] ; first argument
	push ax
	mov ax, [bp + 6][4] ; second argument
	push ax
	mov ax, seg tempIDCT1
	push ax
	mov ax, offset tempIDCT1
	push ax
	call iDCT_Bink
	
	mov ax, seg tempIDCT1
	push ax
	mov ax, offset tempIDCT1
	push ax
	mov ax, seg tempIDCT2
	push ax
	mov ax, offset tempIDCT2
	push ax
	call MatrixTranspose
	
	mov ax, seg tempIDCT2
	push ax
	mov ax, offset tempIDCT2
	push ax
	mov ax, seg tempIDCT1
	push ax
	mov ax, offset tempIDCT1
	push ax
	call iDCT_Bink
	
	mov ax, seg tempIDCT1
	push ax
	mov ax, offset tempIDCT1
	push ax
	mov ax, [bp + 6][2]
	push ax
	mov ax, [bp + 6][0]
	push ax
	call MatrixTranspose
	
	mov ax, [bp + 6][2]
	push ax
	mov ax, [bp + 6][0]
	push ax
	call MatrixScale

	pop ax
	
	mov sp, bp 
	pop bp
	ret 8
iDCT_Block ENDP

; Calculates the bink inverse discrete cosine transform of one block.
; Arguments on the stack: 
; Argument 1 = segment address of data
; Argument 2 = offset address of data
; Argument 3 = segment address for output
; Argument 4 = offset address for output
iDCT_Bink PROC NEAR
	push bp
	mov bp, sp

	push ax ; Save registers
	push bx
	push cx
	push dx

	; set data segment and source index register to data source
	mov ds, [bp + 4][6] ; first argument
	mov si, [bp + 4][4] ; second argument
	
	; set extra segment to current data segment
	mov ax, seg c0
	mov es, ax
	; set direction flag
	; xor df, df ; TODO : is dit echt nodig ? 
	
	; Initialize current data segment
	; -----------------------------------
	
	; initialize c0 -> set destination index register
	mov di, offset c0
	mov cx, 8
	rep movsw ; si and di are automatically incrementend (see: direction flag)
	
	; initialize d4
	mov di, offset d4
	mov cx, 8
	rep movsw ; si and di are automatically incrementend (see: direction flag)
	
	
	; initialize c2
	mov di, offset c2
	mov cx, 8
	rep movsw ; si and di are automatically incrementend (see: direction flag)
	
	
	; initialize d6
	mov di, offset d6
	mov cx, 8
	rep movsw ; si and di are automatically incrementend (see: direction flag)
	
	
	; initialize c1
	mov di, offset c1
	mov cx, 8
	rep movsw ; si and di are automatically incrementend (see: direction flag)
	
	; initialize d5
	mov di, offset d5
	mov cx, 8
	rep movsw ; si and di are automatically incrementend (see: direction flag)
	
	
	; initialize c3
	mov di, offset c3
	mov cx, 8
	rep movsw ; si and di are automatically incrementend (see: direction flag)
	
	; initialize d7
	mov di, offset d7
	mov cx, 8
	rep movsw ; si and di are automatically incrementend (see: direction flag)
	
	; Start calculations
	; --------------------
	mov ax, seg c0
	mov ds, ax	; set ds-segment also to current data segment
	
	
	; calculate c4: c4 = d4
	mov si, offset d4
	mov di, offset c4
	mov cx, 8
	rep movsw
	
	; calculate c5: c5 = d5 + d6
	mov ax, offset d5
	push ax
	mov ax, offset d6
	push ax
	mov ax, offset c5
	push ax
	call ArrayADD
	
	
	; calculate c7: d5 - d6
	mov ax, offset d5
	push ax
	mov ax, offset d6
	push ax
	mov ax, offset c7
	push ax
	call ArraySUB

	
	; calculate c6: c6 = d7
	mov si, offset d7
	mov di, offset c6
	mov cx, 8
	rep movsw
	
	; caculate B-arrays
	; ---------------------
	
	; calculate b4: b4 = c4 + c5
	mov ax, offset c4
	push ax
	mov ax, offset c5
	push ax
	mov ax, offset b4
	push ax
	call ArrayADD
	
	; calculate b5: b5 = c4 - c5
	mov ax, offset c4
	push ax
	mov ax, offset c5
	push ax
	mov ax, offset b5
	push ax
	call ArraySUB
	
	; calculate b6: b6 = c6 + c7
	mov ax, offset c6
	push ax
	mov ax, offset c7
	push ax
	mov ax, offset b6
	push ax
	call ArrayADD
	
	; calculate b7: b7 = c6 - c7
	mov ax, offset c6
	push ax
	mov ax, offset c7
	push ax
	mov ax, offset b7
	push ax
	call ArraySUB
	
	; calculate b0: b0 = c0 + c1
	mov ax, offset c0
	push ax
	mov ax, offset c1
	push ax
	mov ax, offset b0
	push ax
	call ArrayADD
	
	; calculate b1: b1 = c0 - c1
	mov ax, offset c0
	push ax
	mov ax, offset c1
	push ax
	mov ax, offset b1
	push ax
	call ArraySUB
	
	; calculate b2: b2 = c2 + c2/4 + c3/2
	mov ax, offset c2
	push ax
	mov ax, 2 ; Division by 4: 2 bit shifts
	push ax
	mov ax, offset temp1
	push ax
	call ArraySAR	
	mov ax, offset c2
	push ax
	mov ax, offset temp1 ; result of calculation: c2/4
	push ax
	mov ax, offset temp2
	push ax
	call ArrayADD
	mov ax, offset c3
	push ax
	mov ax, 1 ; Division by 2: 1 bit shift
	push ax
	mov ax, offset temp1
	push ax
	call ArraySAR
	mov ax, offset temp2 ; result of calculation: c2 + c2/4
	push ax
	mov ax, offset temp1 ; result of calculation: c3/2
	push ax
	mov ax, offset b2
	push ax
	call ArrayADD
	
	
	; calculate b3: b3 = c2/2 - c3 - c3/4
	mov ax, offset c2
	push ax
	mov ax, 1 ; Division by 2: 1 bit shift
	push ax
	mov ax, offset temp1
	push ax
	call ArraySAR
	mov ax, offset temp1 ; result of calculation: c2/2
	push ax
	mov ax, offset c3
	push ax
	mov ax, offset temp2
	push ax
	call ArraySUB
	mov ax, offset c3
	push ax
	mov ax, 2 ; Division by 4: 2 bit shifts
	push ax
	mov ax, offset temp1
	push ax
	call ArraySAR
	mov ax, offset temp2 ; result of calculation: c2/2 - c3
	push ax
	mov ax, offset temp1 ; result of calculation: c3/4
	push ax
	mov ax, offset b3
	push ax
	call ArraySUB
	
	
	; calculate A-arrays
	; ---------------------
	
	; calculate a4: a4 = b7/4 + b4 + b4/4 - b4/16
	mov ax, offset b7
	push ax
	mov ax, 2 ; Division by 4: 2 bit shifts
	push ax
	mov ax, offset temp1
	push ax
	call ArraySAR
	mov ax, offset temp1 ; result of calculation: b7/4
	push ax
	mov ax, offset b4
	push ax
	mov ax, offset temp2
	push ax
	call ArrayADD
	mov ax, offset b4
	push ax
	mov ax, 2 ; Division by 4: 2 bit shifts
	push ax
	mov ax, offset temp3
	push ax
	call ArraySAR
	mov ax, offset temp2 ; result of calculation: b7/4 + b4
	push ax
	mov ax, offset temp3 ; result of calculation: b4/4
	push ax
	mov ax, offset temp1
	push ax
	call ArrayADD
	mov ax, offset b4
	push ax
	mov ax, offset 4 ; Division by 16: 4 bit shifts
	push ax
	mov ax, offset temp2
	push ax
	call ArraySAR
	mov ax, offset temp1 ; result of calculation: b7/4 + b4 + b4/4
	push ax
	mov ax, offset temp2 ; result of calculation: b4/16
	push ax
	mov ax, offset a4
	push ax
	call ArraySUB
	
	; calculate a7: a7 = b4/4 - b7 - b7/4 + b7/16
	mov ax, offset b4
	push ax
	mov ax, 2 ; Divsion by 4: 2 bit shifts
	push ax
	mov ax, offset temp1
	push ax
	call ArraySAR
	mov ax, offset temp1 ; result of calculation: b4/4
	push ax
	mov ax, offset b7
	push ax
	mov ax, offset temp2
	push ax
	call ArraySUB
	mov ax, offset b7
	push ax
	mov ax, 2 ; Division by 4: 2 bit shifts
	push ax
	mov ax, offset temp1
	push ax
	call ArraySAR
	mov ax, offset temp2 ; result of calculation: b4/4 - b7
	push ax
	mov ax, offset temp1 ; result of calculation: b7/4
	push ax
	mov ax, offset temp3
	push ax
	call ArraySUB
	mov ax, offset b7
	push ax
	mov ax, 4 ; Division by 16: 4 bit shifts
	push ax
	mov ax, offset temp1
	push ax
	call ArraySAR
	mov ax, offset temp3 ; result of calculation: b4/4 - b7 - b7/4
	push ax
	mov ax, offset temp1 ; result of calculation: b7/16
	push ax
	mov ax, offset a7
	push ax
	call ArrayADD
	
	; calculate a5: a5 = b5 - b6 + b6/4 + b6/16
	mov ax, offset b5
	push ax
	mov ax, offset b6
	push ax
	mov ax, offset temp1
	push ax
	call ArraySUB
	mov ax, offset b6
	push ax
	mov ax, 2 ; Division by 4: 2 bit shifts
	push ax
	mov ax, offset temp2
	push ax
	call ArraySAR
	mov ax, offset temp1 ; result of calculation: b5 - b6
	push ax
	mov ax, offset temp2 ; result of calculation: b6/4
	push ax
	mov ax, offset temp3
	push ax
	call ArrayADD
	mov ax, offset b6
	push ax
	mov ax, 4 ; Division by 16: 4 bit shifts
	push ax
	mov ax, offset temp1
	push ax
	call ArraySAR
	mov ax, offset temp3 ; result of calculation: b5 - b6 + b6/4
	push ax
	mov ax, offset temp1 ; result of calculation: b6/16
	push ax
	mov ax, offset a5
	push ax
	call ArrayADD
	
	; calculate a6: a6 = b6 + b5 - b5/4 - b5/16
	mov ax, offset b6
	push ax
	mov ax, offset b5
	push ax
	mov ax, offset temp1
	push ax
	call ArrayADD
	mov ax, offset b5
	push ax
	mov ax, 2 ; Division by 4: 2 bit shifts
	push ax
	mov ax, offset temp2
	push ax
	call ArraySAR
	mov ax, offset temp1 ; result of calculation: b6 + b5
	push ax
	mov ax, offset temp2 ; result of calculation: b5/4
	push ax
	mov ax, offset temp3
	push ax
	call ArraySUB
	mov ax, offset b5
	push ax
	mov ax, 4 ; Division by 16: 4 bit shifts
	push ax
	mov ax, offset temp1
	push ax
	call ArraySAR
	mov ax, offset temp3 ; result of calculation: b6 + b5 - b5/4
	push ax
	mov ax, offset temp1 ; result of calculation: b5/16
	push ax
	mov ax, offset a6
	push ax
	call ArraySUB
	
	; calculate a0: a0 = b0 + b2
	mov ax, offset b0
	push ax
	mov ax, offset b2
	push ax
	mov ax, offset a0
	push ax
	call ArrayADD
	
	; calculate a1: a1 = b1 + b3
	mov ax, offset b1
	push ax
	mov ax, offset b3
	push ax
	mov ax, offset a1
	push ax
	call ArrayADD
	
	; calculate a2: a2 = b1 - b3
	mov ax, offset b1
	push ax
	mov ax, offset b3
	push ax
	mov ax, offset a2
	push ax
	call ArraySUB
	
	; calculate a3: a3 = b0 - b2
	mov ax, offset b0
	push ax
	mov ax, offset b2
	push ax
	mov ax, offset a3
	push ax
	call ArraySUB
	
	; calculate output
	; output = [o0; o1; o2; o3; o4; o5; o6; o7] 
	; with   o0 = a0 + a4;
	; o1 = a1 + a5;
    ; o2 = a2 + a6;
    ; o3 = a3 + a7;
    ; o4 = a3 - a7;
    ; o5 = a2 - a6;
    ; o6 = a1 - a5;
    ; o7 = a0 - a4;
	; ---------------------
	mov es, [bp + 4][2] ; third argument
	; calculate o0: o0 = a0 + a4
	mov ax, offset a0
	push ax
	mov ax, offset a4
	push ax
	mov ax, [bp + 4][0] ; last argument on the stack
	push ax
	call ArrayADD
	; calculate o1: o1 = a1 + a5
	mov ax, offset a1
	push ax
	mov ax, offset a5
	push ax
	mov ax, [bp + 4][0]
	add ax, 16 ; offset is 8 words further
	push ax
	call ArrayADD
	
	; calculate o2: o2 = a2 + a6
	mov ax, offset a2
	push ax
	mov ax, offset a6
	push ax
	mov ax, [bp + 4][0]
	add ax, 32 ; offset is 16 words further
	push ax
	call ArrayADD
	
	; calculate o3: o3 = a3 + a7
	mov ax, offset a3
	push ax
	mov ax, offset a7
	push ax
	mov ax, [bp + 4][0]
	add ax, 48 ; offset is 24 words further
	push ax
	call ArrayADD
	
	; calculate o4: o4 = a3 - a7
	mov ax, offset a3
	push ax
	mov ax, offset a7
	push ax
	mov ax, [bp + 4][0]
	add ax, 64 ; offset is 32 words further
	push ax
	call ArraySUB
	
	; calculate o5: o5 = a2 - a6
	mov ax, offset a2
	push ax
	mov ax, offset a6
	push ax
	mov ax, [bp + 4][0]
	add ax, 80 ; offset is 40 words further
	push ax
	call ArraySUB
	
	; calculate o6: o6 = a1 - a5
	mov ax, offset a1
	push ax
	mov ax, offset a5
	push ax
	mov ax, [bp + 4][0]
	add ax, 96 ; offset is 48 words further
	push ax
	call ArraySUB
	
	; calculate o7: o7 = a0 - a4	
	mov ax, offset a0
	push ax
	mov ax, offset a4
	push ax
	mov ax, [bp + 4][0]
	add ax, 112 ; offset is 56 words further
	push ax
	call ArraySUB

	pop dx
	pop cx
	pop bx
	pop ax
	
	mov sp, bp
	pop bp
	ret 8 ; four word arguments  on the stack
iDCT_Bink ENDP

; Calculates the result of a elemtwise addition of two arrays for length 8
; Arguments on the stack: 
; Argument 1 = offset address of first operand array
; Argument 2 = offset address of second operand array
; Argument 3 = offset address of result array
; Note: all offset addresses are supposed to be in het current data segment and ds and es are already set to the correct segment
ArrayADD PROC FAR
	push bp
	mov bp, sp
	
	; calculate C = A + B
	mov di, [bp + 6][0] ; last argument: offset result array
	mov cx, 8
	mov bx, 0 ; contains the index of the current element in the array (offset in bytes, array in words)
@@:
	mov si, [bp + 6][4] ; first argument: offset first array
	add si, bx
	lodsw
	push ax ; save element of first array on the stack
	
	mov si, [bp + 6][2] ; second argument: offset second array
	add si, bx
	lodsw
	pop dx
	add ax, dx
	stosw ; store result of ax in es:di and increments di
	inc bx
	inc bx ; increment one word, so 2 bytes
	loop @B
	
	mov sp, bp
	pop bp
	ret 6 
ArrayADD ENDP

; Calculates the result of a elemtwise substraction of two arrays for length 8
; Arguments on the stack: 
; Argument 1 = offset address of first operand array
; Argument 2 = offset address of second operand array
; Argument 3 = offset address of result array
; Result Array = First Array - Second Array
; Note: all offset addresses are supposed to be in het current data segment and ds and es are already set to the same correct segment
ArraySUB PROC FAR
	push bp
	mov bp, sp
	
	mov di, [bp + 6][0] ; last argument: offset result array
	mov cx, 8
	mov bx, 0 ; contains the index of the current element in the array (offset in bytes, array in words)
@@:
	mov si, [bp + 6][2] ; first argument: offset second array
	add si, bx
	lodsw
	push ax ; save element of first array on the stack
	
	mov si, [bp + 6][4] ; second argument: offset first array
	add si, bx
	lodsw
	pop dx
	sub ax, dx
	stosw ; store result of ax in es:di and increments di
	inc bx
	inc bx ; increment one word, so 2 bytes
	loop @B
	
	mov sp, bp
	pop bp
	ret 6 
ArraySUB ENDP

; Calculates the result of a elemtwise SAR of an array of length 8
; Arguments on the stack: 
; Argument 1 = offset address of operand array
; Argument 2 = Total number of bit shifts (> 0)
; Argument 3 = offset address of result array
; Note: all offset addresses are supposed to be in het current data segment and ds and es are already set to the same correct segment
ArraySAR PROC FAR
	push bp
	mov bp, sp
	
	mov si, [bp + 6][4]
	mov di, [bp + 6][0]
	mov cl, [bp + 6][2]
	mov ch, 8
ForLoop:
	lodsw
	sar ax, cl ; quantity has to be specificied in cl
	stosw
	dec ch
	cmp ch, 0
	je EndForLoop
	jmp ForLoop

EndForLoop:
	mov sp, bp
	pop bp
	ret 6
ArraySAR ENDP

; Calculates the transpose of a matrix. Input is a array of length 64. The rows are sequential stored.
; Arguments on the stack: 
; Argument 1 = segment of input matrix
; Argument 2 = offset of input matrix
; Argument 3 = segment of output matrix
; Argument 4 = offset of output matrix
MatrixTranspose PROC FAR
	push bp
	mov bp, sp

	push ax
	push bx
	push cx
	push dx
	push ds
	push es

	mov ds, [bp + 6][6] ; First Argument
	mov si, [bp + 6][4] ; Second argument
	mov es, [bp + 6][2] ; Third Argument
	; mov di, [bp + 4][0] ; Last Argument -> overbodige instructie, moet toch elke keer in de for-loop gebeuren
	xor cx, cx
	
	; C++ Code
	;	for (int i = 0; i < 64; i++) {
	;	output[(i % 8)*8 + i / 8] = input[i];
	;}

@@:
	xor dx,dx
	mov ax, cx
	
	mov bx, 8
	div bx ; result of calculation: AX = DX:AX / Op, rest in DX
	push ax ; save register ax
	mov ax, dx
	mov dx, 8
	mul dx ; result of calculation: DX:AX = AX*Op
	mov dx, ax
	pop ax ; restore register ax
	add ax, dx ; Dest = Dest + Source
	mov dx, 2
	mul dx ; result of calculation: DX:AX = AX*Op -> because data are words (2x bytes)
	mov di, [bp + 6][0]
	add di, ax ; calculate offset address
	movsw
	
	inc cx
	cmp cx, 64
	jne @B
	
	pop es
	pop ds
	pop dx
	pop cx
	pop bx
	pop ax

	mov sp, bp
	pop bp
	ret 8
MatrixTranspose ENDP

; Scales the matrix with a factor 8 so that the inverse discrete cosine transform the same is as the 
; proper orthogonal transform IDCT-II. Shifts all the values with +128 and makes sure that each entry
; is in the range [0, 255]
; Arguments on the stack: 
; Argument 1 = segment of matrix (data are words)
; Argument 2 = offset of matrix
MatrixScale PROC FAR
	push bp
	mov bp, sp

	push ax
	push bx
	push cx
	push dx
	push ds
	push es
	
	mov ds, [bp + 6][2]
	mov si, [bp + 6][0]
	mov es, [bp + 6][2] ; desitnation is the same as the source
	mov di, si
	cld

	mov cx, 64
	xor dx, dx
Start_Loop:
	lodsw
	mov bx, 8 ; the scale factor is 8
	cwd		; sign extend to DX:AX (32-bit)
	idiv bx ; result of calculation: AX = DX:AX / Op
	add ax, 128
	
	; check boundary 255
	cmp ax, 255
	jle @F ; jump to forward label
	mov ax, 255
	; check boundary 0
@@:
	cmp ax, 0
	jge @F
	mov ax, 0
@@:
	stosw
	loop Start_Loop

	pop es
	pop ds
	pop dx
	pop cx
	pop bx
	pop ax
	
	mov sp, bp
	pop bp
	ret 4
MatrixScale ENDP


END