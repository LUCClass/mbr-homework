

# MBR

Code in this directory is for the MBR. It is the first-stage bootloader that is automatically loaded from the disk by the BIOS. It is responsible for loading the second-stage bootloader from the disk and calling it. This MBR will start executing code at the `boot` label.

The job of your MBR code is to (1) print out a welcome string, (2) read the first 50 or so sectors from the hard disk into memory at address 0x7E00 and then (3) jump to 0x7E00.

Your job is to write the following functions:

1. `putStr` calls the BIOS to print a NULL-terminated string.
2. `readSector` calls the BIOS to load sectors from the hard drive.

I have included some example code for you to reference. The file `print_hex_16.asm` contains a function that prints an integer to the console. It calls the BIOS to print characters. The label `do_print_hex` is where the actual printing takes place. Ralph Brown's Interrupt List has a detailed description of how the BIOS calls work. The high-level overview of calling the BIOS is that you need to set up the CPU registers with the right values to tell the BIOS what you want it to do and then run an `int` instruction to actually call the BIOS.

You can test this function with the following code:

    mov ax,0x1234
    push ax
    call print_hex_16
    add ax,2

This should print `1234` to the terminal.

## Compiling

You will need `nasm`, a 16-bit x86 assembler to build the MBR code:

    make img

This will produce an MBR image called `mbr.img`. To test the image in Qemu:

    make run

If your program correctly loads the sector from the hard disk and runs it, it will print a message to the screen indicating that it is working correctly.
To debug with `gdb` on `qemu` you can do
    
    make debug
