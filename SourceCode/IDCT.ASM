.MODEL large

; Constants
blockW equ 8
blockH equ 8

.CODE

; Calculates the inverse discrete cosine transform. 
; Arguments on the stack:
; Argument 1 = segment address of data
; Argument 2 = offset address of data
iDCT PROC FAR
	push bp
	mov bp, sp
	
	; TODO integer based discrete cosine transform implementeren
	
	
	mov sp, bp
	pop bp
	ret 0
iDCT ENDP

; Calculates the inverse discrete cosine transform of one block.
; Arguments on the stack: 
; Argument 1 = segment address of data
; Argument 2 = offset address of current data block in data
iDCTBlock PROC NEAR
	push bp
	mov bp, sp
	
	mov dl, -1		; coefficient u
	mov dh, -1		; coefficient v
forU:
	inc dl	
	cmp dl, blockW
	je EndFor
forV:
	inc dh
	cmp dh, blockH
	je forU
	
	
	jmp forV
	
EndFor:
	mov sp, bp
	pop bp
	ret 2
IDCTBlock ENDP


END