.MODEL large

include HELPERS.INC
include SHOW.INC

.DATA
	public RGBPalette ; For testing purposes
	RGBPalette db 756 dup(?) ; 252 colors
	
	public channel1, channel2, channel3
	channel1 db 256 dup(?) ; Used for Y and R values
	channel2 db 256 dup(?) ; Used for U(Cb) and G values
	channel3 db 256 dup(?) ; Used for V(Cr) and B values
	channel4 db 256 dup(?) ; Used for the index in the palette

	oldVideoMode db ?

.FARDATA?
	screenBuffer	db 64000 dup(?)	; the 64000 bytes for the screen

.CODE

; Function that shows the image in RGB-space in 256 colors on the screen
; Arguments on the stack:
; Argument 1 = segment address of MDU (MDU continas words)
; Argument 2 = offset address of MDU
; Argument 3 = MDU number
; The MDU contains data that is transformed with the IDCT.  The steps that need to be performed:
; apply upsampling on the MDU, calculate a color index from the YUV values, write the output to the sreen.
showImage PROC FAR
	push bp
	mov bp, sp
	
	mov ax, [bp + 6][4]
	push ax
	mov ax, [bp + 6][2]
	push ax
	call UpSampling

	call setPalette

	call changeColorSpace
	
 	call calcChannel4

 	mov ax, [bp + 6][0]
 	push ax
	call WriteToScreenBuffer
		
	mov sp, bp
	pop bp
	ret 6
showImage ENDP

; Gets an offset to one MDU as input address and puts the corresponding Y, Cb, Cr data 
; in channel1, channel2, channel3
; Arguments on the stack:
; Argument 1 = segment address of MDU
; Argument 2 = offset address of MDU
UpSampling PROC FAR
	push bp
	mov bp, sp
	
	mov ax, [bp + 6][2]
	push ax
	mov ax, [bp + 6][0]
	push ax
	call UpSamplingY
	
	; UpSampling of Cb
	mov ax, [bp + 6][2]
	push ax
	mov ax, [bp + 6][0]
	add ax, 512 ; We need the 5-th matrix in the MDU (512 = 4 * 64 * 2)
	push ax
	mov ax, seg channel2
	push ax
	mov ax, offset channel2
	push ax
	call ProcessBlockC
	
	; UpSampling of Cr
	mov ax, [bp + 6][2]
	push ax
	mov ax, [bp + 6][0]
	add ax, 640 ; We need the 6-th matrix in the MDU (650 = 5 * 64 * 2)
	push ax
	mov ax, seg channel3
	push ax
	mov ax, offset channel3
	push ax
	call ProcessBlockC
	
	mov sp, bp
	pop bp
	ret 4
UpSampling ENDP

; Arguments on the stack
; Argument 1 = segment address of MDU
; Argument 2 = offset address of MDU
UpSamplingY PROC FAR
	push bp
	mov bp, sp
			
	mov ax, [bp + 6][2]
	push ax
	mov ax, [bp + 6][0]
	push ax
	mov ax, 0
	push ax
	call ProcBlockY 
	
	mov ax, [bp + 6][2]
	push ax
	mov ax, [bp + 6][0]
	add ax, 128 ; Second matrix of 8x8 values (64 words further)
	push ax
	mov ax, 8
	push ax
	call ProcBlockY 
	
	mov ax, [bp + 6][2]
	push ax
	mov ax, [bp + 6][0]
	add ax, 256 ; Third matrix of 8x8 values (128 words further)
	push ax
	mov ax, 128
	push ax
	call ProcBlockY 
	
	mov ax, [bp + 6][2]
	push ax
	mov ax, [bp + 6][0]
	add ax, 384 ; Fourth matrix of 8x8 values (192 words further)
	push ax
	mov ax, 136
	push ax
	call ProcBlockY 
	
	
	mov sp, bp
	pop bp
	ret 4
UpSamplingY ENDP

; Arguments on the stack
; Argument 1 = seg of input and output (should be in the same segment)
; Argument 2 = offset of input MDU (start of current Y-block)
; Argument 3 = offset in channel1 (offset for current 8x8 block: possible values for offset are 0, 8, 128, 136)
ProcBlockY PROC FAR
	push bp
	mov bp, sp

	push ax
	push bx
	push cx
	push dx

	; Equivalent C++ Code
	;	for (int i = 0; i < 8; i++) {
	;		for (int j = 0; j < 8; j++) {
	;			output[offset] = input[i*8 + j];
	;			offset++;
	;	}
	;	offset = offset + 8;
	;}
	
	mov ds, [bp + 6][4]
	mov es, [bp + 6][4]

	mov ax, [bp + 6][0]
	add ax, offset channel1
	mov di, ax
	
	xor cx, cx ; counter outer for loop
@Outer:
	push cx ; save counter outer for loop
	xor cx, cx ; counter inner for loop
@Inner:	
	mov ax, [bp - 10] ; Counter outer for loop in ax
	mov bx, 8
	mul bx 			; ax = i * 8
	add ax, cx       ; ax = i *8 + j
	mov bx, 2
	mul bx			; ax = 2 * (i * 8 + j) (Data are words)
	mov bx, [bp + 6][2]
	add ax, bx		; ax = [i * 8 + j]
	mov si, ax
	lodsw 
	stosb
	; End of inner loop
	inc cx
	cmp cx, 8
	jne @Inner
	; End of outer loop
	pop cx
	add di, 8
	inc cx
	cmp cx, 8
	jne @Outer

	pop dx
	pop cx
	pop bx
	pop ax

	mov sp, bp
	pop bp
	ret 6
ProcBlockY ENDP

; Copies the content of the data in the MDU to the Chromium output stream by converting
; the 8x8 block to a 16x16 block.
; Arguments on the stack
; Argument 1 = segment of input Chromium stream
; Argument 2 = offset in input Chromium stream
; Argument 3 = segment of Chromium output stream
; Argument 4 = offset in Chromium output stream
ProcessBlockC PROC FAR
	push bp
	mov bp, sp
	
	push ax
	push cx
	
	mov ds, [bp + 6][6]
	mov si, [bp + 6][4]
	
	mov es, [bp + 6][2]
	mov di, [bp + 6][0]

	mov cx, 8 ; counter outer for-loop
Start_Loop:
	push cx
	mov cx, 8 ; counter inner for-loop
@@: ; inner loop
	lodsw
	stosb
	stosb
	add di, 14
	stosb
	stosb
	sub di, 16
	loop @B
	add di, 16 ; jump one row further in output segment
	pop cx
	loop Start_Loop
	
	pop cx
	pop ax
	
	mov sp, bp
	pop bp
	ret 8
ProcessBlockC ENDP

; Procedure that writes the content of channel 4 in the screenBuffer.
; Arguments on the stack:
; Argument 1 = MDU number (zero-based)
WriteToScreenBuffer PROC FAR
	push bp
	mov bp, sp

	push ax
	push bx
	push cx
	push dx

	; Calculate offset in screenBuffer	
	mov ax, [bp + 6][0]
	mov bx, 20 ; 20 MDU per row
	xor dx, dx
	div bx ; AX = DX:AX / Op & DX = Rest
	push dx ; Save rest 
	mov bx, 256
	mul bx ; AX = Quotient * 256
	mov bx, 20
	mul bx ; AX = Quotient * 256 * 20 
	pop dx ; restore rest
	push ax ; save the first part of the offset
	mov ax, dx ; Rest in ax
	mov bx, 16
	mul bx ; AX = 16 * rest
	mov dx, ax
	pop ax
	add ax, dx ; The total offset in ax

	; Set up ds and es registers
	mov bx, seg screenBuffer
	mov es, bx
	mov di, offset screenBuffer
	add di, ax

	mov ax, seg channel4
	mov ds, ax
	mov si, offset channel4

	mov cx, 16 ; 16 rows
ForLoop:
	push cx
	mov cx, 16 ; 16 columns
	rep movsb
	pop cx
	add di, 304 ; 304 = 16px * 19
	loop ForLoop

	pop dx
	pop cx
	pop bx
	pop ax

	mov sp, bp
	pop bp
	ret 2
WriteToScreenBuffer ENDP

; Converts the values of YUV (YCbCr) to RGB
; No arguments on the stack
; The input values are overriden by the output values
changeColorSpace PROC FAR
	push bp
	mov bp, sp

	push ax
	push bx
	push cx
	push dx
	
	; Formula for calculation RGB from YCbCr-values
	; R = Y 									+ 1.402 ( Cr - 128)
	; G = Y 	- 0.34414 ( Cb - 128 )			- 0.71414 ( Cr - 128 )
	; B = Y 	+ 1.772 ( Cb - 128 )
	
	; For precision we use following version 
	; (the numbers are then rounded to their nearest integers):
	; 100*R = 100 * Y 							+ 140 ( Cr - 128)
	; 100*G = 100 * Y 	- 34 ( Cb - 128 )		- 71 ( Cr - 128 )
	; 100*B = 100 * Y 	+ 177 ( Cb - 128 )
	mov ax, seg channel1
	mov es, ax
	mov ds, ax
	xor cx, cx ; Counter: 0 -> 256
ForLoop:	
	; Load current Y, Cb and Cr value on the stack 
	mov si, offset channel1 ; Y
	add si, cx
	xor ah, ah
	mov al, ds:[si]
	push ax

	mov si, offset channel2 ; Cb
	add si, cx
	xor ah, ah
	mov al, ds:[si]
	push ax

	mov si, offset channel3 ; Cr
	add si, cx
	xor ah, ah
	mov al, ds:[si]
	push ax

	; calculate R: 100 * R = 100 * Y + 140 ( Cr - 128)
	mov ax, [bp - 10] 		; AX = Y
	mov dx, 100
	mul dx ; result of calculation: DX:AX = AX * Op = 100 * Y
	push ax
	mov ax, [bp - 14]		; AX = Cr
	sub ax, 128				; AX = Cr - 128
	mov dx, 140	
	mul dx					; AX = 140 * ( Cr - 128 )
	mov dx, ax 				; DX = 140 * ( Cr - 128 )
	pop ax 					; AX = 100 * Y
	add ax, dx				; AX = 100 * Y + 140 ( Cr - 128)
	xor dx, dx
	mov bx, 100
	div bx
	mov di, offset channel1
	add di, cx
	xor ah, ah
	mov es:[di], al			; Save R-value
	mov bx, 1
	cmp bx, bx ; Set zero flag (see label: Intermediate)
Intermediate:
	jne ForLoop ; intermediate label because the for-loop contains to many instructions

	; calculate G: 100*G = 100 * Y - 34 ( Cb - 128 ) - 71 ( Cr - 128 )
	mov ax, [bp - 10] 		; AX = Y
	mov dx, 100
	mul dx					; AX = 100 * Y
	push ax
	mov ax, [bp - 14]		; AX = Cr
	sub ax, 128				; AX = Cr - 128
	mov dx, 71
	mul dx					; AX = 71 * ( Cr - 128 )
	pop dx
	sub dx, ax				; DX = 100 * Y - 71 * ( Cr - 128)
	push dx
	mov ax, [bp - 12]		; AX = Cb
	sub ax, 128				; AX = Cb - 128
	mov dx, 34
	mul dx					; AX = 34 * ( Cb - 128 )
	mov dx, ax				; DX = 39 * ( Cb - 128 )
	pop ax
	sub ax, dx				; AX = 100 * ( Y - 16 ) - 71 * ( Cr - 128) - 34 * ( Cb - 128 )
	xor dx, dx
	mov bx, 100
	div bx
	mov di, offset channel2
	add di, cx
	xor ah, ah
	mov es:[di], al 		; Save G-value
	
	; calculate B: 100*B = 100 * Y 	+ 177 ( Cb - 128 )
	mov ax, [bp - 10] 		; AX = Y
	mov dx, 100
	mul dx 					; AX = 100 * Y
	push ax
	mov ax, [bp - 12] 		; AX = Cb
	sub ax, 128				; AX = Cb - 128
	mov dx, 177
	mul dx					; AX = 177 * ( Cb - 128 )
	pop dx
	add ax, dx				; DX = 100 * Y + 177 * ( Cb - 128 )
	xor dx, dx
	mov bx, 100
	div bx
	mov di, offset channel3
	add di, cx
	xor ah, ah
	mov es:[di], al 		; Save B-value

	pop ax ; Remove 3 initial values on the stack at beginning for loop
	pop ax
	pop ax

	inc cx
	cmp cx, 256
	jne Intermediate
	
	pop dx
	pop cx
	pop bx
	pop ax
		
	mov sp, bp
	pop bp
	ret 0
changeColorSpace ENDP

; Procedure that is used while tranforming the color space. 
clipValue PROC NEAR

clipValue ENDP


; Initializes the palette with 252 colors (in total 756 bytes)
; No arguments on the stack
setPalette PROC FAR
	push bp
	mov bp, sp

	push ax
	push bx
	push cx
	push dx
	
	; Equivalent C++ Code:
	; for (int r = 0; r <= 60; r = r + 12) {
		; for (int g = 0; g <= 60; g = g + 12) {
			; for (int b = 0; b <= 60; b = b + 10) {
				; // In total: 6*6*7 = 252 colors

				; std::cout << "RGB = " << r << " " << g << " " << b << std::endl;
			; }
		; }
	; }
	
	mov ax, seg RGBPalette
	mov es, ax
	mov di, offset RGBPalette
	
	mov bx, 0 	; Counter First loop
@1:
	xor cx, cx
@2:
	mov dx, 0		; Counter Third loop
@3:
	; Calculate and Save R-value
	mov ax, bx
	stosb
	; Calculate and Save G-value
	mov ax, cx
	stosb
	; Calculate and Save B-value
	mov ax, dx
	stosb
	; Termination of most inner loop
	add dx, 10
	cmp dx, 70
	jne @3
	; Termination of midle loop
	add cx, 12
	cmp cx, 72
	jne @2
	; Termination of outer loop
	add bx, 12
	cmp bx, 72
	jne @1

	pop dx
	pop cx
	pop bx
	pop ax
	
	mov sp, bp
	pop bp
	ret 0
setPalette ENDP

; Procedure that Initializes the screenbuffer with zeros.
; No arguments on the stack.
ClearScreenBuffer PROC FAR
	push bp
	mov bp, sp

	push ax
	push cx
	push es
	push di

	mov ax, seg screenBuffer
	mov es, ax
	mov di, offset screenBuffer
	mov cx, 32000
	xor ax, ax
	rep stosw

	pop di
	pop es
	pop cx
	pop ax

	mov sp, bp
	pop bp
	ret 0
ClearScreenBuffer ENDP

; Procedures that writes the screenbuffer to the graphics memory.
; No arguments on the stack.
RenderScreen PROC FAR
	push bp
	mov bp, sp

	push ax
	push bx
	push cx

	; Set the video mode
	mov ax, 13h
	xor ah, ah
	push ax
	call setVideoMode
	mov bx, seg oldVideoMode
	mov es, bx
	mov di, offset oldVideoMode
	mov es:[di], al


	; Set the palette
	mov ax, seg RGBPalette
	mov ds, ax
	mov es, ax
	mov dx, offset RGBPalette
	xor bx, bx
	mov cx, 252 ; 252 colors
	mov ax, 1012h
	int 10h

	; Copy data of screenbuffer in the graphics memory
	; TODO this is depending on the MDU number
	mov ax, seg screenBuffer
	mov ds, ax
	mov si, offset screenBuffer
	mov ax, 0a000h
	mov es, ax
	mov di, 0
	mov cx, 64000
	rep movsb

	pop cx
	pop bx
	pop ax

	mov sp, bp
	pop bp
	ret 0 
RenderScreen ENDP

; Restores the screen back to normal text mode.
; No arguments on the stack.
RestoreScreen PROC FAR
	push bp
	mov bp, sp

	mov ax, seg oldVideoMode
	mov ds, ax
	mov si, offset oldVideoMode
	mov al, ds:[si]
	xor ah, ah
	push ax
	call setVideoMode	

	mov sp, bp
	pop bp
	ret 0
RestoreScreen ENDP

; Set the video mode and returns the previous mode in AL.
setVideoMode PROC NEAR
	push	bp				; save dynamic link
	mov		bp, sp			; update bp
	push	bx
	
	mov		ah, 0fh			; get current video mode in al
	int		10h
	
	mov		bx, ax
	
	mov		ax, [bp + 4][0]	; get requested mode
	xor		ah, ah			; function 0
	int		10h
	
	mov		ax, bx
	
	pop		bx
	pop		bp	
	ret	2				; return
setVideoMode ENDP

; Procedure that calculates the color indexes of RGB-values in the palette.
; The result is stored in channel 4.
; No arguments on the stack
calcChannel4 PROC FAR
	push bp
	mov bp, sp

	push ax
	push bx
	push cx

	mov ax, seg channel4
	mov es, ax
	mov ds, ax
	mov di, offset channel4
	xor cx, cx ; Counter: 0 -> 256
ForLoop:	
	; Load current Y, Cb and Cr value on the stack 
	mov si, offset channel1 ; Y
	add si, cx
	xor ah, ah
	mov al, ds:[si]
	push ax

	mov si, offset channel2 ; Cb
	add si, cx
	xor ah, ah
	mov al, ds:[si]
	push ax

	mov si, offset channel3 ; Cr
	add si, cx
	xor ah, ah
	mov al, ds:[si]
	push ax

	call findClosestColorIndex
	stosb

	inc cx
	cmp cx, 256
	jne ForLoop
	
	pop cx
	pop bx
	pop ax

	mov sp, bp
	pop bp
	ret 0
calcChannel4 ENDP


; Returns the index in ax of the 8-bit color in the palette that is the 
; closest to the specified RGB-values. The index is zero based.
; Arguments on the stack:
; Argument 1 = R-value
; Argument 2 = G-value
; Argument 3 = B-value
findClosestColorIndex PROC FAR
	push bp
	mov bp, sp

	push bx
	push cx
	push dx

	; Calculate closest R-index
	xor dx, dx
	mov ax, [bp + 6][4]
	mov bx, 48 ; (= 4 * 12) Source in range 0 - 255 while palette has range 0 - 63 ( diff. factor 4). R varies in steps of 12 (see proc. setPalette)
	div bx ; AX = DX:AX / Op and DX = Rest
	push ax ; save index of R value on the stack

	; Calculate the closest G-index
	xor dx, dx
	mov ax, [bp + 6][2]
	mov bx, 48
	div bx ; AX = DX:AX / Op and DX = Rest
	push ax ; save index of G value on the stack

	; Calculate the closest B-index
	xor dx, dx
	mov ax, [bp + 6][0]
	mov bx, 40
	div bx ; AX = DX:AX / Op and DX = Rest
	push ax ; save index of B value on the stack

	; Calculate index in palette of 252 colors
	; Calc: index = r_index * g_count * b_count + g_index * b_count + b_index 
	pop dx ; dx = index = b_index
	pop ax ; ax = g_index
	mov bx, 7
	push dx ; save dx for multiplication
	mul bx ; ax = g_index * b_count
	pop dx
	add dx, ax ; dx = g_index * b_count + b_index
	pop ax ; ax = r_index
	push dx ; save intermediate value
	mov bx, 6
	mul bx ; ax = r_index * g_count
	mov bx, 7
	mul bx ; ax = r_index * g_count * b_count
	pop dx
	add ax, dx ; ax = r_index * g_count * b_count + g_index * b_count + b_index
	
	pop dx
	pop cx
	pop bx

	mov sp, bp
	pop bp
	ret 6
findClosestColorIndex ENDP

END