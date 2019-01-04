# wishbone
Trying to learn Wishbone by implementing few master/slave devices

## what is implemented

### register(s)

[wb_slave_register/](wb_slave_register/)

a slave device which implements a set of basic registers - writing to them will retain the given value, and reading will return it.

number of registers is configurable and is done via a module parameter

