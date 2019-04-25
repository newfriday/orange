	;org 07c00h

[SECTION .s16]
[BITS 16]
	global _start
_start:
	jmp 07c0h:OffDispStr

OffDispStr	equ	$ - $$
DispStr:
	mov ax, cs
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, 0100h

	;mov eax, DispStr
	mov ax, BootMessage
	mov bp, ax
	mov cx, 16
	mov ax, 01301h
	mov bx, 000ch
	mov dl, 0
	int 10h
	jmp $

BootMessage:		db "Hello, OS world!"
times 	510-($-$$)	db	0
dw 	0xaa55
