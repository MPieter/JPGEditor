; IDCT.ASM
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
	msgData db 'The data:$'
	msgTranspose db 'Executing Transpose$'
	msgIDCT db 'Executing IDCT:$'
	msgArrayAdd db 'Executing ArrayAdd: $'
	msgArraySub db 'Executing ArraySub (First array - Second array): $'
	msgArraySar db 'Executing ArraySAR: $'
	
	
.CODE

; Test code for the procedure iDCT
; Usage: call function on see output in MS-DOS
; No arguments on the stack
IDCTT PROC FAR
	push bp
	mov bp, sp
	
	; Initialize data segment
	call initializeDCTCoeff
	
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
	call PrintDataSegment
	
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
	call PrintDataSegment
	
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
	call initializeDCTCoeff
	
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
	call PrintDataSegment
	
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
	call PrintDataSegment
	
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
	call initializeArray
	
	mov ax, offset msgData
	push ax
	call PrintString
	
	mov ax, seg arrayOne
	push ax
	mov ax, offset arrayOne
	push ax
	mov ax, 8
	push ax
	call PrintDataSegment
	
	; Second Array
	mov ax, seg arrayTwo
	push ax
	mov ax, offset arrayTwo
	push ax
	call initializeArray
	
	mov ax, offset msgData
	push ax
	call PrintString
	
	mov ax, seg arrayOne
	push ax
	mov ax, offset arrayOne
	push ax
	mov ax, 8
	push ax
	call PrintDataSegment
	
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
	call PrintDataSegment
	
	
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
	call initializeArray
	
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
	call PrintDataSegment
	
	; Second Array
	mov ax, seg arrayThree
	push ax
	mov ax, offset arrayThree
	push ax
	call initializeArray
	
	mov ax, offset msgData
	push ax
	call PrintString
	
	mov ax, seg arrayThree
	push ax
	mov ax, offset arrayThree
	push ax
	mov ax, 8
	push ax
	call PrintDataSegment
	
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
	call PrintDataSegment
	
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
	call initializeArray
	
	mov ax, offset msgData
	push ax
	call PrintString
	
	mov ax, seg arrayOne
	push ax
	mov ax, offset arrayOne
	push ax
	mov ax, 8
	push ax
	call PrintDataSegment
	
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
	call PrintDataSegment
	
	mov sp, bp
	pop bp
	ret 0
ArraySARTest ENDP

; Prints the value of the data
; Argument 1 = segment address of data
; Argument 2 = offset address of current data block in data
; Argument 3 = data length
; Note: inserts automatically a new line after 8 values
PrintDataSegment PROC NEAR
	push bp
	mov bp, sp
	
	; Print result
	mov ax, [bp + 4][4]
	mov ds, ax
	mov si, [bp + 4][2]
	; xor df, df ; TODO is this really necessary ? 
	mov cx, [bp + 4][0]
	mov bx, 8
@@:
	lodsw
	push ax
	call PrintNumber
	call PrintSpace
	dec bx
	cmp bx, 0
	jne ContinueLoop
	call PrintNewLine
	mov bx, 8
ContinueLoop:
	loop @B
	
	mov sp, bp
	pop bp
	ret 0
PrintDataSegment ENDP

; Initializes an array of length 8 with data
; Arguments on the stack:
; Argument 1 = segment address of array
; Argument 2 = offset address of array
initializeArray PROC NEAR
	push bp
	mov bp, sp
	
	mov ax, [bp + 4][2]
	mov es, ax
	mov di, [bp + 4][0]
	
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
	
	mov sp, bp
	pop bp
	ret 0
initializeArray ENDP

; Initializes the data in data "dctCoeff" with dummy data 
; No arguments on the stack
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