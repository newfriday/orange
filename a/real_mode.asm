	org	07c00h			; 告诉编译器程序加载到7c00处
	jmp	07c0h:DispStrOff

code:
times	10	db	0
	;	never reach here

DispStrOff	equ	$	-	$$
DispStr:
	mov	ax, BootMessage
	mov	bp, ax			; ES:BP = 串地址
	mov	cx, 16			; CX = 串长度
	mov	ax, 01301h		; AH = 13,  AL = 01h
	mov	bx, 000ch		; 页号为0(BH = 0) 黑底红字(BL = 0Ch,高亮)
	mov	dl, 0
	int	10h			; 10h 号中断
	jmp $

BootMessage:		db	"Hello, OS world!"
