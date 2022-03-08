.286
.model small
.stack 100h
.data
.code

;;;;;;;;;;;;;;;;;;;;;;;  Draw Single Pixel Function  ;;;;;;;;;;;;;;;;;;;;;;;

; draw a single pixel specific to Mode 13h (320x200 with 1 byte per color)
drawPixel:
	color EQU ss:[bp+4] 
	x1 EQU ss:[bp+6]
	y1 EQU ss:[bp+8]

	push	bp
	mov	bp, sp
				; using ax but not pushing it
	push	bx
	push	cx
	push	dx
	push	es ; extra segment register

	; set ES as segment of graphics frame buffer ~ in the extra segment, put the starting address of the video buffer to Mode 13h
	mov	ax, 0A000h ; a000:000
	mov	es, ax ; cannot use immediate directly


	; BX = ( y1 * 320 ) + x1
	mov	bx, x1 ; move the value of x1 into bx
	mov	cx, 320 ; move 320 into cx
	xor	dx, dx ; set dx to 0
	mov	ax, y1 ; move the value of y1 into ax
	mul	cx ; multiply cx by what is in ax and store it in ax = 320 * y1 ~ DX:AX AX is 16 bits = 64k = 65536 
	add	bx, ax ; add bx and ax and store it in bx

	; DX = color
	mov	dx, color ; dx is made up of dh and dl ~ color is dl because the lower is filled first

	; plot the pixel in the graphics frame buffer
	mov	BYTE PTR es:[bx], dl ; starting from the address of the es ; move dl to address of bx ;  BYTE PTR is specify the type being moved

	pop	es
	pop	dx
	pop	cx
	pop	bx

	pop	bp

	ret	6 ; pushed 3 arguements which are word sized ~ 6 bytes

;;;;;;;;;;;;;;;;;;;;;;;  Draw Line Function  ;;;;;;;;;;;;;;;;;;;;;;;

; drawLine(color, x1, y1, x2, y2)
drawLine:
		color EQU ss:[bp+4]
		x1 EQU ss:[bp+6]
		y1 EQU ss:[bp+8]
		x2 EQU ss:[bp+10]
		y2 EQU ss:[bp+12]

		push bp
		mov bp, sp

		push ax
		push bx
		push cx
		push dx

		; abs(y2-y1)
		mov ax, y2
		sub ax, y1 ; ax = y2 - y1

		push ax
		call absolute_value

		mov bx, ax ; abs(y2-y1) is in BX

		; abs(x2-x1)
		mov ax, x2
		sub ax, x1 ; ax = x2 - x1

		push ax
		call absolute_value

		 ;if x2 == x1
		cmp ax, 0
		je drawLineVCases

		; else if abs(y2-y1) < abs(x2-x1)
		cmp bx, ax ; if abs(y2-y1) < abs(x2-x1)
		jl drawLineLowCases ; jump to here if less than ~ // possible error: relative jump out of range // solution: create TASM.cfg file and add /jJUMPS // 
		jmp drawLineCaseHighCases ; else if abs(y2-y1) >= abs(x2-x1)

;;;;;;;;;;;;;;;;;;;;;;;  Triangle Function  ;;;;;;;;;;;;;;;;;;;;;;;

; Draw triangle function

drawTriangle:
		color EQU ss:[bp+4]
		x1 EQU ss:[bp+6]
		y1 EQU ss:[bp+8]
		x2 EQU ss:[bp+10]
		y2 EQU ss:[bp+12]
		x3 EQU ss:[bp+14]
		y3 EQU ss:[bp+16]

		; calling the drawLine function
		push bp
		mov bp, sp

		push ax
		push bx
		push cx
		push dx
		
		push WORD PTR y1	; y1
		push WORD PTR x1	; x1
		push WORD PTR y2	; y2
		push WORD PTR x2	; x2
		push color			; color
		call drawline

		push WORD PTR y1	; y1
		push WORD PTR x1	; x1
		push WORD PTR y3	; y3
		push WORD PTR x3	; x3
		push color			; color
		call drawline

		push WORD PTR y2	; y2
		push WORD PTR x2	; x2
		push WORD PTR y3	; y3
		push WORD PTR x3	; x3
		push color			; color
		call drawline

		pop dx
		pop cx
		pop bx
		pop ax

		mov sp, bp
		pop bp

		ret 10

;;;;;;;;;;;;;;;;;;;;;;;  Vertical Line Case  ;;;;;;;;;;;;;;;;;;;;;;;

drawLineVCases:
		mov ax, y1
		cmp ax, y2
		jg drawLineCaseVDec ; if y1 > y2
		jmp drawLineCaseVInc ; else if y2 >= y1

drawLineCaseVDec:
		;drawLineV(color, x, y2, y1)
		mov cx, y2
again2:
		cmp cx, y1	
		jg done2
		push cx		
		push x1		
		push color	
		call drawPixel
		inc cx		
		jmp again2
done2:
		jmp drawLine_exit

		jmp drawLine_exit

drawLineCaseVInc:

		;drawLineV(color, x, y1, y2)
		mov cx, y1
again1:
		cmp cx, y2	
		jg done1
		push cx		
		push x1		
		push color	
		call drawPixel
		inc cx		
		jmp again1
done1:
		jmp drawLine_exit


;;;;;;;;;;;;;;;;;;;;;;;  Low Cases  ;;;;;;;;;;;;;;;;;;;;;;;

drawLineLowCases:

		mov ax, x1
		cmp ax, x2
		jg drawLineCaseLowDec ; if x1 > x2 
		jmp drawLineCaseLowInc ; else if x2>=x1

drawLineCaseLowDec:

		; drawLineLow(color, x2, y2, x1, y1)
		push y1
		push x1
		push y2
		push x2
		push color
		call drawLineLow
		jmp drawLine_exit


drawLineCaseLowInc:
	
		; drawLineLow(color, x1, y1, x2, y2)
		push y2
		push x2
		push y1
		push x1
		push color
		call drawLineLow ; be careful ~ was previously call drawLine_exit
		jmp drawLine_exit

;;;;;;;;;;;;;;;;;;;;;;;  High Cases  ;;;;;;;;;;;;;;;;;;;;;;;

drawLineCaseHighCases: ; if abs(y2-y1) >= abs(x2-x1)

		mov ax, y1
		cmp ax, y2
		jg drawLineCaseHighDec ; if y1 > y2
		jmp drawLineCaseHighInc ; else if y1 <= y2

drawLineCaseHighDec:

		; drawLineHigh(color, x2, y2, x1, y1)
		push y1
		push x1
		push y2
		push x2
		push color
		call drawLineHigh
		jmp drawLine_exit

drawLineCaseHighInc:

		; drawLineHigh(color, x1, y1, x2, y2)
		push y2
		push x2
		push y1
		push x1
		push color
		call drawLineHigh
		jmp drawLine_exit

;;;;;;;;;;;;;;;;;;;;;;;  Exit Function  ;;;;;;;;;;;;;;;;;;;;;;;

drawLine_exit:

		pop dx
		pop cx
		pop bx
		pop ax

		mov sp, bp
		pop bp

		ret 10

;;;;;;;;;;;;;;;;;;;;;;;  Draw Line High Function  ;;;;;;;;;;;;;;;;;;;;;;;

; drawLineHigh(color, x1, y1, x2, y2)
drawLineHigh:

		color EQU ss:[bp+4]
		x1 EQU ss:[bp+6]
		y1 EQU ss:[bp+8]
		x2 EQU ss:[bp+10]
		y2 EQU ss:[bp+12]

		push bp
		mov bp, sp

		push ax
		push bx
		push cx
		push dx

		sub sp, 12
		delta_x equ word ptr ss:[bp-4]
		delta_y equ word ptr ss:[bp-6]
		x_inc equ word ptr ss:[bp-8]
		D equ word ptr ss:[bp-10]
		x equ word ptr ss:[bp-12]
		y equ word ptr ss:[bp-14]

		; delta_x = x2 - x1
		mov ax, x2
		sub ax, x1
		mov delta_x, ax

		; delta_y = y2-y1
		mov ax, y2
		sub ax, y1
		mov delta_y, ax

		; x_inc = 1
		mov x_inc, 1

		cmp delta_x, 0
		jge drawLineHighDeltaXPos ; if delta_x >= 0

drawLineHighDeltaXNeg: ; else if delta_x < 0
		; x_inc = -1
		neg x_inc ; x_inc becomes -1
		; delta_x = -delta_x
		neg delta_x ; delta_x becomes -delta_x

drawLineHighDeltaXPos:; if delta_x >= 0
		; D = (2 * delta_x) - delta_y
		mov ax, delta_x ; ax = delta_x
		mov bx, 2		; bx = 2
		imul bx ; ax = 2 * delta_x (imul is SIGNED multiply) 
		sub ax, delta_y ; ax = (2 * delta_x) - delta_y
		mov D, ax		; dx = ax

		; y = y1
		mov ax, y1		; ax = y1
		mov y, ax		; y = ax = y1

		; x = x1
		mov ax, x1		; ax = x1
		mov x, ax		; x = ax = x1

		; while y <= y2 ~ for y from y1 --> y2

drawLineHighLoop:
		mov ax, y ; ax = y = y1
		cmp ax, y2 ; if y1 > y2 
		jg drawLineHigh_exit ; go to here when we have reached the end of loop
		; drawPixel(color, x, y) ; else draw the pixel
		push y			; push y1
		push x			; push x1
		push color		; push the color
		call drawPixel	; draw a pixel

		cmp D, 0				; if D > 0
		jg drawLineHighLoopDPos  ; go to here
		jmp drawLineHighLoopDNeg ; else if D <= 0

drawLineHighLoopDPos:; if D > 0
		; x = x + x_inc
		mov ax, x		; ax = x = x1
		add ax, x_inc	; ax = x+x_inc
		mov x, ax		; x = ax
		; D = D + (2 * (delta_x - delta_y))

		mov ax, delta_x	; ax = delta_x
		sub ax, delta_y ; ax = delta_x - delta_y
		mov bx, 2		; bx = 2
		imul bx			; ax = (2 * (delta_x - delta_y))
		add ax, D		; ax = D + (2 * (delta_x - delta_y))
		mov D, ax		; D = D + (2 * (delta_x - delta_y))

		inc y					; increment the value of y
		jmp drawLineHighLoop		; go back to the next iteration of the loop

drawLineHighLoopDNeg: ; if D <=0
		; D = D + 2*delta_x
		mov ax, delta_x
		mov bx, 2
		imul bx ; ax = 2*delta_x
		add ax, D ; ax = D + 2*delta_x
		mov D, ax ; D = D + 2*delta_x

		; inc x
		inc y					; increment the value of x
		jmp drawLineHighLoop		; go back to the next iteration of the loop

drawLineHigh_exit:; the loop is finished
		pop dx
		pop cx
		pop bx
		pop ax

		mov sp, bp
		pop bp

		ret 10

;;;;;;;;;;;;;;;;;;;;;;;  Draw Line Low Function  ;;;;;;;;;;;;;;;;;;;;;;;

; drawLineLow(color, x1, y1, x2, y2)
drawLineLow:
		color EQU ss:[bp+4]
		x1 EQU ss:[bp+6]
		y1 EQU ss:[bp+8]
		x2 EQU ss:[bp+10]
		y2 EQU ss:[bp+12]

		push bp
		mov bp, sp

		push ax
		push bx
		push cx
		push dx

		sub sp, 12
		delta_x equ word ptr ss:[bp-4]
		delta_y equ word ptr ss:[bp-6]
		y_inc equ word ptr ss:[bp-8]
		D equ word ptr ss:[bp-10]
		x equ word ptr ss:[bp-12]
		y equ word ptr ss:[bp-14]

		; delta_x = x2 - x1
		mov ax, x2
		sub ax, x1
		mov delta_x, ax

		; delta_y = y2-y1
		mov ax, y2
		sub ax, y1
		mov delta_y, ax

		; y_inc = 1
		mov y_inc, 1

		cmp delta_y, 0
		jge drawLineLowDeltaYPos ; if delta_y >= 0

drawLineLowDeltaYNeg: ; else if delta_y < 0

		; y_inc = -1
		neg y_inc ; y_inc becomes -1
		; delta_y = -delta_y
		neg delta_y ; delta_y becomes -delta_y

drawLineLowDeltaYPos:

		; D = (2 * delta_y) - delta_x
		mov ax, delta_y ; ax = delta_y
		mov bx, 2		; bx = 2
		imul bx ; ax = 2 * delta_y (imul is SIGNED multiply) 
		sub ax, delta_x ; ax = (2 * delta_y) - delta_x
		mov D, ax		; dx = ax

		; y = y1
		mov ax, y1		; ax = y1
		mov y, ax		; y = ax = y1

		; x = x1
		mov ax, x1		; ax = x1
		mov x, ax		; x = ax = x1

		; while x <= x2 ~ for x from x1 --> x2

drawLineLowLoop:

		mov ax, x ; ax = x = x1
		cmp ax, x2 ; if x1 > x2 
		jg drawLineLow_exit ; go to here when we have reached the end of loop
		; drawPixel(color, x, y) ; else draw the pixel
		push y			; push y1
		push x			; push x1
		push color		; push the color
		call drawPixel	; draw a pixel

		cmp D, 0				; if D > 0
		jg drawLineLowLoopDPos  ; go to here
		jmp drawLineLowLoopDNeg ; else if D <= 0

drawLineLowLoopDPos:; if D > 0

		; y = y + y_inc
		mov ax, y		; ax = y = y1
		add ax, y_inc	; ax = y+y_inc
		mov y, ax		; y = ax
		; D = D + (2 * (delta_y - delta_x))

		mov ax, delta_y	; ax = delta_y
		sub ax, delta_x ; ax = delta_y - delta_x
		mov bx, 2		; bx = 2
		imul bx			; ax = (2 * (delta_y - delta_x))
		add ax, D		; ax = D + (2 * (delta_y - delta_x))
		mov D, ax		; D = D + (2 * (delta_y - delta_x))

		inc x					; increment the value of x
		jmp drawLineLowLoop		; go back to the next iteration of the loop

drawLineLowLoopDNeg: ; if D <=0

		; D = D + 2*delta_y
		mov ax, delta_y
		mov bx, 2
		imul bx ; ax = 2*delta_y
		add ax, D ; ax = D + 2*delta_y
		mov D, ax ; D = D + 2*delta_y

		; inc x
		inc x					; increment the value of x
		jmp drawLineLowLoop		; go back to the next iteration of the loop

drawLineLow_exit:; the loop is finished

		pop dx
		pop cx
		pop bx
		pop ax

		mov sp, bp
		pop bp

		ret 10

;;;;;;;;;;;;;;;;;;;;;;;  Absolute Value Function  ;;;;;;;;;;;;;;;;;;;;;;;

absolute_value: ; returns absolute value of x in AX
		x EQU ss:[bp+4]

		push bp
		mov bp, sp

		mov ax, x
		cmp ax, 0
		jl absneg ; jl jumps less (signed) vs jb jump below (unsigned)
		jmp abspos

absneg:
		neg ax

abspos:
		mov sp, bp
		pop bp
		ret 2

;;;;;;;;;;;;;;;;;;;;;;; Start of Program ;;;;;;;;;;;;;;;;;;;;;;;

start:
		; intialize data segment
		mov ax, @data
		mov ds, ax

		; set video mode - 320x200 256-color mode
		mov ax, 4F02h
		mov bx, 13h
		int 10h

;;;;;;;;;;;;;;;;;;;;;;;  Testing  ;;;;;;;;;;;;;;;;;;;;;;;

		; Slope between 0 and 1, increasing ~ |y2-y1| = 10 < |x2-x1| = 30
		;push WORD PTR 80 ; y2
		;push WORD PTR 40 ; x2
		;push WORD PTR 70 ; y1
		;push WORD PTR 10 ; x1
		;push 0005h		 ; color
		;call drawline

		; Slope between -1 and 0, increasing ~ |y2-y1| = 10 < |x2-x1| = 30
		;push WORD PTR 70 ; y2
		;push WORD PTR 90 ; x2
		;push WORD PTR 80 ; y1
		;push WORD PTR 60 ; x1
		;push 0006h		 ; color
		;call drawline

		; Slope between 0 and 1, decreasing ~ |y2-y1| = 10 < |x2-x1| = 30 
		;push WORD PTR 170 ; y2
		;push WORD PTR 10 ; x2
		;push WORD PTR 180 ; y1
		;push WORD PTR 40 ; x1
		;push 000Dh		 ; color
		;call drawline

		; Slope between -1 and 0, decreasing ~ |y2-y1| = 10 < |x2-x1| = 30
		;push WORD PTR 180 ; y2
		;push WORD PTR 60 ; x2
		;push WORD PTR 170 ; y1
		;push WORD PTR 90 ; x1
		;push 000Eh		 ; color
		;call drawline

		; horizontal line
		;push WORD PTR 125 ; y2
		;push WORD PTR 225 ; x2
		;push WORD PTR 125 ; y1
		;push WORD PTR 25 ; x1
		;push 000Eh		 ; color
		;call drawline

		; vertical line
		;push WORD PTR 125 ; y2
		;push WORD PTR 25 ; x2
		;push WORD PTR 190 ; y1
		;push WORD PTR 25 ; x1
		;push 000Eh		 ; color
		;call drawline

;;;;;;;;;;;;;;;;;;;;;;;  Drawing a triangle  ;;;;;;;;;;;;;;;;;;;;;;;
		
	;;;;;; code to draw triangle here ;;;;;

		push WORD PTR 180 ; y3
		push WORD PTR 60 ; x3
		push WORD PTR 10 ; y2
		push WORD PTR 160 ; x2
		push WORD PTR 180 ; y1
		push WORD PTR 260 ; x1
		push 0002h		 ; color
		call drawTriangle

	;;;;;; end of triangle drawing ;;;;;

;;;;;;;;;;;;;;;;;;;;;;;  End of Program  ;;;;;;;;;;;;;;;;;;;;;;;

		; prompt for a key
		
		mov ah, 0
		int 16h

		; switch back to text mode
		
		mov ax, 4f02h
		mov bx, 3
		int 10h

		mov ax, 4C00h
		int 21h

END start