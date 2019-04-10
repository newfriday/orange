; ==========================================
; tss.asm
; 编译方法：nasm tss.asm -o tss.bin
; ==========================================

%include	"pm.inc"	; 常量, 宏, 以及一些说明

org 0100h
	jmp	LABEL_BEGIN

[SECTION .gdt]
; GDT
;                              段基址,       段界限     , 属性
LABEL_GDT:	   Descriptor       0,				0,		0   ; 空描述符
LABEL_DESC_INITCODE: Descriptor	0, InitCodeLen - 1,	DA_C + DA_32; 非一致代码段
LABEL_DESC_TASKCODE0: Descriptor	0, Task0CodeLen - 1,	DA_C + DA_32 ; 非一致代码段
LABEL_DESC_TASKCODE1: Descriptor	0, Task1CodeLen - 1,	DA_C + DA_32 ; 非一致代码段
LABEL_DESC_STACK0:  Descriptor	0,	    TopOfStack0,	DA_DRW; 堆栈段 
LABEL_DESC_STACK1:  Descriptor	0,	    TopOfStack1,	DA_DRW; 堆栈段 
LABEL_DESC_TSS0:  Descriptor		0,	TSS0Len -1,    DA_386TSS; 
LABEL_DESC_TSS1:  Descriptor		0,	TSS1Len -1,    DA_386TSS; 
LABEL_DESC_VIDEO:  Descriptor 0B8000h,       0ffffh,    DA_DRW; 显存首地址

; GDT 结束
GdtLen		equ	$ - LABEL_GDT; GDT长度
GdtPtr		dw	GdtLen - 1	; GDT界限
			dd	0		; GDT基地址

; GDT 选择子
SelectorInitCode	equ	(LABEL_DESC_INITCODE	- LABEL_GDT)
SelectorTaskCode0	equ	(LABEL_DESC_TASKCODE0	- LABEL_GDT)
SelectorTaskCode1	equ	(LABEL_DESC_TASKCODE1	- LABEL_GDT)
SelectorStack0		equ (LABEL_DESC_STACK0	- LABEL_GDT) 
SelectorStack1		equ (LABEL_DESC_STACK1	- LABEL_GDT) 
SelectorTSS0		equ (LABEL_DESC_TSS0	- LABEL_GDT)
SelectorTSS1		equ (LABEL_DESC_TSS1	- LABEL_GDT)
SelectorVideo       equ (LABEL_DESC_VIDEO   - LABEL_GDT)
; END of [SECTION .gdt]

; task 堆栈段, 两个task共用次堆栈
[SECTION .s0]
ALIGN	32
[BITS	32]
LABEL_STACK0:
	times	32	db	0
TopOfStack0		equ	$	-	LABEL_STACK0	-	1
; end of .s0

[SECTION .s0]
ALIGN	32
[BITS	32]
LABEL_STACK1:
	times	32	db	0
TopOfStack1		equ	$	-	LABEL_STACK1	-	1
; end of .s0

[SECTION .idt]
LABEL_IDT:
;				选择子					偏移
%rep 255
		Gate	SelectorInitCode,		DummyHandler,	0,	DA_386IGate
%endrep
IdtLen	equ	$	-	LABEL_IDT
IdtPtr	dw	IdtLen	-	1
		dd	0
; END of [SECTION .idt]

; ring0 task0 TSS
[SECTION .tss0]
ALIGN   32
[BITS   32]
LABEL_TSS0:
        DD  0           ; Back
        DD  TopOfStack0	; 0 级堆栈
        DD  SelectorStack0 ; 
        DD  0           ; 1 级堆栈
        DD  0           ; 
        DD  0			; 2 级堆栈
        DD  0			; 
        DD  0           ; CR3
        DD  0           ; EIP
        DD  0           ; EFLAGS
        DD  0           ; EAX
        DD  0           ; ECX
        DD  0           ; EDX
        DD  0           ; EBX
        DD  0           ; ESP
        DD  0           ; EBP
        DD  0           ; ESI
        DD  0           ; EDI
        DD  0           ; ES
        DD  0			; CS
        DD  0			; SS
        DD  0           ; DS
        DD  0           ; FS
        DD  0           ; GS
        DD  0           ; LDT
        DW  0           ; 调试陷阱标志
        DW  $ - LABEL_TSS0 + 2   ; I/O位图基址
        DB  0ffh            ; I/O位图结束标志
TSS0Len      equ $ - LABEL_TSS0

; ring0 task1 TSS1
[SECTION .tss1]
ALIGN   32
[BITS   32]
LABEL_TSS1:
        DD  0           ; Back
        DD  TopOfStack1	; 0 级堆栈
        DD  SelectorStack1 ; 
        DD  0           ; 1 级堆栈
        DD  0           ; 
        DD  0			; 2 级堆栈
        DD  0			; 
        DD  0           ; CR3
        DD  0           ; EIP
        DD  0			; EFLAGS
        DD  0           ; EAX
        DD  0           ; ECX
        DD  0           ; EDX
        DD  0           ; EBX
        DD  0           ; ESP
        DD  0           ; EBP
        DD  0           ; ESI
        DD  0           ; EDI
        DD  0           ; ES
        DD  SelectorTaskCode1; CS
        DD  SelectorStack1; SS
        DD  0           ; DS
        DD  0           ; FS
        DD  0           ; GS
        DD  0           ; LDT
        DW  0           ; 调试陷阱标志
        DW  $ - LABEL_TSS1 + 2   ; I/O位图基址
        DB  0ffh            ; I/O位图结束标志
TSS1Len      equ $ - LABEL_TSS1

[SECTION .s16]
[BITS	16]
;ebx: code base 
;ecx: descripter entry start address 
SetDescBase:
	xor	eax, eax
	mov ax, cs
	shl eax, 4
	add eax, ebx
	mov word [ecx + 2], ax
	shr eax, 16
	mov byte [ecx + 4], al
	mov byte [ecx + 7], ah
	ret

LABEL_BEGIN:
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	mov	ss, ax
	mov	sp, 0100h

	; 保护模式代码段初始化 
	mov ebx, LABEL_SEG_INIT
	mov ecx, LABEL_DESC_INITCODE
	call SetDescBase 	

	mov ebx, LABEL_SEG_TASK0
	mov ecx, LABEL_DESC_TASKCODE0
	call SetDescBase 	

	mov ebx, LABEL_SEG_TASK1
	mov ecx, LABEL_DESC_TASKCODE1
	call SetDescBase 	

	mov ebx, LABEL_STACK0
	mov ecx, LABEL_DESC_STACK0
	call SetDescBase 	

	mov ebx, LABEL_STACK1
	mov ecx, LABEL_DESC_STACK1
	call SetDescBase 	

	mov ebx, LABEL_TSS0
	mov ecx, LABEL_DESC_TSS0
	call SetDescBase 	

	mov ebx, LABEL_TSS1
	mov ecx, LABEL_DESC_TSS1
	call SetDescBase 	

	; 为加载 GDTR 作准备
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_GDT		; eax <- gdt 基地址
	mov	dword [GdtPtr + 2], eax	; [GdtPtr + 2] <- gdt 基地址

	; 加载 GDTR
	lgdt	[GdtPtr]

	; 为加载 IDTR 作准备
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_IDT		; eax <- idt 基地址
	mov	dword [IdtPtr + 2], eax	; [IdtPtr + 2] <- gdt 基地址

	; 关中断
	cli

	lidt	[IdtPtr]

	; 打开地址线A20
	in	al, 92h
	or	al, 00000010b
	out	92h, al

	; 准备切换到保护模式
	mov	eax, cr0
	or	eax, 1
	mov	cr0, eax

	; 真正进入保护模式
	jmp	dword SelectorInitCode:0	; 执行这一句会把 SelectorCode32 装入 cs,
								; 并跳转到 Code32Selector:0  处
; END of [SECTION .s16]

[SECTION .s32]; 32 位代码段. 由实模式跳入.
[BITS	32]
LABEL_SEG_INIT:
	xor	eax, eax
	mov ax, SelectorStack0
	mov ss, ax
	xor	eax, eax
	mov ax, TopOfStack0
	mov sp, ax

	push SelectorTaskCode0
	push 0 

	xor	eax, eax
	mov ax, SelectorStack1
	mov ss, ax
	xor	eax, eax
	mov ax, TopOfStack1
	mov sp, ax

	push SelectorTaskCode1
	push 0 

	mov ebx, 1 
	jmp	SwitchTask

SwitchTask:
OffSwitchTask	equ	SwitchTask	-	$$
	cmp ebx, 1	
	je	.4

	; switch to stack0
	xor	eax, eax
	mov ax, SelectorStack0
	mov ss, ax

	mov ax, TopOfStack0 - 8 
	mov sp, ax

	retf
.4:
	; switch to stack1
	xor	eax, eax
	mov ax, SelectorStack1
	mov ss, ax

	mov ax, TopOfStack1 - 8 
	mov sp, ax

	retf

_DummyHandler:
DummyHandler	equ	_DummyHandler	-	$$
	jmp	$

InitCodeLen	equ	$ - LABEL_SEG_INIT

LABEL_SEG_TASK0:
	mov ax,	SelectorVideo
	mov gs,	ax
	mov edi,(80 * 11 + 79) * 2
	mov ah,	0Ch
	mov al,	'H'
	mov	[gs:edi], ax
	mov ecx, 0ffffffh
.0:
	dec ecx
	jecxz	.1		
	jmp	.0
.1:
	mov ebx, 1
	jmp SelectorInitCode:OffSwitchTask
	jmp SelectorTaskCode0:0

Task0CodeLen	equ	$ -	 LABEL_SEG_TASK0

LABEL_SEG_TASK1:
	mov ax,	SelectorVideo
	mov gs,	ax
	mov edi,(80 * 11 + 79) * 2
	mov ah,	0Ch
	mov al,	'Y'
	mov	[gs:edi], ax
	mov ecx, 0ffffffh
.2:
	dec ecx
	jecxz	.3
	jmp	.2
.3:
	mov ebx, 0
	jmp SelectorInitCode:OffSwitchTask
	jmp SelectorTaskCode1:0
Task1CodeLen	equ	$ -	 LABEL_SEG_TASK1

; END of [SECTION .s32]
