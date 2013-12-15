.MODEL large

include EDITOR.INC ; definitions for YStream, CbStream, CrStream
include SAMPLING.INC

.CODE

; Gets an offset to an MDU as input address and puts the corresponding Y, Cb, Cr data 
; in the correct segments defined in EDITOR.INC
; Arguments on the stack:
; Argument 1 = segment address of MDU
; Argument 2 = offset address of MDU
; Argument 3 = MDU number
UpSampling PROC FAR
	push bp
	mov bp, sp
	
	; calculate offset in YStream, CbStream, CrStream depending on the value of the MDU number
	mov ax, [bp + 6][0]
	mov bx, 256 ; number of bytes per block
	mul bx ; result of calculation: DX:AX = AX * Op
	
	; Process luminance blocks
	mov ds, [bp + 6][4]
	mov si, [bp + 6][2]
	mov es, seg YStream
	mov di, offset YStream
	add di, ax
	
	push ax ; save offset in data segment
	mov cx, 256 ; 4 luminance blocks
@@:
	lodsw
	stosb
	loop @B
	pop ax ; restore offset in data segment
	
	; Process Cb-blocks
	mov bx, seg CbStream
	push bx
	mov bx, offset CbStream
	add bx, ax
	push bx
	call ProcessChromiumBlock

	; Process Cr-blocks
	mov bx, seg CrStream
	push bx
	mov bx, offset CrStream
	add bx, ax
	push bx
	call ProcessChromiumBlock
	
	mov sp, bp
	pop bp
	ret 8
ENDP

; Copies the content of the data in the MDU to the Chromium output stream by converting
; the 8x8 block to a 16x16 block.
; Arguments on the stack
; Argument 1 = segment of Chromium output stream
; Argument 2 = offset in Chromium output stream
; Assumes that ds:si registers are set correctly.
ProcessChromiumBlock PROC FAR
	push bp
	mov bp, sp
	
	push ax ; save register ax
	
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
	ret 
ProcessChromiumBlock ENDP

END

END