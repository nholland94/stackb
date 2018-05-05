#include <argp.h>
#include <stdlib.h>
#include <stdbool.h>
#include <unistd.h>
#include <string.h>
#include <termios.h>

#include "common.h"
#include "instructions.h"
#include "execute.h"
#include "machine.h"

#define DEFAULT_STACK_SIZE 1024
#define DEFAULT_CALL_STACK_SIZE 512

typedef struct arguments {
  bool debug;
  char *file;
  size_t stack_size;
  size_t call_stack_size;
} arguments;

static const char *program_version = "stackbvm 0.1";
static const char *bug_address = "<nholland94@gmail.com>";
static const char doc[] = "Execute a program on the stackb virtual machine.";
static struct argp_option options[] = {
  { "debug", 'd', NULL, 0, "execute program in debugger" },
  { "file", 'f', "<file>", 0, "execute program from file" },
  { "stack-size", 's', "<size>", 0, "set value stack size (default: 1024)" },
  { "call-stack-size", 'c', "<size>", 0, "set call stack size (default: 512)" },
  { NULL }
};
static size_t parse_size(char *arg) {
  size_t n = 0;
  size_t len = strlen(arg);
  for(ptrdiff_t i = 0; i < len; i++)
    n = n * 10 + (arg[i] + '0');
  return n;
};
static error_t parse_opt(int key, char *arg, struct argp_state *state) {
  struct arguments *args = state->input;
  switch(key) {
  case 'd': args->debug = true; break;
  case 'f': args->file = arg; break;
  case 's': args->stack_size = parse_size(arg); break;
  case 'c': args->call_stack_size = parse_size(arg); break;
  default: return ARGP_ERR_UNKNOWN;
  }

  return 0;
}
static struct argp argp = { options, parse_opt, NULL, doc, NULL, NULL, NULL };

typedef struct program {
  void *ptr;
  size_t size;
} program;

program load_program_from_file(char *filename) {
  program p;

  FILE *f = fopen(filename, "rb");
  fseek(f, 0, SEEK_END);
  p.size = ftell(f);
  fseek(f, 0, SEEK_SET);

  p.ptr = malloc(p.size);
  if(p.ptr == NULL) panic("ALLOCATION ERROR");

  fread(p.ptr, p.size, 1, f);
  fclose(f);

  return p;
}

program load_program_from_stdin() {
  #define BUF_SIZE 1024
  byte buf[BUF_SIZE];

  program p = {
    .ptr = malloc(BUF_SIZE),
    .size = BUF_SIZE
  };
  if(p.ptr == NULL) panic("ALLOCATION ERROR");

  size_t offset = 0;
  while(fgets(buf, BUF_SIZE, stdin)) {
    size_t buf_len = strlen(buf);
    if(offset + buf_len > p.size) {
      p.size += BUF_SIZE;
      p.ptr = realloc(p.ptr, p.size);
    }

    memcpy(p.ptr + offset, buf, buf_len);
    offset += buf_len;
  }

  return p;
}

/*
char getch() {
  char input = 0;
  struct termios t = { 0 };
  if(tcgetattr(0, &t) < 0)
    panic("tcgetattr");
  t.c_lflag &= ~ICANON;
  t.c_lflag &= ~ECHO;
  t.c_cc[VMIN] = 1;
  t.c_cc[VTIME] = 0;
  if(tcsetattr(0, TCSANOW, &t) < 0)
    panic("tcsetattr");
  if(read(0, &input, 1) < 0)
    panic("read");
  t.c_lflag |= ICANON;
  t.c_lflag |= ECHO;
  if(tcsetattr(0, TCSADRAIN, &t) < 0)
    panic("tcsetattr");
  return input;
}

void execute_debugger(machine *m) {
  char input;

  while(true) {
    printf("[%04x]> ", m->code.curr - m->code.base);
    fflush(stdout);
    input = getch();
    printf("\n");
    switch(input) {
    case '.':
      execute(m, false);
      print_stack(m);
      break;

    case 's':
      print_stack(m);
      break;

    case 'c':
      print_call_stack(m);
      break;

    case 'q':
      return;

    // case '?':
    //   print_debugger_help();
    //   break;
    default:
      printf("invalid input\n");
    }
  }
}
*/

int main(int argc, char **argv) {
  arguments args = {
    .debug = false,
    .file = NULL,
    .stack_size = DEFAULT_STACK_SIZE,
    .call_stack_size = DEFAULT_CALL_STACK_SIZE
  };
  argp_parse(&argp, argc, argv, 0, NULL, &args);

  program program = (args.file != NULL) ? load_program_from_file(args.file) : load_program_from_stdin();

  size_t tag_stack_size = args.stack_size * sizeof(byte);
  size_t val_stack_size = args.stack_size * sizeof(word);
  size_t call_stack_size = args.call_stack_size * sizeof(call_frame);
  size_t heap_size = tag_stack_size + val_stack_size + call_stack_size;

  byte *heap = (byte*)malloc(heap_size);
  byte *tag_stack = heap;
  word *val_stack = (word*)(heap + tag_stack_size);
  call_frame *call_stack = (call_frame*)(heap + tag_stack_size + val_stack_size);

  machine m = {
    .stack = {
      .tag_bot = tag_stack,
      .tag_top = tag_stack - 1,
      .val_bot = val_stack,
      .val_top = val_stack - 1,
      .val_cap = val_stack + args.stack_size
    },
    .call_stack = {
      .bot = call_stack,
      .top = call_stack - 1,
      .cap = call_stack + args.call_stack_size
    },
    .code = {
      .base = program.ptr,
      .curr = program.ptr,
      .cap = program.ptr + program.size
    }
  };

  push_call(&m, QREF_CONS(0, program.size));

  if(args.debug) {
		panic("TODO: debugger no implemented");
    // execute_debugger(&m);
  } else {
    execute(&m, true);
  }

  print_stack(&m);

  free(heap);
  free(program.ptr);

  return 0;
}
