

# MBR

Code in this directory is for the MBR. It is the first-stage bootloader that is automatically loaded from the disk by the BIOS. It is responsible for loading the second-stage bootloader from the disk and calling it. This MBR will start executing code at the `boot` label.

The job of your MBR code is to (1) print out a welcome string, (2) read the first 50 or so sectors from the hard disk into memory at address 0x7E00 and then (3) jump to 0x7E00.

Your job is to write the following functions:

1. `putStr` calls the BIOS to print a NULL-terminated string.
2. `readSector` calls the BIOS to load sectors from the hard drive.

## Prereqs

You'll need a few programs to make this work. You can install them on Ubuntu with the command below:

    user@system:~ sudo apt install nasm qemu-system-x86 make 

## BIOS Operations

The PC BIOS provides a bunch of low-level functions to make your job easier. It can print stuff to the screen, get input from the keyboard, read and write to the disks, play sounds, draw pixels on the screen, and lots of other stuff. These low-level functions are called *drivers*, and the details of how they're implemented are generally hardware-dependent---that is, they are different on different machines. For a complete list of BIOS functionality, search google for *Ralph Brown's Interrupt List*.

BIOS functions can be called by executing `INT` instructions, which cause software-initiated interrupts. Executing an `INT` instruction causes your program to call the BIOS, which executes some function based on the parameters you pass. Parameters are passed from your program to the BIOS in the CPU's registers. The BIOS different functions (printing characters to the screen, reading keyboard input, etc) depending on the values your program passes.


### An Easy One: Getting a Keystroke from the Keyboard

Probably the simplest BIOS call is requesting a keystroke from the keyboard. This call just hangs until the user presses a key, then it returns with the ASCII code for the keypress in register `AL`. To call the **Get Keystroke** function in the BIOS, just put the value `0` in register `AH` then execute an `INT 0x16` instruction:

    mov ah,0
    int 0x16  ; This instruction will hang until you press a key.
              ; After you press a key, it will return with AL = ASCII code


### Printing to the Terminal

To print a character to the terminal, you have to pass a bit more information to the BIOS. The operation code 0x0E in register `AH` tells the BIOS that we want to print a character. The ASCII code for the character to print goes in register `AL`. Registers `BH` and `BL` get the BIOS page number and foreground color respectively. I've written an example function that prints the character `A` to the terminal below.

| Register  | Meaning          |
|-----------|------------------|
| AH        | Command: 0x0E    |
| AL        | Char to write    |
| BH        | Page Number      |
| BL        | Foreground Color |


    printA:
      push bp     ; prologue
      mov bp,sp
      
      mov ah, $0xe
      mov bh,0    ; Page 0
      mov bl,7    ; Foreground color 7 (gray)
      mov al,'A'  ; Char to print in AL
      int 16      ; Call the BIOS
      
      pop bp      ; Epilogue
      ret



### Reading from the Disk

Reading from the disk can be a little challenging. We need to tell the BIOS (1) the disk read command, (2) where we want to read from on the disk, (3) where we want the data to go in memory, and (4) how much data to read. For (1), the disk read command 0x02 goes in register `AH`. For (2), we need to specify a sector on the disk to read. The disk is addressed in cylinder, head, and sector numbers. We want to read from cylinder 0, sector 2 head 0. The first hard disk number is 0x80. For (3), we want to put the stage 1 bootloader immediately after the MBR in memory. The MBR lives at 0x7C00 and takes up 512 bytes (0x7C00 + 512 = 0x7C00 + 0x800 = 0x7E00). The data will be written to `ES:BX`. For (4), we need to read as much data as is taken up by the stage 1 bootloader---50 sectors should be good. Finally, call the BIOS with `INT 0x13` to initiate the disk read.

| Register  | Meaning                              |
|-----------|--------------------------------------|
| AH        | Command: 0x02                        |
| AL        | Num sectors to read                  |
| ES        | Segment where data should be written |
| BX        | Offset into ES to write data         |
| CH        | Low 8 bits of cyl num                |
| CL        | Sector num                           |
| DH        | Head num                             |
| DL        | Drive num                            |



### Example Code

I have included some example code for you to reference. The file `print_hex_16.asm` contains a function that prints an integer to the console. It calls the BIOS to print characters. The label `do_print_hex` is where the actual printing takes place. Ralph Brown's Interrupt List has a detailed description of how the BIOS calls work. The high-level overview of calling the BIOS is that you need to set up the CPU registers with the right values to tell the BIOS what you want it to do and then run an `int` instruction to actually call the BIOS.

You can test this function with the following code:

    mov ax,0x1234
    push ax
    call print_hex_16
    add ax,2

This should print `1234` to the terminal.

## Compiling

We can't just use any regular compiler to build the MBR because it runs in 16-bit mode. Most compilers and assemblers don't support 16-bit x86 mode anymore, so you will need `nasm`, a 16-bit x86 assembler to build the MBR code:

    make img

This will produce an MBR image called `mbr.img`. To test the image in Qemu:

    make run

If your program correctly loads the sector from the hard disk and runs it, it will print a message to the screen indicating that it is working correctly.
To debug with `gdb` on `qemu` you can do
    
    make debug


## 8086 Assembly Reference

## Registers

| Register  | Meaning                              |
|-----------|--------------------------------------|
| AX        | 16-bit Integer Register              |
| BX        | 16-bit Integer Register              |
| CX        | 16-bit Integer Register              |
| DX        | 16-bit Integer Register              |
| SI        | 16-bit Pointer Register              |
| DI        | 16-bit Pointer Register              |
| BP        | Base Pointer (same as Frame Pointer) |
| SP        | Stack Pointer                        |


There are two kinds of registers in the 8086: integer registers and pointer registers. Integer registers AX, BX, CX, and DX hold 16-bit integers. Pointer registers SI and DI hold addresses.

#### Example: set the value of register AX to 0x1234

    mov ax,0x1234

#### Example: Declare a variable and set its value

    [BITS 16]
    boot:
        mov si,var      ; Get the address of var into register SI
        mov word [si],1 ; change the variable's value to 1
        hlt             ; Halt the CPU
    var:                ; declare a variable called `var'
        dw 0            ; Initial value of the variable is 0 (dw means declare word)
        
    times 510-($-$$) db 0 ; Skip to end of boot sector
    db 0x55 ; Magic Numbers
    db 0xaa ; To make disk bootable

#### Example: Calling Functions

The `call` and `ret` instructions are used to call and return from functions. `call` pushes the return address onto the stack and jumps to the specified function. `ret` pops the return address off of the stack and jumps back to that address.

    [BITS 16]
    boot:
        call func       ; Call function func
        hlt             ; Halt the CPU
        
    func:
        push bp         ; Prologue
        mov bp,sp
        ; ... do some stuff ...
        pop bp          ; Epilogue
        ret
    times 510-($-$$) db 0 ; Skip to end of boot sector
    db 0x55 ; Magic Numbers
    db 0xaa ; To make disk bootable


#### Example: Passing Parameters to functions
    [BITS 16]
    boot:
        mov ax,5        ; Initialize AX to 5
        push ax         ; Pass parameter on the stack
        call add1       ; Call function add1
        add sp,2        ; Clean up the stack
        hlt             ; Halt the CPU
    ; |----------------|
    ; | Parameter      | <- BP+4
    ; |----------------|
    ; | Return Address | <- BP+2
    ; |----------------|
    ; | Caller's BP    | <- SP,BP
    ; |----------------|
    add1:
        push bp         ; Prologue
        mov bp,sp
        mov ax,[bp+4]   ; Get input parameter off of stack
        add ax,1        ; Add 1 to input parameter. Return value in AX
        pop bp          ; Epilogue
        ret
    times 510-($-$$) db 0 ; Skip to end of boot sector
    db 0x55 ; Magic Numbers
    db 0xaa ; To make disk bootable


#### Example: Loops

In this exmple, we will write a loop to count the number of characters in a string. SI points to the beginning of the string. BX is the index into the string, and AL

    [BITS 16] 
    boot:
        mov si,str
        mov bx,0        ; Initialize character count to 0
    loop:
        mov al,[si+bx]  ; Get a character from the string into AL
        cmp al,0        ; Compare to NULL terminator
        je loop_done    ; If we found a NULL terminator, we're done.
        add bx,1        ; Otherwise increment character count
        jmp loop        ; And go get another char
    loop_done:
        hlt 
    str:
        db "testing",0

    times 510-($-$$) db 0 ; Skip to end of boot sector
    db 0x55 ; Magic Numbers
    db 0xaa ; To make disk bootable
