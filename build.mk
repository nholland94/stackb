include var.mk
SEMICOLON=;
define NL :=


endef

C_STRUCTURE_SOURCES=$(wildcard $(C_DIR)/*.ml)
C_SIGNATURE_SOURCES=$(wildcard $(C_DIR)/*.mli)
C_NATIVE_OBJECTS=$(patsubst %.ml,%.cmx,$(C_STRUCTURE_SOURCES))

VM_SOURCES=$(wildcard $(VM_DIR)/*.c)
VM_OBJECTS=$(patsubst %.c,%.o,$(VM_SOURCES))

ocaml_deps.mk: build.mk $(C_STRUCTURE_SOURCES) $(C_SIGNATURE_SOURCES)
	ocamldep -I $(C_DIR) $(C_STRUCTURE_SOURCES) $(C_SIGNATURE_SOURCES) > $@
-include ocaml_deps.mk

$(STACKBC): $(C_NATIVE_OBJECTS)
	ocamlfind ocamlopt $(OCAMLFIND_OPTS) $^ -o $@

# $(info $(subst @,$(NL),$(shell ocamldep -I $(C_DIR) $(C_DIR)/*.ml $(C_DIR)/*.mli | grep -v '.\+ :$$' | sed -e 's/ :/:/' | sed -e 's/ \?$$/@/')))
# $(subst @,$(NL),$(shell ocamldep -I $(C_DIR) $(C_DIR)/*.ml $(C_DIR)/*.mli | grep -v '.\+ :$$' | sed -e 's/ :/:/' | sed -e 's/ \?$$/@/'))

# %.cmo: %.ml
# 	ocamlfind ocamlc $(OCAMLFIND_OPTS) -c $< -o $@
%.cmx: %.ml
	ocamlfind ocamlopt $(OCAMLFIND_OPTS) -c $< -o $@

$(STACKBVM): $(VM_OBJECTS)
	$(CC) $(CC_FLAGS) $^ -o $@
.SECONDEXPANSION:
%.o: %.c \
  $$(addprefix $$(dir $$*)/,$$(shell\
    (\
      cd $$(dir $$*)$$(SEMICOLON)\
      $(CC) -MM -MG $$(notdir $$*.c)\
    ) | cut -d' ' -f2-))
	$(CC) $(CC_FLAGS) -c $< -o $@
