CC=gcc
ifdef DEBUG
CC_FLAGS=-g
endif
OCAMLFIND_OPTS=-package core_kernel -package bigarray -package ppx_deriving -package angstrom

all: stackbvm stackbc

clean:
	rm -f stackbvm stackbc *.o

stackbc: stackbc.ml
	ocamlfind ocamlopt $(OCAMLFIND_OPTS) $< -o $@

stackbvm: $(patsubst %.c,%.o,$(wildcard *.c))
	$(CC) $(CC_FLAGS) $^ -o $@

.SECONDEXPANSION:
%.o: %.c $$(shell sed -n 's/^\#include \\+"\\([^"]\\+\\)"/\\1/p' $$*.c)
	$(CC) $(CC_FLAGS) -c $< -o $@
