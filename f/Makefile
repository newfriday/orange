mbr:	mbr.o	mbr.ld
	ld -o mbr mbr.o -Tmbr.ld
	dd if=mbr ibs=512 skip=8 of=a.img obs=512 seek=0 count=1
mbr.o:	mbr.asm
	nasm -f elf -o mbr.o mbr.asm
	dd if=mbr.o ibs=1 skip=304 of=mbr.s16 seek=0 count=512
clean:
	rm -f mbr.o	mbr
