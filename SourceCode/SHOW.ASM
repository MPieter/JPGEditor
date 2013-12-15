.MODEL large

include SHOW.INC
include EDITOR.INC

.DATA
	RGBPalette db 768 dup(?)

.CODE

; Function that shows the image in RGB-space in 256 colors on the screen
; Y-, Cb-, Cr- streams are declared in EDITOR.INC
; No arguments on the stack.
showImage PROC FAR
	push bp
	mov bp, sp
	
	; Calculate RGB-values and store them in video memory
	; Formula for calculation RGB from YUV-values
	; R = 1.164(Y - 16) + 1.596(V - 128)
	; G = 1.164(Y - 16) - 0.813(V - 128) 	- 0.391(U - 128)
	; B = 1.164(Y - 16)       						+ 2.018(U - 128)
	
	; For precision we use follewing version:
	; 100*R = 116.4(Y - 16) + 159.6(Cr - 128)
	; 100*G = 116.4(Y - 16) - 81.3(Cr - 128) 	- 39.1(Cb - 128)
	; 100*B = 116.4(Y - 16)       						+ 201.8(Cb - 128)

	mov cx, 64000
@@:
	; Load Y on the stack
	mov ax, seg YStreamSeg
	mov ds, ax
	mov si, offset YStreamSeg
	lodsw ; loads addressof YStream in AX
	mov ds, ax
	mov si, 0
	lodsb
	xor ah, ah
	push ax
	
	; Load Cb on the stack
	mov ax, seg CbStreamSeg
	mov ds, ax
	mov si, offset CbStreamSeg
	lodsw ; loads addressof YStream in AX
	mov ds, ax
	mov si, 0
	lodsb
	xor ah, ah
	push ax
	
	; Load Cr on the stack
	mov ax, seg CrStreamSeg
	mov ds, ax
	mov si, offset CrStreamSeg
	lodsw ; loads addressof YStream in AX
	mov ds, ax
	mov si, 0
	lodsb
	xor ah, ah
	push ax
	
	; calculate R: 100*R = 116.4(Y - 16) + 159.6(Cr - 128)
	mov ax, [sp + 4] 		; AX = Y
	sub ax, 16				; AX = Y - 16
	mov dx, 116
	mul dx ; result of calculation: DX:AX = AX * Op = 116 * ( Y - 16 )
	push ax
	mov ax, [sp + 2] 		; AX = Cr
	sub ax, 128				; AX = Cr - 128
	mov dx, 160	
	mul dx						; AX = 160 * ( Cr - 128 )
	mov dx, ax 				; DX = 160 * ( Cr - 128 )
	pop ax 					; AX = 116  * (Y - 16)
	add ax, dx				; AX = 116 * ( Y - 16 ) + 160 * ( Cr - 128 )
	push ax 					; Save R-value on the stack
	
	; calculate G: 100*G = 116.4(Y - 16) - 81.3(Cr - 128) 	- 39.1(Cb - 128)
	mov ax, [sp + 6]		; AX = Y
	sub ax, 16				; AX = Y - 16
	mov dx, 116
	mul dx						; AX = 116 * ( Y - 16)
	push ax
	mov ax, [sp + 4]		; AX = Cr
	sub ax, 128				; AX = Cr - 128
	mov dx, 81
	mul dx						; AX = 81 * ( Cr - 128 )
	pop dx
	sub dx, ax				; DX = 116 * ( Y - 16 ) - 81 * ( Cr - 128)
	push dx
	mov ax, [sp + 6]		; AX = Cb
	sub ax, 128				; AX = Cb - 128
	mov dx, 39
	mul dx						; AX = 39 * ( Cb - 128 )
	mov dx, ax				; DX = 39 * ( Cb - 128 )
	pop ax
	sub ax, dx				; AX = 116 * ( Y - 16 ) - 81 * ( Cr - 128) - 39 * ( Cb - 128 )
	push ax					; Save G-value on the stack
	
	; calculate B: 100*B = 116.4(Y - 16)       						+ 201.8(Cb - 128)
	mov ax, [sp + 8] 		; AX = Y
	sub ax, 16				; AX = Y - 16
	mov dx, 116
	mul dx 					; AX = 116 * ( Y - 16 )
	push ax
	mov ax, [sp + 8] 		; AX = Cb
	sub ax, 128				; AX = Cb - 128
	mov dx, 202
	mul dx						; AX = 202 * ( Cb - 128 )
	pop dx
	add dx, ax				; DX = 116 * ( Y - 16 ) + 202 * ( Cb - 128 )
	push ax
	
	call findClosestColorIndex ; returns index in ax
	
	
	loop @B
	
	mov sp, bp
	pop bp
	ret 0
showImage ENDP

; Function that shows a Y, Cb- or Cr-channel on the screen depending on the input.
; Arguments on the stack
showChannel PROC FAR
	push bp
	mov bp, sp
	
	mov sp, bp
	pop bp
	ret 0
showChannel ENDP

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