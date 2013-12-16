; SAMPLINGT.ASM
; ---------------
; Contains Test Code for all the procedures in SAMPLING.ASM
.MODEL large

include EDITOR.INC
include HELPERS.INC
include SAMP.INC

.DATA
	dataMDU db 384 dup (?) ; contains one MDU -> 4x 8x8 Y blocks, 1x 8x8 Cb block, 1x 8x8 Cr block -> in total 384 bytes
	
	msgSampling db 'Executing Upsampling: $'
	msgYStream db 'The data for Y-channel: $'
	msgCbStream db 'The data for Cb-channel: $'
	msgCrStream db 'The data for Cr-channel: $'
	
.CODE

; Test code for the procedure UpSampling
; No arguments on the stack
UpSamplingTest PROC FAR
	push bp
	mov bp, sp
	
	; Create 6 byte-matrices stored after each other in the MDU
	mov cx, 0 ; counter loop
@@:
	mov dx, seg dataMDU
	push dx
	mov dx, offset dataMDU
	mov ax, 64
	mul cx
	add dx, ax ; add offset according to current count index
	push dx
	call initializeByteMatrix
	cmp cx, 6
	jne @B
	
	; Execute upsampling
	mov ax, offset msgSampling
	push ax
	call PrintString
	
	mov ax, seg dataMDU
	push ax
	mov ax, offset dataMDU
	push ax
	mov ax, 0
	push ax
	call UpSampling
	
	; Display Y-output
	mov ax, offset msgYStream
	push ax
	call PrintString
	
	call setDataSegmentYStream
	push ds
	push si
	mov ax, 256 ; 16x16 matrix
	push ax
	mov ax, 16 ; line break after 16 numbers
	push ax
	call PrintByteSegment
	
	call WaitForEnter ; buffer output
	
	; Display Cb-output
	mov ax, offset msgCbStream
	push ax
	call PrintString
	
	call setDataSegmentCbStream
	push ds
	push si
	mov ax, 256 ; 16x16 matrix
	push ax
	mov ax, 16 ; line break after 16 numbers
	push ax
	call PrintByteSegment
	
	call WaitForEnter
	
	; Display Cr-output
	mov ax, offset msgCrStream
	push ax
	call PrintString
	
	call setDataSegmentCrStream
	push ds
	push si
	mov ax, 256 ; 16x16 matrix
	push ax
	mov ax, 16 ; line break after 16 numbers
	push ax
	call PrintByteSegment
	
	
	mov sp, bp
	pop bp
	ret 0
UpSamplingTest ENDP

END