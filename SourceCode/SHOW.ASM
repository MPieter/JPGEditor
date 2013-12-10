.MODEL large

include SHOW.INC

.CODE

showImage PROC FAR
	push bp
	mov bp, sp
	
	mov sp, bp
	pop bp
	ret 0
showImage ENDP

END