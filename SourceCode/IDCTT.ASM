; IDCTT.ASM
; -------------
; Contains Test Code for all the procedures in IDCT.ASM
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
	
	arrayOne dw 8 dup(0)
	arrayTwo dw 8 dup(0)
	arrayThree dw 8 dup(0)
	
	; Messages for debugging
	msgTranspose db 'Executing Transpose:$'
	msgIDCT db 'Executing IDCT:$'
	msgArrayAdd db 'Executing ArrayAdd: $'
	msgArraySub db 'Executing ArraySub (First array - Second array): $'
	msgArraySar db 'Executing ArraySAR: $'
	msgScale db 'Executing Scaling: $'
	
.CODE

; Test code for the procedure iDCT
; Usage: call function on see output in MS-DOS
; No arguments on the stack
IDCTT PROC FAR
	push bp
	mov bp, sp
	
	; Initialize data segment
	mov ax, seg dctCoeff
	push ax
	mov ax, offset dctCoeff
	push ax
	call intializeWordMatrixDCT
	
	mov ax, offset msgData
	push ax
	call PrintString
	
	; Print the data
	mov ax, seg dctCoeff
	push ax
	mov ax, offset dctCoeff
	push ax
	mov ax, 64
	push ax
	call PrintWordSegment
	
	mov ax, offset msgIDCT
	push ax
	call PrintString
	
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
	
	mov ax, seg subimage
	push ax
	mov ax, offset subimage
	push ax
	mov ax, 64
	push ax
	call PrintWordSegment
	
	mov sp, bp
	pop bp
	ret 0
IDCTT ENDP

; Test code for the procedure MatrixTranspose
; No arguments on the stack
TransposeTest PROC FAR
	push bp
	mov bp, sp
		
	; Initialize data segment
	mov ax, seg dctCoeff
	push ax
	mov ax, offset dctCoeff
	push ax
	call intializeWordMatrixDCT
	
	mov ax, offset msgData
	push ax
	call PrintString
	
	; Print the data
	mov ax, seg dctCoeff
	push ax
	mov ax, offset dctCoeff
	push ax
	mov ax, 64
	push ax
	call PrintWordSegment
	
	mov ax, offset msgTranspose
	push ax
	call PrintString
	
	; calculate Transpose 
	mov ax, seg dctCoeff
	push ax
	mov ax, offset dctCoeff
	push ax
	mov ax, seg subimage
	push ax
	mov ax, offset subimage
	push ax
	call MatrixTranspose
	
	; Print the result
	mov ax, seg subimage
	push ax
	mov ax, offset subimage
	push ax
	mov ax, 64
	push ax
	call PrintWordSegment
	
	mov sp, bp
	pop bp
	ret 0
TransposeTest ENDP

; Test code for the procedure ArrayADD
; No arguments on the stack
ArrayADDTest PROC FAR
	push bp
	mov bp, sp
	
	; First Array
	mov ax, seg arrayOne
	push ax
	mov ax, offset arrayOne
	push ax
	call initializeWordArray
	
	mov ax, offset msgData
	push ax
	call PrintString
	
	mov ax, seg arrayOne
	push ax
	mov ax, offset arrayOne
	push ax
	mov ax, 8
	push ax
	call PrintWordSegment
	
	; Second Array
	mov ax, seg arrayTwo
	push ax
	mov ax, offset arrayTwo
	push ax
	call initializeWordArray
	
	mov ax, offset msgData
	push ax
	call PrintString
	
	mov ax, seg arrayOne
	push ax
	mov ax, offset arrayOne
	push ax
	mov ax, 8
	push ax
	call PrintWordSegment
	
	; Elementwise addition of the two arrays
	mov ax, offset msgArrayAdd
	push ax
	call PrintString
	
	; set ds and es for procedure ArrayADD
	mov ax, seg arrayOne
	mov es, ax
	mov ds, ax
	mov ax, offset arrayOne
	push ax
	mov ax, offset arrayTwo
	push ax
	mov ax, offset arrayThree
	push ax
	call ArrayADD
	
	
	mov ax, seg arrayThree
	push ax
	mov ax, offset arrayThree
	push ax
	mov ax, 8
	push ax
	call PrintWordSegment
	
	
	mov sp, bp
	pop bp
	ret 0
ArrayADDTest ENDP

; Test code for the procedure ArraySUB
; No arguments on the stack
ArraySUBTest PROC FAR
	push bp
	mov bp, sp
	
	; First Array (usage of arrayADD method for having not the same 2 arrays)
	mov ax, seg arrayOne
	push ax
	mov ax, offset arrayOne
	push ax
	call initializeWordArray
	
	; set ds and es for procedure ArrayADD
	mov ax, seg arrayOne
	mov es, ax
	mov ds, ax
	mov ax, offset arrayOne
	push ax
	mov ax, offset arrayOne
	push ax
	mov ax, offset arrayTwo
	push ax
	call ArrayADD
	
	mov ax, offset msgData
	push ax
	call PrintString
	
	mov ax, seg arrayTwo
	push ax
	mov ax, offset arrayTwo
	push ax
	mov ax, 8
	push ax
	call PrintWordSegment
	
	; Second Array
	mov ax, seg arrayThree
	push ax
	mov ax, offset arrayThree
	push ax
	call initializeWordArray
	
	mov ax, offset msgData
	push ax
	call PrintString
	
	mov ax, seg arrayThree
	push ax
	mov ax, offset arrayThree
	push ax
	mov ax, 8
	push ax
	call PrintWordSegment
	
	; Elementwise substraction of the two arrays
	mov ax, offset msgArraySub
	push ax
	call PrintString
	
	; set ds and es for procedure ArraySUB
	mov ax, seg arrayOne
	mov es, ax
	mov ds, ax
	mov ax, offset arrayTwo
	push ax
	mov ax, offset arrayThree
	push ax
	mov ax, offset arrayOne
	push ax
	call ArraySUB
	
	
	mov ax, seg arrayOne
	push ax
	mov ax, offset arrayOne
	push ax
	mov ax, 8
	push ax
	call PrintWordSegment
	
	mov sp, bp
	pop bp
	ret 0
ArraySUBTest ENDP

; Test code for the procedure ArraySAR
; Executes a division by two
; No arguments on the stack
ArraySARTest PROC FAR
	push bp
	mov bp, sp
	
	; First Array
	mov ax, seg arrayOne
	push ax
	mov ax, offset arrayOne
	push ax
	call initializeWordArray
	
	mov ax, offset msgData
	push ax
	call PrintString
	
	mov ax, seg arrayOne
	push ax
	mov ax, offset arrayOne
	push ax
	mov ax, 8
	push ax
	call PrintWordSegment
	
	; Elementwise SAR of the array
	mov ax, offset msgArraySar
	push ax
	call PrintString
	
	; set ds and es for procedure ArrayADD
	mov ax, seg arrayOne
	mov es, ax
	mov ds, ax
	mov ax, offset arrayOne
	push ax
	mov ax, 1 ; Division by two
	push ax
	mov ax, offset arrayTwo
	push ax
	call ArraySAR
	
	
	mov ax, seg arrayTwo
	push ax
	mov ax, offset arrayTwo
	push ax
	mov ax, 8
	push ax
	call PrintWordSegment
	
	mov sp, bp
	pop bp
	ret 0
ArraySARTest ENDP

; Test code for the procedure MatrixScale
; Executes a division by 8 on each element and makes sure that each entry is in
; the range [0, 255]
; No arguments on the stack
MatrixScaleTest PROC FAR
	push bp
	mov bp, sp
	
	; test
	xor ah, ah
	mov al, 200
	push ax
	call PrintNumber
	
	; Initialize data segment
	mov ax, seg dctCoeff
	push ax
	mov ax, offset dctCoeff
	push ax
	call initializeWordMatrixLarge
	
	mov ax, offset msgData
	push ax
	call PrintString
	
	; Print the data
	mov ax, seg dctCoeff
	push ax
	mov ax, offset dctCoeff
	push ax
	mov ax, 64
	push ax
	call PrintWordSegment
	
	mov ax, offset msgScale
	push ax
	call PrintString
	
	; calculate Scaled Matrix 
	mov ax, seg dctCoeff
	push ax
	mov ax, offset dctCoeff
	push ax
	call MatrixScale
	
	; Print the result
	mov ax, seg dctCoeff
	push ax
	mov ax, offset dctCoeff
	push ax
	mov ax, 64
	push ax
	call PrintWordSegment
	
	mov sp, bp
	pop bp
	ret 0
MatrixScaleTest ENDP

END