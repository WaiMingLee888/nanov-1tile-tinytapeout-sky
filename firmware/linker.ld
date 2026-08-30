OUTPUT_ARCH(riscv)
ENTRY(_start)
PROVIDE(__scratch = 0x00000800);

MEMORY
{
    spi_ram (rwx) : ORIGIN = 0x00000000, LENGTH = 64K
}

SECTIONS
{
    .text :
    {
        KEEP(*(.text.start))
        *(.text .text.*)
        *(.rodata .rodata.*)
    } > spi_ram

    .data :
    {
        *(.sdata .sdata.*)
        *(.data .data.*)
    } > spi_ram

    .bss (NOLOAD) :
    {
        *(.sbss .sbss.*)
        *(.bss .bss.*)
        *(COMMON)
    } > spi_ram

    /DISCARD/ :
    {
        *(.comment)
        *(.eh_frame .eh_frame.*)
    }
}
