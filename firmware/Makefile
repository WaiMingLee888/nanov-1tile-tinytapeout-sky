CROSS ?= /mnt/d/riscv/kianRiscV/asic/os/ulinux_asic_kianv_soc/buildroot/output/host/bin/riscv32-buildroot-linux-uclibc-
CC := $(CROSS)gcc
OBJCOPY := $(CROSS)objcopy
OBJDUMP := $(CROSS)objdump
READELF := $(CROSS)readelf

BUILD := build
CFLAGS := -march=rv32e -mabi=ilp32e -Os -ffreestanding -fno-builtin \
	-fno-pic -mno-relax -msmall-data-limit=0 -ffixed-x3 -ffixed-x4 \
	-ffunction-sections -fdata-sections -Wall -Wextra -Werror
LDFLAGS := -nostdlib -nostartfiles -static -Wl,--no-relax,--gc-sections \
	-Wl,-Map=$(BUILD)/nanov_test.map -T linker.ld

.PHONY: all clean inspect simulate

all: $(BUILD)/nanov_test.mem inspect

$(BUILD):
	mkdir -p $@

$(BUILD)/nanov_test.elf: start.S main.c linker.ld | $(BUILD)
	$(CC) $(CFLAGS) $(LDFLAGS) start.S main.c -o $@

$(BUILD)/nanov_test.bin: $(BUILD)/nanov_test.elf
	$(OBJCOPY) -O binary $< $@

$(BUILD)/nanov_test.mem: $(BUILD)/nanov_test.bin bin_to_mem.py
	python3 bin_to_mem.py $< $@

inspect: $(BUILD)/nanov_test.elf
	$(READELF) -h $< > $(BUILD)/nanov_test.readelf.txt
	$(OBJDUMP) -d $< > $(BUILD)/nanov_test.disasm.txt
	$(OBJDUMP) -h $< > $(BUILD)/nanov_test.sections.txt

simulate: all
	$(MAKE) -C ../test clean
	$(MAKE) -C ../test PROG_FILE=../firmware/$(BUILD)/nanov_test.mem \
		PROG_WORDS=$$(wc -l < $(BUILD)/nanov_test.mem)
	! grep failure ../test/results.xml

clean:
	rm -rf $(BUILD)
