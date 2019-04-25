OUTPUT_FORMAT("elf32-i386", "elf32-i386", "elf32-i386")
OUTPUT_ARCH(i386)
ENTRY(_start)
 
SECTIONS
{
    . = 0;
    .boot : {*(.s16)}
    . = ASSERT(. <= 512, "Boot too big!");
    /**
    . = 0x10;
    .boot : {*(.s16)}
    */
}   
