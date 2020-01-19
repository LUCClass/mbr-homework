


[BITS 16]

boot: ; This file starts executing here.

    hlt


times 510-($-$$) db 0 ; Skip to end of boot sector

db 0x55 ; Magic Numbers
db 0xaa ; To make disk bootable


