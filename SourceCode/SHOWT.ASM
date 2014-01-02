; SAMPLINGT.ASM
; ---------------
; Contains Test Code for all the procedures in SAMPLING.ASM
.MODEL large

include HELPERS.INC
include SHOW.INC

.DATA
	dataMDU dw 384 dup (?) ; contains one MDU -> 4x 8x8 Y blocks, 1x 8x8 Cb block, 1x 8x8 Cr block -> in total 384 bytes
	
	msgSampling db 'Executing Upsampling: $'
	msgYStream db 'The data for Y-channel: $'
	msgCbStream db 'The data for Cb-channel: $'
	msgCrStream db 'The data for Cr-channel: $'
	msgChangeColorSpace db 'Executing changeColorSpace: $'
	msgColorR db 'The R-values: $'
	msgColorG db 'The G-values: $'
	msgColorB db 'The B-values: $'
	msgPalette db 'Executing setPalette: $'
	msgRGBPair db 'The tested Pair: $'
	msgResult db 'The result: $'
.CODE

; Test code for the procedure UpSampling
; No arguments on the stack
UpSamplingTest PROC FAR
	push bp
	mov bp, sp
	
	; Create 6 byte-matrices stored after each other in the MDU
	xor cx, cx ; counter loop
@@:
	mov dx, seg dataMDU
	push dx
	mov dx, offset dataMDU
	mov ax, 128 ; 64 words per matrix
	push dx
	mul cx
	pop dx
	add dx, ax ; add offset according to current count index
	push dx
	call initializeWordMatrix
	inc cx
	cmp cx, 6
	jne @B

	; The data
	mov ax, offset msgYStream
	push ax
	call PrintString

	mov ax, seg dataMDU
	push ax
	mov ax, offset dataMDU
	push ax
	mov ax, 64
	push ax
	call PrintWordSegment

	call WaitForEnter
	
	; Execute upsampling
	mov ax, offset msgSampling
	push ax
	call PrintString
	
	mov ax, seg dataMDU
	push ax
	mov ax, offset dataMDU
	push ax
	call UpSampling
	
	; Display Y-output
	mov ax, offset msgYStream
	push ax
	call PrintString
	
	mov ax, seg channel1
	push ax
	mov ax, offset channel1
	push ax
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
	
	mov ax, seg channel2
	push ax
	mov ax, offset channel2
	push ax
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
	
	mov ax, seg channel3
	push ax
	mov ax, offset channel3
	push ax
	mov ax, 256 ; 16x16 matrix
	push ax
	mov ax, 16 ; line break after 16 numbers
	push ax
	call PrintByteSegment
	
	
	mov sp, bp
	pop bp
	ret 0
UpSamplingTest ENDP

; Test code for the procedure changeColorSpace
; No arguments on the stack
changeColorSpaceTest PROC FAR
	push bp
	mov bp, sp

	mov ax, offset msgChangeColorSpace
	push ax
	call PrintString

	mov ax, seg channel1
	push ax
	mov ax, offset channel1
	push ax
	mov ax, 256
	push ax
	call initializeByteArray	
	mov ax, seg channel2
	push ax
	mov ax, offset channel2
	push ax
	mov ax, 256
	push ax
	call initializeByteArray	
	mov ax, seg channel3
	push ax
	mov ax, offset channel3
	push ax
	mov ax, 256
	push ax
	call initializeByteArray	

	call changeColorSpace

	; Print the result
	mov ax, offset msgColorR
	push ax
	call PrintString
	mov ax, seg channel1
	push ax
	mov ax, offset channel1
	push ax
	mov ax, 16
	push ax
	mov ax, 16
	push ax
	call PrintByteSegment

	mov ax, offset msgColorG
	push ax
	call PrintString
	mov ax, seg channel2
	push ax
	mov ax, offset channel2
	push ax
	mov ax, 16
	push ax
	mov ax, 16
	push ax
	call PrintByteSegment

	mov ax, offset msgColorB
	push ax
	call PrintString
	mov ax, seg channel3
	push ax
	mov ax, offset channel3
	push ax
	mov ax, 16
	push ax
	mov ax, 16
	push ax
	call PrintByteSegment

	mov sp, bp
	pop bp
	ret 0
changeColorSpaceTest ENDP

; Test code for the procedure setPalette
; No arguments on the stack
setPaletteTest PROC FAR
	push bp
	mov bp, sp

	mov ax, offset msgPalette
	push ax
	call PrintString

	call setPalette

	mov ax, seg RGBPalette
	push ax
	mov ax, offset RGBPalette
	push ax
	mov ax, 756 ; Number of values
	push ax
	mov ax, 3 ; Line break after each 3 numbers
	push ax
	call PrintByteSegment


	mov sp, bp
	pop bp
	ret 0
setPaletteTest ENDP

; Test code for the procedure RenderScreen
; No arguments on the stack
RenderScreenTest PROC FAR
	push bp
	mov bp, sp

	call setPalette

	; Initalize pixels
	mov ax, seg screenBuffer
	push ax
	mov ax, offset screenBuffer
	push ax
	mov ax, 64000
	push ax
	call initializeByteArray

	call RenderScreen

	call WaitForEnter

	mov sp, bp
	pop bp
	ret 0
RenderScreenTest ENDP

; Test code for the procedure findClosestColorIndex
; No arguments on the stack
findClosestColorIndexTest PROC FAR
	push bp
	mov bp, sp

	mov ax, 14
	push ax
	mov ax, 14
	push ax
	mov ax, 3
	push ax
	call findClosestColorIndex
	push ax ; save result

	mov ax, offset msgRGBPair
	push ax
	call PrintString
	mov ax, 14
	push ax
	call PrintNumber
	call PrintSpace
	mov ax, 14
	push ax
	call PrintNumber
	call PrintSpace
	mov ax, 3
	push ax
	call PrintNumber
	call PrintSpace

	mov ax, offset msgResult
	push ax
	call PrintString
	pop ax
	push ax
	call PrintNumber

	mov sp, bp
	pop bp
	ret 0
findClosestColorIndexTest ENDP

END