.MODEL large

externdef TBHuffman:BYTE ; Huffman Tables

.CODE

entropyDecoding PROC FAR
	push bp
	mov bp, sp
	
	mov sp, bp
	pop bp
	ret 0
entropyDecoding ENDP

END