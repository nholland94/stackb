CC=gcc
ifdef DEBUG
CC_FLAGS=-g
endif

M4=m4

OCAMLFIND_OPTS=-package core_kernel -package bigarray -package ppx_deriving.std -package angstrom -package stdint

C_DIR=c
VM_DIR=vm
M4_LIB_DIR=m4
DATA_DIR=data

STACKBC=stackbc
STACKBVM=stackbvm

M4_LIB_SOURCES=$(wildcard $(M4_LIB_DIR)/*)
DATA_FILES=$(wildcard $(DATA_DIR)/*)
