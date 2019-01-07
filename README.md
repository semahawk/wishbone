# wishbone

Trying to learn Wishbone by implementing few master/slave devices

## what devices are implemented

### nop, slave

[wb_slave_nop/](wb_slave_nop/)

a slave device does nothing - it _only_ responds with an ACK as soon as possible

### nop, master

[wb_master_nop/](wb_master_nop/)

a master device does nothing - it basically only starts a bus cycle, waits for ACK and that's it

### register(s), slave

[wb_slave_register/](wb_slave_register/)

a slave device which implements a set of basic registers - writing to them will retain the given value, and reading will return it.

number of registers is configurable and is done via a module parameter

### seq mem access, master

[wb_master_seq_mem_access/](wb_master_seq_mem_access/)

this master device continuously issues SINGLE WRITE and then SINGLE READ bus cycles
over a range of memory address space (configurable via module parameters)

### interconnect

[wb_intercon/](wb_intercon/)

a simple round robin interconnect, supporting multiple masters and multiple slave devices

### loopback

[wb_loopback/](wb_loopback/)

a simple device which has both a master and a slave interface, which means it can be loopbacked
