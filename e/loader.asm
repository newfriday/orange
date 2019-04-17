; ==========================================
; pl_check.asm
; ���뷽����nasm pl_check.asm -o pl_check.bin
; ==========================================

%include	"pm.inc"	; ����, ��, �Լ�һЩ˵��

org	0100h
	jmp	LABEL_BEGIN

[SECTION .gdt]
; GDT
;                              �λ�ַ,       �ν���     , ����
LABEL_GDT:	   Descriptor       0,				0,		0   ; ��������
LABEL_DESC_INITCODE: Descriptor	0, SegCode32Len - 1,	DA_C + DA_32; ��һ�´����
LABEL_DESC_INITCODED2: Descriptor	0, SegCode32Len - 1,	DA_C + DA_32 + DA_DPL2; ��һ�´����
LABEL_DESC_VIDEO:  Descriptor 0B8000h,	     0ffffh,	DA_DRW + DA_DPL3; �Դ��׵�ַ
LABEL_DESC_STACK0:  Descriptor	0,	    TopOfStack0,	DA_DRW; ��ջ�� 
LABEL_DESC_STACK2:  Descriptor	0,	    TopOfStack2,	DA_DRW + DA_DPL2 ; ��ջ�� 
LABEL_DESC_TASK:  Descriptor	0,	    TopOfTask,		DA_DRW ; ��ջ�� 
LABEL_DESC_TSS:  Descriptor		0,		TSSLen -1,    DA_386TSS; TSS�� 
LABEL_DESC_TSS1:  Descriptor		0,	TSS1Len -1,    DA_386TSS; TSS�� 

; GDT ����
GdtLen		equ	$ - LABEL_GDT	; GDT����
GdtPtr		dw	GdtLen - 1	; GDT����
			dd	0		; GDT����ַ

; GDT ѡ����
SelectorInitCode		equ	(LABEL_DESC_INITCODE	- LABEL_GDT)
SelectorInitCodeD2		equ	(LABEL_DESC_INITCODED2	- LABEL_GDT) + SA_RPL2
SelectorVideo		equ	(LABEL_DESC_VIDEO	- LABEL_GDT) + SA_RPL3
SelectorStack0		equ (LABEL_DESC_STACK0	- LABEL_GDT)
SelectorStack2		equ (LABEL_DESC_STACK2	- LABEL_GDT) + SA_RPL2
SelectorTask		equ (LABEL_DESC_TASK	- LABEL_GDT)
SelectorTSS			equ (LABEL_DESC_TSS		- LABEL_GDT)
SelectorTSS1		equ (LABEL_DESC_TSS1	- LABEL_GDT)
; END of [SECTION .gdt]

; ring0 ��ջ��
[SECTION .s0]
ALIGN	32
[BITS	32]
LABEL_STACK0:
	times	32	db	0
TopOfStack0		equ	$	-	LABEL_STACK0	-	1
; end of .s0

; ring2 ��ջ��
[SECTION .s2]
ALIGN	32
[BITS	32]
LABEL_STACK2:
	times	32	db	0
TopOfStack2		equ	$	-	LABEL_STACK2	-	1
; end of .s2

[SECTION .s2]
ALIGN	32
[BITS	32]
LABEL_TASK:
	times	32	db	0
TopOfTask		equ	$	-	LABEL_TASK	-	1

[SECTION .idt]
LABEL_IDT:
;				ѡ����					ƫ��
.000h:	Gate	SelectorInitCode,		DEHandler,		0,	DA_386IGate + DA_DPL2
%rep 127 
		Gate	SelectorInitCode,		DummyHandler,	0,	DA_386IGate
%endrep
.080h:	Gate	SelectorTSS1,			0,				0,	DA_TaskGate	+ DA_DPL3;������	

IdtLen	equ	$	-	LABEL_IDT
IdtPtr	dw	IdtLen	-	1
		dd	0
; END of [SECTION .idt]

; TSS
[SECTION .tss]
ALIGN   32
[BITS   32]
LABEL_TSS:
        DD  0           ; Back
        DD  TopOfStack0	; 0 ����ջ
        DD  SelectorStack0	; 
        DD  0           ; 1 ����ջ
        DD  0           ; 
        DD  TopOfStack2	; 2 ����ջ
        DD  SelectorStack2 ; 
        DD  0           ; CR3
        DD  0			; EIP
        DD  0           ; EFLAGS
        DD  0           ; EAX
        DD  0           ; ECX
        DD  0           ; EDX
        DD  0           ; EBX
        DD  0			; ESP
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
        DW  0           ; ���������־
        DW  $ - LABEL_TSS + 2   ; I/Oλͼ��ַ
        DB  0ffh            ; I/Oλͼ������־
TSSLen      equ $ - LABEL_TSS

; TSS
[SECTION .tss]
ALIGN   32
[BITS   32]
LABEL_TSS1:
        DD  0           ; Back
        DD  TopOfStack0	; 0 ����ջ
        DD  SelectorStack0	; 
        DD  0           ; 1 ����ջ
        DD  0           ; 
        DD  TopOfStack2	; 2 ����ջ
        DD  SelectorStack2 ; 
        DD  0           ; CR3
        DD  UsrHandler	; EIP
        DD  0           ; EFLAGS
        DD  0           ; EAX
        DD  0           ; ECX
        DD  0           ; EDX
        DD  0           ; EBX
        DD  TopOfTask   ; ESP
        DD  0           ; EBP
        DD  0           ; ESI
        DD  0           ; EDI
        DD  0           ; ES
        DD  SelectorInitCode; CS
        DD  SelectorTask; SS
        DD  0           ; DS
        DD  0           ; FS
        DD  0           ; GS
        DD  0           ; LDT
        DW  0           ; ���������־
        DW  $ - LABEL_TSS1 + 2   ; I/Oλͼ��ַ
        DB  0ffh            ; I/Oλͼ������־
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

	; ����ģʽ����γ�ʼ�� 
	mov ebx, LABEL_SEG_INIT
	mov ecx, LABEL_DESC_INITCODE
	call SetDescBase 	

	mov ebx, LABEL_SEG_INIT
	mov ecx, LABEL_DESC_INITCODED2
	call SetDescBase 	

	mov ebx, LABEL_STACK0
	mov ecx, LABEL_DESC_STACK0
	call SetDescBase 	

	mov ebx, LABEL_STACK2
	mov ecx, LABEL_DESC_STACK2
	call SetDescBase 	

	mov ebx, LABEL_TASK
	mov ecx, LABEL_DESC_TASK
	call SetDescBase 	

	mov ebx, LABEL_TSS
	mov ecx, LABEL_DESC_TSS
	call SetDescBase 	

	mov ebx, LABEL_TSS1
	mov ecx, LABEL_DESC_TSS1
	call SetDescBase 	

	; Ϊ���� GDTR ��׼��
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_GDT		; eax <- gdt ����ַ
	mov	dword [GdtPtr + 2], eax	; [GdtPtr + 2] <- gdt ����ַ

	; ���� GDTR
	lgdt	[GdtPtr]

    ; Ϊ���� IDTR ��׼��
    xor eax, eax
    mov ax, ds
    shl eax, 4
    add eax, LABEL_IDT      ; eax <- idt ����ַ
    mov dword [IdtPtr + 2], eax ; [IdtPtr + 2] <- gdt ����ַ

	; ���ж�
	cli

	; ���� IDTR
	lidt    [IdtPtr]

	; �򿪵�ַ��A20
	in	al, 92h
	or	al, 00000010b
	out	92h, al

	; ׼���л�������ģʽ
	mov	eax, cr0
	or	eax, 1
	mov	cr0, eax

	; �������뱣��ģʽ
	jmp	dword SelectorInitCode:0	; ִ����һ���� SelectorInitCode װ�� cs,
					; ����ת�� Code32Selector:0  ��
; END of [SECTION .s16]

[SECTION .s32]; 32 λ�����. ��ʵģʽ����.
[BITS	32]
LABEL_SEG_INIT:
	xor eax, eax
	mov es, ax
	mov ds, ax

	str ax				; ��ȡTR
	cmp ax,	SelectorTSS	; ���TR�Ƿ񱻼��أ�������ز����ظ�
	je	.1				

	mov ax,	SelectorTSS	; ����TR
	ltr ax
.1:
	mov ax,	cs			
	and	ax,	10b	
	cmp	ax,	10b			; �ж�CPL
	je	.2				; ���CPL!=2��retf��ring2��������ת��.2ִ�в��Դ���

	mov ax, SelectorStack0
	mov ss, ax
	mov sp, TopOfStack0

	push	SelectorStack2	
	push	TopOfStack2
	push	SelectorInitCodeD2	
	push	0
	retf	
.2:						; ���Դ��룬CPL=2
    ;int 0				; ģ���0ָ��

    ;mov ax, 06h		; ����ϵͳ�����ĳ�0�쳣(6 % 0)
    ;mov bl, 00h
    ;div bl  

	int 80h
	jmp $

; bx: line 
; cx: column
; dl: character
_PrintChar:
PrintChar	equ	_PrintChar	-	$$
	mov ax, bx
	mov bl, 80	
	mul bl		; 80 * line = ax 

	add	ax, cx	; ax + colume = ax

	mov bl, 2
	mul	bl		; ax * 2 = ax

	mov bx, ax

	mov	ax, SelectorVideo
	mov	gs, ax			
	mov	edi, ebx	
	mov	ah, 0Ch			
	mov	al,	dl
	mov	[gs:edi], ax
	ret

_DummyHandler:
DummyHandler	equ	_DummyHandler	-	$$
	mov	ax, SelectorVideo
	mov	gs, ax			; ��Ƶ��ѡ����(Ŀ��)
	mov	edi, (80 * 11 + 79) * 2	; ��Ļ�� 11 ��, �� 79 �С�
	mov	ah, 0Ch			; 0000: �ڵ�    1100: ����
	mov	al, '!'
	mov	[gs:edi], ax

	iretd	

_UsrHandler:
UsrHandler	equ	_UsrHandler	-	$$
	mov	ax, SelectorVideo
	mov	gs, ax			; ��Ƶ��ѡ����(Ŀ��)
	mov	edi, (80 * 11 + 79) * 2	; ��Ļ�� 11 ��, �� 79 �С�
	mov	ah, 0Ch			; 0000: �ڵ�    1100: ����
	mov	al, 'U'
	mov	[gs:edi], ax

	iretd	

_DEHandler:
DEHandler		equ	_DEHandler	-	$$
	mov bx, 11 
	mov cx, 76
	mov dl, 'D'
	call SelectorInitCode:PrintChar 
	jmp $

SegCode32Len	equ	$ - LABEL_SEG_INIT
; END of [SECTION .s32]
