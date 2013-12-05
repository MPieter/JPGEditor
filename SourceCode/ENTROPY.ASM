.MODEL large
include ENTROPY.INC
.DATA
; Raw db 60000 DUP (?)				; Raw BITstream
; ; Define place for code values
; HcodeACL db 162 dup (?)
; HcodeACC db 162 dup (?)
; HcodeDCL db 162 dup (?)
; HcodeDCC db 162 dup (?)

.FARDATA?
; We should later try to overwrite Raw...

.CODE

entropyDecoding PROC FAR
	push bp
	mov bp, sp
	
	
	
	mov sp, bp
	pop bp
	ret 0
entropyDecoding ENDP

END