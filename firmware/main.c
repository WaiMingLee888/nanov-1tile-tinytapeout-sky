typedef unsigned int uint32_t;

#define GPIO_OUT (*(volatile uint32_t *)0x10000000u)
#define GPIO_IN  (*(volatile uint32_t *)0x10000004u)
extern volatile uint32_t __scratch[];
#define SCRATCH __scratch

static __attribute__((noreturn)) void finish(uint32_t signature)
{
    GPIO_OUT = signature;
    for (;;) {
        __asm__ volatile ("nop");
    }
}

int main(void)
{
    uint32_t input;
    uint32_t mixed;

    GPIO_OUT = 0x01u;

    input = GPIO_IN & 0xffu;
    mixed = ((input << 8) ^ 0x5aa5u) + 0x1234u;
    SCRATCH[0] = mixed;
    SCRATCH[1] = mixed ^ 0xa5a55a5au;

    if (input != 0x5au)
        finish(0xeeu);
    if (SCRATCH[0] != 0x12d9u)
        finish(0xeeu);
    if (SCRATCH[1] != (0x12d9u ^ 0xa5a55a5au))
        finish(0xeeu);

    finish(0xa5u);
}
