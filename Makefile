CC=gcc
ifdef DEBUG
CC_FLAGS=-g
endif
OCAMLFIND_OPTS=-package core_kernel -package bigarray -package ppx_deriving -package angstrom

# for escaping
SEMICOLON=;

VM_DIR=vm
VM_SRC_C=$(wildcard $(VM_DIR)/*.c)
VM_SRC_M4=$(wildcard $(VM_DIR)/*.m4)

VM_SRC_M4_TARGET=$(patsubst %.m4,%,$(VM_SRC_M4))
VM_SRC_M4_TARGET_C=$(filter %.c,$(VM_SRC_M4_TARGET))
VM_SRC_M4_TARGET_NON_C=$(filter-out %.c,$(VM_SRC_M4_TARGET))

VM_SRC_C_OBJ=$(patsubst %.c,%.o,$(VM_SRC_C))
VM_SRC_M4_TARGET_C_OBJ=$(patsubst %.c,%.o,$(VM_SRC_M4_TARGET_C))

VM_OBJ=$(shell echo $(VM_SRC_C_OBJ) $(VM_SRC_M4_TARGET_C_OBJ) | tr ' ' '\n' | awk '!a[$$0]++')

.PHONY: all clean
all: stackbvm stackbc
clean:
	rm -f stackbvm stackbc $(VM_OBJ) $(VM_SRC_M4_TARGET)

stackbc: stackbc.ml
	ocamlfind ocamlopt $(OCAMLFIND_OPTS) $< -o $@

stackbvm: $(VM_OBJ)
	$(CC) $(CC_FLAGS) $^ -o $@

# m4 rules
$(VM_SRC_M4_TARGET): $(wildcard data/*) $(wildcard m4/*.m4)
$(VM_SRC_M4_TARGET_NON_C): %: %.m4
	m4 $< > $@ || ( rm -f $@; exit 1 )
# This trick currently runs m4 on each file
# every build regardless of whether it's needed,
# and it runs m4 a second time when it actually
# needs to build it. Obviously, this is suboptimal,
# but a fix would be tricky (maybe have a phony target
# for each m4 target to reduce m4 passes to 1 per run,
# but that doesn't fix running m4 when it's not needed).
.SECONDEXPANSION:
$(VM_SRC_M4_TARGET_C): %.c: %.c.m4 \
  $$(addprefix $(VM_DIR)/,$$(shell \
    m4 $$*.c.m4 | $(CC) -xc -MM -MG - | cut -d' ' -f2-))
	m4 $< > $@ || rm -f $@

# c rules
.SECONDEXPANSION:
$(VM_OBJ): %.o: %.c \
  $$(addprefix $(VM_DIR)/,$$(shell \
    [ -f $$*.c -a ! -f $$*.c.m4 ] &&\
    (\
      cd $$(dir $$*)$$(SEMICOLON)\
      $(CC) -MM -MG $$(notdir $$*.c)\
    ) | cut -d' ' -f2-))
	$(CC) $(CC_FLAGS) -c $< -o $@
