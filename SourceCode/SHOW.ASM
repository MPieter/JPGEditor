.MODEL large

include SHOW.INC

.DATA
	public RGBPalette ; For testing purposes
	RGBPalette db 756 dup(?)
	
	public channel1, channel2, channel3
	channel1 db 256 dup(?) ; Used for Y and R values
	channel2 db 256 dup(?) ; Used for U and G values
	channel3 db 256 dup(?) ; Used for V and B values

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

	; call changeColorSpace
 
	; Daarna juiste color index berekenen
	; Index in video geheugen plaatsen
	call getColorIndex
	
	call WriteToScreen	
	; TODO
	; calculate offset in YStream, CbStream, CrStream depending on the value of the MDU number
	; mov ax, [bp + 6][0]
	; mov bx, 256 ; number of bytes per block
	; mul bx ; result of calculation: DX:AX = AX * Op
	; mov bx, ax ; save result in ax
	
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
	
	mov ax, [bp + 6][2]
	push ax
	mov ax, [bp + 6][0]
	push ax
	;call UpSamplingCb
	
	mov ax, [bp + 6][2]
	push ax
	mov ax, [bp + 6][0]
	push ax
	;call UpSamplingCr
	
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
	
	mov cx, 0 ; counter outer for loop
@Outer:
	push cx ; save counter outer for loop
	mov cx, 0 ; counter inner for loop
@Inner:	
	mov ax, [bp - 2] ; Counter outer for loop in ax
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

	mov sp, bp
	pop bp
	ret 6
ProcBlockY ENDP

; Arguments on the stack
; Argument 1 = segment of MDU
; Argument 2 = offset in MDU
UpSamplingCb PROC NEAR
	push bp
	mov bp, sp
	
	mov ax, [bp + 6][4]
	push ax
	mov ax, [bp + 6][2]
	push ax
	;call setExtraSegmentCbStream
	push es
	add di, [bp + 4][0]
	push di
	call ProcessBlockC
	
	mov sp, bp
	pop bp
	ret 6
UpSamplingCb ENDP

; Arguments on the stack
; Argument 1 = segment of MDU
; Argument 2 = offset in MDU
UpSamplingCr PROC NEAR
	push bp
	mov bp, sp
	
	mov ax, [bp + 6][4]
	push ax
	mov ax, [bp + 6][2]
	push ax
	;call setExtraSegmentCrStream
	push es
	add di, [bp + 4][0]
	push di
	call ProcessBlockC
	
	mov sp, bp
	pop bp
	ret 6
UpSamplingCr ENDP

; Copies the content of the data in the MDU to the Chromium output stream by converting
; the 8x8 block to a 16x16 block.
; Arguments on the stack
; Argument 1 = segment of input Chromium stream
; Argument 2 = offset in input Chromium stream
; Argument 1 = segment of Chromium output stream
; Argument 2 = offset in Chromium output stream
ProcessBlockC PROC FAR
	push bp
	mov bp, sp
	
	push ax ; save register ax
	
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
	
	
	pop ax ; restore register ax
	
	mov sp, bp
	pop bp
	ret 4
ProcessBlockC ENDP

getColorIndex PROC FAR
	push bp
	mov bp, sp
	
	; Loop over 16x16 matrix
	xor ah, ah
	mov cx, 0
@@:
	mov ax, seg channel1
	push ax
	mov ax, offset channel1
	add ax, cx
	push ax ; push Y value
	mov ax, offset channel2
	add ax, cx
	push ax ; push U value
	mov ax, offset channel3
	add ax, cx
	push ax  ; push V value
	call changeColorSpace

	inc cx
	cmp cx, 256
	jne @B
	
	; findClosestIndex
	
	mov sp, bp
	pop bp
	ret 0
getColorIndex ENDP

; Converts the values of YUV (YCbCr) to RGB
; No arguments on the stack
; The input values are overriden by the output values
changeColorSpace PROC FAR
	push bp
	mov bp, sp
	
	; Formula for calculation RGB from YUV-values
	; R = 1.164(Y - 16) + 1.596(V - 128)
	; G = 1.164(Y - 16) - 0.813(V - 128) 	- 0.391(U - 128)
	; B = 1.164(Y - 16)       						+ 2.018(U - 128)
	
	; For precision we use following version 
	; (the numbers are then rounded to their nearest integers):
	; 100*R = 116.4(Y - 16) + 159.6(Cr - 128)
	; 100*G = 116.4(Y - 16) - 81.3(Cr - 128) 	- 39.1(Cb - 128)
	; 100*B = 116.4(Y - 16)       						+ 201.8(Cb - 128)
	mov ax, seg channel1
	mov es, ax
	mov ds, ax
	mov cx, 0 ; Counter: 0 -> 256
ForLoop:	
	; Load current Y, Cb and Cr value on the stack 
	mov si, offset channel1 ; Y
	add si, cx
	mov ax, ds:[si]
	push ax

	mov si, offset channel2 ; Cb
	add si, cx
	mov ax, ds:[si]
	push ax

	mov si, offset channel3 ; Cr
	add si, cx
	mov ax, ds:[si]
	push ax

	; calculate R: 100*R = 116(Y - 16) + 160(Cr - 128)
	mov ax, [bp - 2] 		; AX = Y ; TODO 
	sub ax, 16				; AX = Y - 16
	mov dx, 116
	mul dx ; result of calculation: DX:AX = AX * Op = 116 * ( Y - 16 )
	push ax
	mov ax, [bp - 6]		; AX = Cr
	sub ax, 128				; AX = Cr - 128
	mov dx, 160	
	mul dx					; AX = 160 * ( Cr - 128 )
	mov dx, ax 				; DX = 160 * ( Cr - 128 )
	pop ax 					; AX = 116  * (Y - 16)
	add ax, dx				; AX = 116 * ( Y - 16 ) + 160 * ( Cr - 128 )
	mov di, offset channel1
	add di, cx
	mov es:[di], ax			; Save R-value
	mov bx, 1
	cmp bx, bx ; Set zero flag (see label: Intermediate)
Intermediate:
	jne ForLoop ; intermediate label because the for-loop contains to many instructions

	; calculate G: 100*G = 116(Y - 16) - 81(Cr - 128) 	- 39(Cb - 128)
	mov ax, [bp - 2] 		; AX = Y
	sub ax, 16				; AX = Y - 16
	mov dx, 116
	mul dx					; AX = 116 * ( Y - 16)
	push ax
	mov ax, [bp - 6]		; AX = Cr
	sub ax, 128				; AX = Cr - 128
	mov dx, 81
	mul dx					; AX = 81 * ( Cr - 128 )
	pop dx
	sub dx, ax				; DX = 116 * ( Y - 16 ) - 81 * ( Cr - 128)
	push dx
	mov ax, [bp - 4]		; AX = Cb
	sub ax, 128				; AX = Cb - 128
	mov dx, 39
	mul dx						; AX = 39 * ( Cb - 128 )
	mov dx, ax				; DX = 39 * ( Cb - 128 )
	pop ax
	sub ax, dx				; AX = 116 * ( Y - 16 ) - 81 * ( Cr - 128) - 39 * ( Cb - 128 )
	mov di, offset channel2
	add di, cx
	mov es:[di], ax 		; Save G-value on the stack
	
	; calculate B: 100*B = 116(Y - 16)       						+ 202(Cb - 128)
	mov ax, [bp - 2] 		; AX = Y
	sub ax, 16				; AX = Y - 16
	mov dx, 116
	mul dx 					; AX = 116 * ( Y - 16 )
	push ax
	mov ax, [bp - 4] 		; AX = Cb
	sub ax, 128				; AX = Cb - 128
	mov dx, 202
	mul dx						; AX = 202 * ( Cb - 128 )
	pop dx
	add ax, dx				; DX = 116 * ( Y - 16 ) + 202 * ( Cb - 128 )
	mov di, offset channel3
	add di, cx
	mov es:[di], ax 		; Save B-value on the stack

	inc cx
	cmp cx, 256
	jne Intermediate
	
		
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
	mov cx, 0
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
	
	mov sp, bp
	pop bp
	ret 0
setPalette ENDP

; Procedures that writes the screenbuffer to the graphics memory.
; No arguments on the stack.
WriteToScreen PROC FAR
	push bp
	mov bp, sp

	; Set the video mode
	mov ax, 13h
	xor ah, ah
	int 10h

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

	mov sp, bp
	pop bp
	ret 0 
WriteToScreen ENDP

; Returns the index in ax of the 8-bit color in the palette that is the closest to the specified RGB-values
; Arguments on the stack:
; Argument 1 = R-value
; Argument 2 = G-value
; Argument 3 = B-value
findClosestColorIndex PROC NEAR
	push bp
	mov bp, sp
	
	mov sp, bp
	pop bp
	ret 6
findClosestColorIndex ENDP

END