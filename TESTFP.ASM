.MODEL large ; one data and one code segment, stack and data segment are grouped

.STACK 1024  ; stack, 1024 bytes

.DATA        ; data segment, global variables
message db "Optellen gelukt$"
floatingPoint dd 1.5

.CODE        ; code segment

; ----------------------------- CODE STARTS HERE -------------------------------
main:
	mov	ax, @DATA
	mov	ds, ax

start:
	mov ax, dd
	fadd ax, dd
	cmp ax, 3
	je exit
	jmp start
exit:
	call print
	; Exit to DOS
	mov	ax, 4c00h
	int	21h

; --- END

print PROC NEAR
	push bp
	mov bp, sp
	
	mov ah, 09h
	mov dx, offset message
	int 21h
	
	mov sp, bp
	pop bp
	ret 0
print ENDP

; _------------------------------- END OF CODE ---------------------------------
END main
