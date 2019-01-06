# intercon

a general Wishbone interconnect, supporting `N` masters and `M` slaves

## test scenario

in the test scenario ([testbench.sv](testbench.sv)), we have 2 master devices (both [wb_master_nop](wb_master_nop/)) and 2 slave devices (both [wb_slave_nop](wb_slave_nop/))

master device #0 always accesses address 0x0000, and master device #1 always accesses address 0x1000

### memory map

| Adress space    | Device     |
| --------------- | ---------- |
| 0x0000 - 0x0fff | NOP0       |
| 0x1000 - 0x1fff | NOP1       |
| 0x2000 - 0x2fff | Reserved   |
| 0x3000 - 0x3fff | Reserved   |
| 0x4000 - 0x4fff | Reserved   |
| 0x5000 - 0x5fff | Reserved   |
| 0x6000 - 0x6fff | Reserved   |
| 0x7000 - 0x7fff | Reserved   |
| 0x8000 - 0x8fff | Reserved   |
| 0x9000 - 0x9fff | Reserved   |
| 0xa000 - 0xafff | Reserved   |
| 0xb000 - 0xbfff | Reserved   |
| 0xc000 - 0xcfff | Reserved   |
| 0xd000 - 0xdfff | Reserved   |
| 0xe000 - 0xefff | Reserved   |
| 0xf000 - 0xffff | Reserved   |

### wave

![wave](wave.png)
