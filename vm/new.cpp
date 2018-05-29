typedef void (*instruction_fn)(machine*);

template<class T> struct {
  T *bot;
  T *top;
  T *cap;
};

typedef struct {
  stack<uint8_t> stack;
  stack<call_frame> call_stack;
  bool running;
  error error;
  program *program;
} machine;

machine *allocate_machine(size_t stack_size, size_t call_stack_size) {
  const size_t allocation_size = sizeof(machine) + stack_size + call_stack_size * sizeof(call_frame);
  const void *memory = malloc(allocation_size);
  machine *m = (machine*)memory;

  const uint8_t *stack_base = ((uint8_t*)memory) + sizeof(machine);
  const call_frame *call_stack_base = (call_frame*)(stack_base + stack_size);

  m->stack.bot = stack_base;
  m->stack.top = stack_base;
  m->stack.cap = stack_base + stack_size;
  m->call_stack.bot = call_stack_base;
  m->call_stack.top = call_stack_base;
  m->call_stack.cap = call_stack_base + call_stack_size;
  m->running = false;
  m->error = NO_ERROR;
  m->program = NULL;

  return m;
}

template<int Size> class Value {
  static const word_count = Size / sizeof(size_t);
  size_t words[word_count];

public:
  void *write(void *dst) {
    ptrdiff_t index = 0;

    static_if(Size % sizeof(size_t) == 0) {
      while(index < word_count) {
        *(size_t*)dst = words[index];
        dst = (void*)(((size_t*)dst) + 1);
        index++;
      }

      return dst;
    } static_else {
      while(index < word_count - 1) {
        *(size_t*)dst = words[index];
        dst = (void*)(((size_t*)dst) + 1);
        index++;
      }

      *(size_t*)dst = (words[word_count - 1] & last_word_mask) | (*(size_t*)dst & ~last_word_mask);
      dst = (void*)(((uint8_t*)dst) + last_word_size);
      return dst;
    }
  }
}

template<1, ptrdiff_t Count> copy(void *src, void *dst) {
  copy_using<uint8_t, Count>(src, dst);
}
template<2, ptrdiff_t Count> copy(void *src, void *dst) {
  copy_using<uint16_t, Count>(src, dst);
}
template<4, ptrdiff_t Count> copy(void *src, void *dst) {
  copy_using<uint32_t, Count>(src, dst);
}
#if __WORD_SIZE == 64
template<8, ptrdiff_t Count> copy(void *src, void *dst) {
  copy_using<uint64_t, Count>(src, dst);
}
#endif
template<ptrdiff_t Size, ptrdiff_t Count> copy(void *src, void *dst) {
  // nope... if size is greater than word size, we need multiple registers
  size_t total_size = Size * Count;
  size_t reg = *(size_t*)src;

  while(total_size > sizeof(size_t)) {
    *(size_t*)dst = reg;
    dst = (void*)(((size_t*)dst) + 1);
  }

  if(total_size > 0) {
    *(size_t*)
  }
}

void drop(machine *m, ptrdiff_t size) {
  check_underflow(m, size);
  m->stack.top -= size;
}
template<int Size> void instruction_DROP_static(machine *m) {
  drop(m, Size);
}
void instruction_DROP_dynamic(machine *m) {
  drop(m, read_argument(m));
}

void dup(machine *m, ptrdiff_t size, ptrdiff_t count) {
  check_overflow(m, count * size);
  check_underflow(m, size);
  copy(m->stack.top - size, m->stack.top, size, count);
}
template <int Size, int Count> instruction_DUP_dynamic(machine *m) {
}



void (*instruction_DROP1)(machine *m) = instruction_DROP_static<1>;
void (*instruction_DROP2)(machine *m) = instruction_DROP_static<2>;
void (*instruction_DROP4)(machine *m) = instruction_DROP_static<4>;
void (*instruction_DROP8)(machine *m) = inst9pruction_DROP_static<8>;
void (*instruction_DROP16)(machine *m) = instruction_DROP_static<16>;
void (*instruction_DROP32)(machine *m) = instruction_DROP_static<32>;
void (*instruction_DROPN)(machine *m) = instruction_DROP_dynamic;

<@
  map_ordered [non_reserved_instructions] [lambda {val instr} {
    variable fn_name "instruction_[set instr("full_name")]"
    variable fn_exp [expr {
      [set instr("size")] = "N" ? "${fn_name}_dynamic" :
      [set instr("size")] != {} ? "${fn_name}_static<[set instr("size")]" :
      "${fn_name}_implementation"
    }]
    return "const instruction_fn $fn_name = $fn_exp;"
  }]
@>

instruction_fn instruction_table[256] = {
<@
  map_ordered [instructions] [lambda {val instr} {
    return "instruction_[set instr("full_name")],"
  }]
@>
};

void execute(machine *m) {
  if(m->error != NO_ERROR || m->program == NULL)
    yolo;

  uint8_t opcode;
  m->running = true;

  while(m->running) {
    opcode = read_byte(m->program);
    instruction_table[opcode](m);
  }

  // check error flags
}
