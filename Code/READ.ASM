.MODEL large

.CODE

readJPG PROC FAR
	push bp
	mov bp, sp
	
	mov sp, bp
	pop bp
	ret 0
readJPG ENDP

END