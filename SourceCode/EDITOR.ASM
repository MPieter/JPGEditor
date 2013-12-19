.MODEL large

include EDITOR.INC
include HELPERS.INC

.DATA
	YStreamSeg dw ?
	CbStreamSeg dw ?
	CrStreamSeg dw ?
	
	msgError db 'Error during allocating memory.$'
	msgErrorCode db 'The Error code: $'
	msgErrorBlockSize db 'The maximum block size available: $'

.CODE

; Start the editor to open a file
startEditor PROC FAR
	push bp
	mov bp, sp
	
	call allocMemory
	jnc ReadStart ; if no error continue
	; Error afhandeling
	mov dx, offset msgError
	push dx
	call PrintString
	call PrintNewline
	
	pushf ; save flags
	; Error code
	mov dx, offset msgErrorCode
	push dx
	call PrintString
	
	push ax ; error code in ax
	call PrintNumber
	call PrintNewline
	
	; Maximum block size available
	mov dx, offset msgErrorBlockSize
	push dx
	call PrintString
	push bx ; avalaible memory in bx
	call PrintNumber
	call PrintNewline
	
	popf ; pop flags
	
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

	clc ; clear carry flag
	mov bx, 250; number of paragraphs needed (1 paragraph = 256 bytes) and we need 64k bytes
	; Y-Stream
	mov ax, offset YStreamSeg
	mov di, ax
	xor al, al
	mov ah, 48h
	int 21h ; store segment-address of allocated memory in ax
	stosw
	jc EndAlloc
	
	; Cb-Stream
	mov ax, offset CbStreamSeg
	mov di, ax
	mov ah, 48h
	int 21h
	stosw
	jc EndAlloc
	
	; Cr-Stream
	mov ax, offset CrStreamSeg
	mov di, ax
	mov ah, 48h
	int 21h
	stosw
	
	; More information about int 21, 48h: http://stanislavs.org/helppc/int_21-48.html
EndAlloc:
	mov sp, bp
	pop bp
	ret 0
allocMemory ENDP

; Set register es to correct segment of Y Stream
; Set register di to correct offset of Y Stream
; Useful procedure for starting to write to YStream
; No arguments on the stack
setExtraSegmentYStream PROC FAR
	push bp
	mov bp, sp
	
	push ax ; save used registers
	push ds
	push si
	
	mov ax, seg YStreamSeg
	mov ds, ax
	mov si, offset YStreamSeg
	lodsw ; loads segment address of YStream in AX
	mov es, ax
	mov di, 0
	
	pop si ; restore used registers
	pop ds
	pop ax
	
	mov sp, bp
	pop bp
	ret 0
setExtraSegmentYStream ENDP

; Set register es to correct segment of Cb Stream
; Set register di to correct offset of Cb Stream
; Useful procedure for starting to write to CbStream
; No arguments on the stack
setExtraSegmentCbStream PROC FAR
	push bp
	mov bp, sp
	
	push ax ; save used registers
	push ds
	push si
	
	mov ax, seg CbStreamSeg
	mov ds, ax
	mov si, offset CbStreamSeg
	lodsw ; loads segment address of CbStream in AX
	mov es, ax
	mov di, 0
	
	pop si ; restore used registers
	pop ds
	pop ax
	
	mov sp, bp
	pop bp
	ret 0
setExtraSegmentCbStream ENDP

; Set register es to correct segment of Cr Stream
; Set register di to correct offset of Cr Stream
; Useful procedure for starting to write to CrStream
; No arguments on the stack
setExtraSegmentCrStream PROC FAR
	push bp
	mov bp, sp
	
	push ax ; save used registers
	push ds
	push si
	
	mov ax, seg CrStreamSeg
	mov ds, ax
	mov si, offset CrStreamSeg
	lodsw ; loads segment address of CrStream in AX
	mov es, ax
	mov di, 0
	
	pop si ; restore used registers
	pop ds
	pop ax
	
	mov sp, bp
	pop bp
	ret 0
setExtraSegmentCrStream ENDP

; Set register ds to correct segment of Y Stream
; Set register si to correct offset of Y Stream
; Useful procedure for starting to read from YStream
; No arguments on the stack
setDataSegmentYStream PROC FAR
	push bp
	mov bp, sp
	
	push ax
	
	mov ax, seg YStreamSeg
	mov ds, ax
	mov si, offset YStreamSeg
	lodsw
	mov ds, ax
	mov si, 0
	
	pop ax
	
	mov sp, bp
	pop bp
	ret 0
setDataSegmentYStream ENDP

; Set register ds to correct segment of Cb Stream
; Set register si to correct offset of Cb Stream
; Useful procedure for starting to read from CbStream
; No arguments on the stack
setDataSegmentCbStream PROC FAR
	push bp
	mov bp, sp
	
	push ax
	
	mov ax, seg CbStreamSeg
	mov ds, ax
	mov si, offset CbStreamSeg
	lodsw
	mov ds, ax
	mov si, 0
	
	pop ax
	
	mov sp, bp
	pop bp
	ret 0
setDataSegmentCbStream ENDP

; Set register ds to correct segment of Cr Stream
; Set register si to correct offset of Cr Stream
; Useful procedure for starting to read from CrStream
; No arguments on the stack
setDataSegmentCrStream PROC FAR
	push bp
	mov bp, sp
	
	push ax
	
	mov ax, seg CrStreamSeg
	mov ds, ax
	mov si, offset CrStreamSeg
	lodsw
	mov ds, ax
	mov si, 0
	
	pop ax
	
	mov sp, bp
	pop bp
	ret 0
setDataSegmentCrStream ENDP

END