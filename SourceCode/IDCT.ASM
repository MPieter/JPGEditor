.MODEL large
include IDCT.INC
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
	ret ;2
IDCTBlock ENDP

; Calculates the value of the cos(x) where x is the input argument that is stored
; on top of the stack.
; The return value is stored in ax.
calcCOS PROC NEAR
	push bp
	mov bp, sp
	
								; TODO implementeren
	
	mov sp, bp
	pop bp
	ret 2
calcCOS ENDP

; Calculates the normalizing scale factor in the invers disrete cosine transform.
; The return value is stored in ax.
; Accepts one argument on top of the stack.
calcNormalizer PROC NEAR
	push bp
	mov bp, sp
	
	mov dx, [bp + 4]
	cmp dx, 0
	jne false	
true:							; TODO correcte waarden nog implementeren
	mov ax, 0
	jmp exitF
false:
	mov ax, 1
exitF:
	mov sp, bp
	pop bp
	ret 2
calcNormalizer ENDP

END