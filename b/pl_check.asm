; ==========================================
; pl_check.asm
; 编译方法：nasm pl_check.asm -o pl_check.bin
; ==========================================

%include	"pm.inc"	; 常量, 宏, 以及一些说明

org	7c00h
	jmp	LABEL_BEGIN

[SECTION .gdt]
; GDT
;                              段基址,       段界限     , 属性
LABEL_GDT:	   Descriptor       0,				0,		0   ; 空描述符
LABEL_DESC_CODE32: Descriptor	0, SegCode32Len - 1,	DA_C + DA_32; 非一致代码段
LABEL_DESC_CODE32D2: Descriptor	0, SegCode32Len - 1,	DA_C + DA_32 + DA_DPL2; 非一致代码段
LABEL_DESC_VIDEO:  Descriptor 0B8000h,	     0ffffh,	DA_DRW + DA_DPL3; 显存首地址
LABEL_DESC_STACK0:  Descriptor	0,	    TopOfStack0,	DA_DRW + DA_DPL0 ; 堆栈段 
LABEL_DESC_STACK2:  Descriptor	0,	    TopOfStack2,	DA_DRW + DA_DPL2 ; 堆栈段 
LABEL_DESC_TSS:  Descriptor		0,		  TSSLen -1,    DA_386TSS; 堆栈段 

; 门					选择子,		段内偏移,	参数个数,	属性 
LABEL_CALL_GATE: Gate	SelectorCode32R2D0,	      0,    0,	DA_386CGate + DA_DPL3

; GDT 结束
GdtLen		equ	$ - LABEL_GDT	; GDT长度
GdtPtr		dw	GdtLen - 1	; GDT界限
			dd	0		; GDT基地址

; GDT 选择子
SelectorCode32		equ	(LABEL_DESC_CODE32	- LABEL_GDT)
SelectorCode32R1D0	equ	(LABEL_DESC_CODE32	- LABEL_GDT) + SA_RPL1
SelectorCode32R2D0	equ	(LABEL_DESC_CODE32	- LABEL_GDT) + SA_RPL2
SelectorCode32R3D0	equ	(LABEL_DESC_CODE32	- LABEL_GDT) + SA_RPL3

SelectorCode32R2D2	equ	(LABEL_DESC_CODE32D2- LABEL_GDT) + SA_RPL2

SelectorVideo		equ	(LABEL_DESC_VIDEO	- LABEL_GDT) + SA_RPL3
SelectorStack0		equ (LABEL_DESC_STACK0	- LABEL_GDT) 
SelectorStack2		equ (LABEL_DESC_STACK2	- LABEL_GDT) + SA_RPL2
SelectorTSS			equ (LABEL_DESC_TSS		- LABEL_GDT)

SelectorCallGateTest	equ	(LABEL_CALL_GATE	- LABEL_GDT) + SA_RPL2
; END of [SECTION .gdt]

; ring0 堆栈段
[SECTION .s0]
ALIGN	32
[BITS	32]
LABEL_STACK0:
	times	32	db	0
TopOfStack0		equ	$	-	LABEL_STACK0	-	1
; end of .s0

; ring2 堆栈段
[SECTION .s2]
ALIGN	32
[BITS	32]
LABEL_STACK2:
	times	32	db	0
TopOfStack2		equ	$	-	LABEL_STACK2	-	1
; end of .s2

; TSS
[SECTION .tss]
ALIGN   32
[BITS   32]
LABEL_TSS:
        DD  0           ; Back
        DD  TopOfStack0 ; 0 级堆栈
        DD  SelectorStack0 ; 
        DD  0           ; 1 级堆栈
        DD  0           ; 
        DD  TopOfStack2	; 2 级堆栈
        DD  SelectorStack2 ; 
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
        DD  0           ; CS
        DD  0           ; SS
        DD  0           ; DS
        DD  0           ; FS
        DD  0           ; GS
        DD  0           ; LDT
        DW  0           ; 调试陷阱标志
        DW  $ - LABEL_TSS + 2   ; I/O位图基址
        DB  0ffh            ; I/O位图结束标志
TSSLen      equ $ - LABEL_TSS

[SECTION .s16]
[BITS	16]
LABEL_BEGIN:
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	mov	ss, ax
	mov	sp, 0100h

	; gdt初始化 32 位代码段描述符
	xor	eax, eax
	mov	ax, cs
	shl	eax, 4
	add	eax, LABEL_SEG_CODE32
	mov	word [LABEL_DESC_CODE32 + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_CODE32 + 4], al
	mov	byte [LABEL_DESC_CODE32 + 7], ah

	; gdt初始化 32 位代码段描述符 ring2
	xor	eax, eax
	mov	ax, cs
	shl	eax, 4
	add	eax, LABEL_SEG_CODE32
	mov	word [LABEL_DESC_CODE32D2 + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_CODE32D2 + 4], al
	mov	byte [LABEL_DESC_CODE32D2 + 7], ah

	; gdt写入stack3数据段地址
	xor	eax, eax
	add	eax, LABEL_STACK2 
	mov	word [LABEL_DESC_STACK2 + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_STACK2 + 4], al
	mov	byte [LABEL_DESC_STACK2 + 7], ah

	; gdt初始化TSS 
	xor	eax, eax
	mov	ax, cs
	shl	eax, 4
	add	eax, LABEL_TSS
	mov	word [LABEL_DESC_TSS + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_TSS + 4], al
	mov	byte [LABEL_DESC_TSS + 7], ah

	; 为加载 GDTR 作准备
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_GDT		; eax <- gdt 基地址
	mov	dword [GdtPtr + 2], eax	; [GdtPtr + 2] <- gdt 基地址

	; 加载 GDTR
	lgdt	[GdtPtr]

	; 关中断
	cli

	; 打开地址线A20
	in	al, 92h
	or	al, 00000010b
	out	92h, al

	; 准备切换到保护模式
	mov	eax, cr0
	or	eax, 1
	mov	cr0, eax

	; 真正进入保护模式
	jmp	dword SelectorCode32:0	; 执行这一句会把 SelectorCode32 装入 cs,
					; 并跳转到 Code32Selector:0  处
; END of [SECTION .s16]

[SECTION .s32]; 32 位代码段. 由实模式跳入.
[BITS	32]
LABEL_SEG_CODE32:
	str ax				; 读取TR
	cmp ax,	SelectorTSS	; 检查TR是否被加载，如果加载不再重复
	je	.1				

	mov ax,	SelectorTSS	; 加载TR
	ltr ax
.1:
	mov ax,	cs			
	and	ax,	10b	
	cmp	ax,	10b			; 判断CPL
	je	.2				; 如果CPL!=2，retf到ring2，否则跳转到.2执行测试代码

	push	SelectorStack2	
	push	TopOfStack2
	push	SelectorCode32R2D2	
	push	0
	retf	
.2:						; 测试代码，CPL=2
	mov	ax, SelectorVideo
	mov	gs, ax			; 视频段选择子(目的)
	mov	edi, (80 * 11 + 79) * 2	; 屏幕第 11 行, 第 79 列。
	mov	ah, 0Ch			; 0000: 黑底    1100: 红字
	mov	al, 'P'
	mov	[gs:edi], ax
									; RPL = 2, CPL = 2 
	call	SelectorCallGateTest:0	; DPL_G = 2, RPL_G = 2		
									; DPL_B = 0
SegCode32Len	equ	$ - LABEL_SEG_CODE32
; END of [SECTION .s32]
