.MODEL large

include EDITOR.INC
include SAMP.INC

.CODE

; Gets an offset to one MDU as input address and puts the corresponding Y, Cb, Cr data 
; in the correct segments defined in EDITOR.INC
; Arguments on the stack:
; Argument 1 = segment address of MDU
; Argument 2 = offset address of MDU
; Argument 3 = MDU number ; Zero based
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

END