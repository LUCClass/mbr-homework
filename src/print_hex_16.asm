
;
; |-------------------------------|
; |         Number to Print       |
; |-------------------------------|
; |         Return Address        |
; |-------------------------------|
; |          Caller's BP          |
; |-------------------------------|
;
; Prints a 16-bit hex value passed on the stack
print_hex_16:
    push bp   ; Preamble
    mov bp,sp
    push ax
    push bx
    push cx

    mov cx,16 ; Load the count register, which tracks how many bits to shift

print_hex_loop:
    mov ax,[4+bp] ; Get number to print in AX
    sub cx,4      ; Decrement the shift count
    shr ax,cl     ; Shift the number
    and ax,0xf    ; Mask off higher order bits
    add al,'0'    ; Add ASCII offset
    cmp al,'9'
    jle do_print_hex
    add al,7
do_print_hex:
    mov ah, 0x0e  ; Call BIOS to print character
    xor bh,bh
    mov bl, 0x07
    int 16
    cmp cx,0
    jg print_hex_loop

    pop cx        ; Collapse stack frame
    pop bx
    pop ax
    pop bp
    ret

