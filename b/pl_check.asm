; ==========================================
; pl_check.asm
; ���뷽����nasm pl_check.asm -o pl_check.bin
; ==========================================

%include	"pm.inc"	; ����, ��, �Լ�һЩ˵��

org	7c00h
	jmp	LABEL_BEGIN

[SECTION .gdt]
; GDT
;                              �λ�ַ,       �ν���     , ����
LABEL_GDT:	   Descriptor       0,				0,		0   ; ��������
LABEL_DESC_CODE32: Descriptor	0, SegCode32Len - 1,	DA_C + DA_32; ��һ�´����
LABEL_DESC_CODE32D2: Descriptor	0, SegCode32Len - 1,	DA_C + DA_32 + DA_DPL2; ��һ�´����
LABEL_DESC_VIDEO:  Descriptor 0B8000h,	     0ffffh,	DA_DRW + DA_DPL3; �Դ��׵�ַ
LABEL_DESC_STACK0:  Descriptor	0,	    TopOfStack0,	DA_DRW + DA_DPL0 ; ��ջ�� 
LABEL_DESC_STACK2:  Descriptor	0,	    TopOfStack2,	DA_DRW + DA_DPL2 ; ��ջ�� 
LABEL_DESC_TSS:  Descriptor		0,		  TSSLen -1,    DA_386TSS; ��ջ�� 

; ��					ѡ����,		����ƫ��,	��������,	���� 
LABEL_CALL_GATE: Gate	SelectorCode32R2D0,	      0,    0,	DA_386CGate + DA_DPL3

; GDT ����
GdtLen		equ	$ - LABEL_GDT	; GDT����
GdtPtr		dw	GdtLen - 1	; GDT����
			dd	0		; GDT����ַ

; GDT ѡ����
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

; TSS
[SECTION .tss]
ALIGN   32
[BITS   32]
LABEL_TSS:
        DD  0           ; Back
        DD  TopOfStack0 ; 0 ����ջ
        DD  SelectorStack0 ; 
        DD  0           ; 1 ����ջ
        DD  0           ; 
        DD  TopOfStack2	; 2 ����ջ
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
        DW  0           ; ���������־
        DW  $ - LABEL_TSS + 2   ; I/Oλͼ��ַ
        DB  0ffh            ; I/Oλͼ������־
TSSLen      equ $ - LABEL_TSS

[SECTION .s16]
[BITS	16]
LABEL_BEGIN:
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	mov	ss, ax
	mov	sp, 0100h

	; gdt��ʼ�� 32 λ�����������
	xor	eax, eax
	mov	ax, cs
	shl	eax, 4
	add	eax, LABEL_SEG_CODE32
	mov	word [LABEL_DESC_CODE32 + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_CODE32 + 4], al
	mov	byte [LABEL_DESC_CODE32 + 7], ah

	; gdt��ʼ�� 32 λ����������� ring2
	xor	eax, eax
	mov	ax, cs
	shl	eax, 4
	add	eax, LABEL_SEG_CODE32
	mov	word [LABEL_DESC_CODE32D2 + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_CODE32D2 + 4], al
	mov	byte [LABEL_DESC_CODE32D2 + 7], ah

	; gdtд��stack3���ݶε�ַ
	xor	eax, eax
	add	eax, LABEL_STACK2 
	mov	word [LABEL_DESC_STACK2 + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_STACK2 + 4], al
	mov	byte [LABEL_DESC_STACK2 + 7], ah

	; gdt��ʼ��TSS 
	xor	eax, eax
	mov	ax, cs
	shl	eax, 4
	add	eax, LABEL_TSS
	mov	word [LABEL_DESC_TSS + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_TSS + 4], al
	mov	byte [LABEL_DESC_TSS + 7], ah

	; Ϊ���� GDTR ��׼��
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_GDT		; eax <- gdt ����ַ
	mov	dword [GdtPtr + 2], eax	; [GdtPtr + 2] <- gdt ����ַ

	; ���� GDTR
	lgdt	[GdtPtr]

	; ���ж�
	cli

	; �򿪵�ַ��A20
	in	al, 92h
	or	al, 00000010b
	out	92h, al

	; ׼���л�������ģʽ
	mov	eax, cr0
	or	eax, 1
	mov	cr0, eax

	; �������뱣��ģʽ
	jmp	dword SelectorCode32:0	; ִ����һ���� SelectorCode32 װ�� cs,
					; ����ת�� Code32Selector:0  ��
; END of [SECTION .s16]

[SECTION .s32]; 32 λ�����. ��ʵģʽ����.
[BITS	32]
LABEL_SEG_CODE32:
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

	push	SelectorStack2	
	push	TopOfStack2
	push	SelectorCode32R2D2	
	push	0
	retf	
.2:						; ���Դ��룬CPL=2
	mov	ax, SelectorVideo
	mov	gs, ax			; ��Ƶ��ѡ����(Ŀ��)
	mov	edi, (80 * 11 + 79) * 2	; ��Ļ�� 11 ��, �� 79 �С�
	mov	ah, 0Ch			; 0000: �ڵ�    1100: ����
	mov	al, 'P'
	mov	[gs:edi], ax
									; RPL = 2, CPL = 2 
	call	SelectorCallGateTest:0	; DPL_G = 2, RPL_G = 2		
									; DPL_B = 0
SegCode32Len	equ	$ - LABEL_SEG_CODE32
; END of [SECTION .s32]
