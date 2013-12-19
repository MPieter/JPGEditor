.MODEL large

include SHOW.INC
include EDITOR.INC

.DATA
	RGBPalette db 768 dup(?)
	
	channel1 db 256 dup(?) ; Used for Y and R values
	channel2 db 256 dup(?) ; Used for U and G values
	channel3 db 256 dup(?) ; Used for V and B values

.CODE

; Function that shows the image in RGB-space in 256 colors on the screen
; Arguments on the stack:
; Argument 1 = segment address of MDU
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
	
	call getColorIndex
	
	call WriteToScreen	
	
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
	
	; calculate offset in YStream, CbStream, CrStream depending on the value of the MDU number
	mov ax, [bp + 6][0]
	mov bx, 256 ; number of bytes per block
	mul bx ; result of calculation: DX:AX = AX * Op
	mov bx, ax ; save result in ax
	
	mov ax, [bp + 6][4]
	push ax
	mov ax, [bp + 6][2]
	push ax
	push bx ; offset in YStream
	call UpSamplingY
	
	mov ax, [bp + 6][4]
	push ax
	mov ax, [bp + 6][2]
	push ax
	push bx ; offset in CbStream
	call UpSamplingCb
	
	mov ax, [bp + 6][4]
	push ax
	mov ax, [bp + 6][2]
	push ax
	push bx ; offset in CbStream
	call UpSamplingCr
	
	mov sp, bp
	pop bp
	ret 6
UpSampling ENDP

; Arguments on the stack
; Argument 1 = segment address of MDU
; Argument 2 = offset address of MDU
; Argument 3 = offset in YStream
UpSamplingY PROC FAR
	push bp
	mov bp, sp
			
	mov ax, [bp + 6][4]
	push ax
	mov ax, [bp + 6][2]
	push ax
	call setExtraSegmentYStream
	push es
	add di, [bp + 6][0]
	;add di, 0
	push di
	call ProcBlockY 
	
	mov ax, [bp + 6][4]
	push ax
	mov ax, [bp + 6][2]
	add ax, 64 ; Second matrix of 8x8 values
	push ax
	call setExtraSegmentYStream
	push es
	add di, [bp + 6][0]
	add di, 8
	push di
	call ProcBlockY 
	
	mov ax, [bp + 6][4]
	push ax
	mov ax, [bp + 6][2]
	add ax, 128 ; Second matrix of 8x8 values
	push ax
	call setExtraSegmentYStream
	push es
	add di, [bp + 6][0]
	add di, 128
	push di
	call ProcBlockY 
	
	mov ax, [bp + 6][4]
	push ax
	mov ax, [bp + 6][2]
	add ax, 192 ; Second matrix of 8x8 values
	push ax
	call setExtraSegmentYStream
	push es
	add di, [bp + 6][0]
	add di, 136
	push di
	call ProcBlockY 
	
	
	mov sp, bp
	pop bp
	ret 6
UpSamplingY ENDP

; Arguments on the stack
; Argument 1 = seg of input MDU
; Argument 2 = offset of input MDU (start of current Y-block)
; Argument 3 = seg of output Y stream
; Argument 4 = offset in output Y stream (start of current 16x16 block with offset for current 8x8 block: possible values for offset are 0, 8, 128, 136)
ProcBlockY PROC FAR
	push bp
	mov bp, sp
	
	mov ds, [bp + 6][8]
	mov si, [bp + 6][6]

	mov es, [bp + 6][4]
	mov di, [bp + 6][2]
	add di, [bp + 6][0]
	
	mov cx, 8 ; counter outer for loop
@Outer:
	push cx ; save counter outer for loop
	mov cx, 8 ; counter inner for loop
@Inner:	
	movsb
	inc di
	loop @Inner
	pop cx
	add di, 8
	loop @Outer
	mov sp, bp
	pop bp
	ret 8
ProcBlockY ENDP

; Arguments on the stack
; Argument 1 = segment of MDU
; Argument 2 = offset in MDU
; Argument 3 = offset in CbStream
UpSamplingCb PROC NEAR
	push bp
	mov bp, sp
	
	mov ax, [bp + 6][4]
	push ax
	mov ax, [bp + 6][2]
	push ax
	call setExtraSegmentCbStream
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
; Argument 3 = offset in CrStream
UpSamplingCr PROC NEAR
	push bp
	mov bp, sp
	
	mov ax, [bp + 6][4]
	push ax
	mov ax, [bp + 6][2]
	push ax
	call setExtraSegmentCrStream
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
	call calcRGB

	inc cx
	cmp cx, 256
	jne @B
	
	; findClosestIndex
	
	mov sp, bp
	pop bp
	ret 0
getColorIndex ENDP

; Converts the values of YUV (YCbCr) to RGB
; Arguments on the stack:
; Argument 1 = segment of Y, U, V values
; Argument 2 = offset of Y-value
; Argument 3 = offset of U-value
; Argument 4 = offset of V-value
; The input values are overriden by the output values
calcRGB PROC FAR
	push bp
	mov bp, sp
	
	; Calculate RGB-values and store them in video memory
	; Formula for calculation RGB from YUV-values
	; R = 1.164(Y - 16) + 1.596(V - 128)
	; G = 1.164(Y - 16) - 0.813(V - 128) 	- 0.391(U - 128)
	; B = 1.164(Y - 16)       						+ 2.018(U - 128)
	
	; For precision we use following version:
	; 100*R = 116.4(Y - 16) + 159.6(Cr - 128)
	; 100*G = 116.4(Y - 16) - 81.3(Cr - 128) 	- 39.1(Cb - 128)
	; 100*B = 116.4(Y - 16)       						+ 201.8(Cb - 128)
	
	; calculate R: 100*R = 116.4(Y - 16) + 159.6(Cr - 128)
	mov ax, [channel1][[bp + 6][4]] 		; AX = Y
	sub ax, 16				; AX = Y - 16
	mov dx, 116
	mul dx ; result of calculation: DX:AX = AX * Op = 116 * ( Y - 16 )
	push ax
	mov ax, [channel3][bp + 6][0] 		; AX = Cr
	sub ax, 128				; AX = Cr - 128
	mov dx, 160	
	mul dx						; AX = 160 * ( Cr - 128 )
	mov dx, ax 				; DX = 160 * ( Cr - 128 )
	pop ax 					; AX = 116  * (Y - 16)
	add ax, dx				; AX = 116 * ( Y - 16 ) + 160 * ( Cr - 128 )
	push ax 					; Save R-value on the stack
	
	; calculate G: 100*G = 116.4(Y - 16) - 81.3(Cr - 128) 	- 39.1(Cb - 128)
	mov ax, [channel1][bp + 6][4]		; AX = Y
	sub ax, 16				; AX = Y - 16
	mov dx, 116
	mul dx						; AX = 116 * ( Y - 16)
	push ax
	mov ax, [channel3][bp + 6][0]		; AX = Cr
	sub ax, 128				; AX = Cr - 128
	mov dx, 81
	mul dx						; AX = 81 * ( Cr - 128 )
	pop dx
	sub dx, ax				; DX = 116 * ( Y - 16 ) - 81 * ( Cr - 128)
	push dx
	mov ax, [channel2][bp + 6][2]		; AX = Cb
	sub ax, 128				; AX = Cb - 128
	mov dx, 39
	mul dx						; AX = 39 * ( Cb - 128 )
	mov dx, ax				; DX = 39 * ( Cb - 128 )
	pop ax
	sub ax, dx				; AX = 116 * ( Y - 16 ) - 81 * ( Cr - 128) - 39 * ( Cb - 128 )
	push ax					; Save G-value on the stack
	
	; calculate B: 100*B = 116.4(Y - 16)       						+ 201.8(Cb - 128)
	mov ax, [bp + 6][4] 		; AX = Y
	sub ax, 16				; AX = Y - 16
	mov dx, 116
	mul dx 					; AX = 116 * ( Y - 16 )
	push ax
	mov ax, [bp + 6][2] 		; AX = Cb
	sub ax, 128				; AX = Cb - 128
	mov dx, 202
	mul dx						; AX = 202 * ( Cb - 128 )
	pop dx
	add dx, ax				; DX = 116 * ( Y - 16 ) + 202 * ( Cb - 128 )
	push ax
	
		
	mov sp, bp
	pop bp
	ret 0
calcRGB ENDP


; Initializes the palette with 252 colors
; No arguments on the stack
setPalette PROC NEAR
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
	
	mov cx, 6 	; Counter First loop
@1:
	

	push cx		; Save counter First loop
	mov cx, 6
@2:
	
	
	push cx 		; Save counter Second loop
	mov cx, 7		; Counter Third loop
@3:
	; Calculate and Save R-value
	
	; Calculate and Save G-value
	
	; Calculate and Save B-value
	
	loop @3
	pop cx
	loop @2
	pop cx
	loop @1
	
	mov sp, bp
	pop bp
	ret 0
setPalette ENDP

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