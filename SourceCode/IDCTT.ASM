.MODEL large

include IDCT.INC
include IDCTT.INC
include HELPERS.INC

.DATA
	dctCoeff dw 64 dup(0)
	; dctCoeff 	dw -415, -26, -58, 33, 56, -24, -2, 0 ; data is separated on multiple lines because of a line-length limitation (http://www.masmforum.com/board/index.php?PHPSESSID=786dd40408172108b65a5a36b09c88c0&topic=16595.0)
	; 				dw 4, -16, -50, 11, 11, -7, -6, 4,
	; 				dw -45, 6, 70, -28, -28, 11, 4, -5
	; 				dw -59, 13, 39, -21, -12, 9, 2, 2
	; 				dw 12, -6, -13, -5, -2, 2, -3, 3
	; 				dw -10, 3, 3, -9, -3, 1, 5, 2
	; 				dw 0, 0, 0, -2, -1, -4, 4, -1
	; 				dw -1, 0, -1, -5, -1, 0, 0, 1
	
	subimage dw 64 dup(?)
	
	
.CODE

; Test code for the IDCT.ASM
; Usage: call function on see output in MS-DOS
; No arguments on the stack
IDCTT PROC FAR
	push bp
	mov bp, sp
	
	; Initialize data segment
	call initializeDCTCoeff
	
	; Do inverse transformation
	mov ax, seg dctCoeff
	push ax
	mov ax, offset dctCoeff
	push ax
	mov ax, seg subimage
	push ax
	mov ax, offset subimage
	push ax
	call iDCT
	
	; Print result
	mov ax, seg subimage
	mov ds, ax
	mov si, offset subimage
	; xor df, df ; TODO is this really necessary ? 
	mov cx, 64
@@:
	lodsw
	push ax
	call PrintNumber
	loop @B
	
	mov sp, bp
	pop bp
	ret 0
IDCTT ENDP

TransposeTest PROC FAR
	push bp
	mov bp, sp
	
	; Initialize data segment
	call initializeDCTCoeff
	
	mov sp, bp
	pop bp
	ret 0
TransposeTest ENDP

initializeDCTCoeff PROC NEAR
	push bp
	mov bp, sp
	
	mov ax, seg dctCoeff
	mov es, ax
	mov di, offset dctCoeff
	
	; Row
	mov ax, -415
	stosw
	mov ax, -26
	stosw
	mov ax, -58
	stosw
	mov ax, 33
	stosw
	mov ax, 56
	stosw
	mov ax, -24
	stosw
	mov ax, -2
	stosw
	mov ax, 0
	stosw
	; Row
	mov ax, 4
	stosw
	mov ax, -16
	stosw
	mov ax, -50
	stosw
	mov ax, 11
	stosw
	mov ax, 11
	stosw
	mov ax, -7
	stosw
	mov ax, -6
	stosw
	mov ax, 4
	stosw
	; Row
	mov ax, -45
	stosw
	mov ax, 6
	stosw
	mov ax, 70
	stosw
	mov ax, -28
	stosw
	mov ax, -28
	stosw
	mov ax, 11
	stosw
	mov ax, 4
	stosw
	mov ax, -5
	stosw
	; Row
	mov ax, -59
	stosw
	mov ax, 13
	stosw
	mov ax, 39
	stosw
	mov ax, -21
	stosw
	mov ax, -12
	stosw
	mov ax, 9
	stosw
	mov ax, 2
	stosw
	mov ax, 2
	stosw
	; Row
	mov ax, 12
	stosw
	mov ax, -6
	stosw
	mov ax, -13
	stosw
	mov ax, -5
	stosw
	mov ax, -2
	stosw
	mov ax, 2
	stosw
	mov ax, -3
	stosw
	mov ax, 3
	stosw
	; Row
	mov ax, -10
	stosw
	mov ax, 3
	stosw
	mov ax, 3
	stosw
	mov ax, -9
	stosw
	mov ax, -3
	stosw
	mov ax, 1
	stosw
	mov ax, 5
	stosw
	mov ax, 2
	stosw
	; Row
	mov ax, 0
	stosw
	mov ax, 0
	stosw
	mov ax, 0
	stosw
	mov ax, -2
	stosw
	mov ax, -1
	stosw
	mov ax, -4
	stosw
	mov ax, 4
	stosw
	mov ax, -1
	stosw
	; Row
	mov ax, -1
	stosw
	mov ax, 0
	stosw
	mov ax, -1
	stosw
	mov ax, -5
	stosw
	mov ax, -1
	stosw
	mov ax, 0
	stosw
	mov ax, 0
	stosw
	mov ax, 1
	stosw
	
	mov sp, bp
	pop bp
	ret 0
initializeDCTCoeff ENDP

END