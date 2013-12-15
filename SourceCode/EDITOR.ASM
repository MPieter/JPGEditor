.MODEL large

include EDITOR.INC
include HELPERS.INC

.DATA
	YStreamSeg dw 1 ?
	CbStreamSeg dw 1 ?
	CrStreamSeg dw 1 ?
	
	msgError db 'Error during allocating memory.$'

.CODE

; Start the editor to open a file
startEditor PROC FAR
	push bp
	mov bp, sp
	
	call allocMemory
	jnc ReadStart ; if no error continue
	mov ax, offset msgError
	push ax
	call PrintString
	
ReadStart:	
	


Return:
	mov sp, bp
	pop bp
	ret 0
startEditor ENDP

; Destructor for the editor. Releasing of the resources
endEditor PROC FAR
	push bp
	mov bp, sp
	
	; Release Y-Stream
	mov ax, seg YStreamSeg
	mov ds, ax
	mov ax, offset YStreamSeg
	mov si, ax
	lodsw
	mov es, ax
	mov ah, 49h
	int 21h
	
	; Release Cb-Stream
	mov ax, offset CbStreamSeg
	mov si, ax
	lodsw
	mov es, ax
	mov ah, 49h
	int 21h
	
	; Release Cr-Stream
	mov ax, offset CrStreamSeg
	mov si, ax
	lodsw
	mov es, ax
	mov ah, 49h
	int 21h
	
	mov sp, bp
	pop bp
	ret 0
endEditor ENDP

; Allocates memory for Y-, Cb-, Cr-Stream
; No arguments on the stack
; If the CF is set, on error has occured.
allocMemory PROC NEAR
	push bp
	mov bp, sp
	
	mov ax, seg YStreamSeg
	mov es, ax


	mov bx, 4000; number of paragraphs needed (1 paragraph = 16 bytes) and we need 64k bytes
	; Y-Stream
	mov ax, offset YStreamSeg
	mov di, ax
	mov ah, 48h
	int 21h ; store segment-address of allocated memory in ax
	stosw
	
	; Cb-Stream
	mov ax, offset CbStreamSeg
	mov di, ax
	mov ah, 48h
	int 21h
	stosw
	
	; Cr-Stream
	mov ax, offset CrStreamSeg
	mov di, ax
	mov ah, 48h
	int 21h
	stosw
	
	
	; More information about int 21, 48h: http://stanislavs.org/helppc/int_21-48.html
	
	mov sp, bp
	pop bp
	ret 0
allocMemory ENDP

END