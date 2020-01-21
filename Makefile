PORT := $$(date +'%s')
PORT := $(shell echo "$$(( ( $(PORT) & 4095 ) + 1024))" )

n ?= 10
all:img

img: dirs
	nasm -f elf32 -g3 -F dwarf src/mbr.asm -o obj/mbr.o
	ld -Ttext=0x7c00 -melf_i386 obj/mbr.o -o obj/mbr.elf
	objcopy -O binary obj/mbr.elf mbr.img
	dd if=stage1.img of=mbr.img seek=1 conv=notrunc

run:
	qemu-system-i386 -hda mbr.img

clean:
	rm -f obj/*

debug:
	n=$(n); \
	while [ $${n} -gt 0 ] ; do \
		PORT := $$(date +'%s') \
		PORT := $(shell echo "$$(( ( $(PORT) & 4095 ) + 1024))" ) \
		processlist=`ps aux | grep tcp::$(PORT) | grep -v grep`; \
		n=$${#processlist}; \
		echo $$processlist; \
		echo $$n ; \
	done; \
	qemu-system-i386 -hda mbr.img -S -gdb tcp::$(PORT) &
	gdb mbr.elf -x gdb_init_real_mode.txt -ex 'target remote localhost:$(PORT)' -ex 'break *0x7c00' -ex 'continue'

dirs:
	mkdir -p obj
