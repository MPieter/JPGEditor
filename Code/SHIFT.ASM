.MODEL large

.CODE

shiftColors PROC FAR
	push bp
	mov bp, sp
	
	mov sp, bp
	pop bp
	ret 0
shiftColors ENDP

END