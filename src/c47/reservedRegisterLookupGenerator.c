/* Run this and pipe the output to gperf and capture it's output thus:
 * reservedRegisterLookupGenerator | gperf -C -G --null-strings -m 1000 \
 *                                         -E -n -L ANSI-C \
 *                                         -N lookupReservedVariableName \
 *                                         -t \
 *      >src/c47/reservedRegisterLookup.h
 *
 * The output will then need editing.  The asso_values array needs the
 * 36th and 37th elements swapped:
 *      -      22, 22, 22, 22, 22, 22,  9,  8, 22, 22,
 *      +      22, 22, 22, 22, 22,  9, 22,  8, 22, 22,
 * The TO_QSPI prefix is needed for asso_values and wordlist.
 */
#include <stdio.h>

struct {
  unsigned char name[8];
  const char *reg;
} names[] = {
#if 0
  {2, 'X',  0,   0,   0,   0,   0,   0},
  {2, 'Y',  0,   0,   0,   0,   0,   0},
  {2, 'Z',  0,   0,   0,   0,   0,   0},
  {2, 'T',  0,   0,   0,   0,   0,   0},
  {2, 'A',  0,   0,   0,   0,   0,   0},
  {2, 'B',  0,   0,   0,   0,   0,   0},
  {2, 'C',  0,   0,   0,   0,   0,   0},
  {2, 'D',  0,   0,   0,   0,   0,   0},
  {2, 'L',  0,   0,   0,   0,   0,   0},
  {2, 'I',  0,   0,   0,   0,   0,   0},
  {2, 'J',  0,   0,   0,   0,   0,   0},
  {2, 'K',  0,   0,   0,   0,   0,   0},
  {2, 'M',  0,   0,   0,   0,   0,   0},
  {2, 'N',  0,   0,   0,   0,   0,   0},
  {2, 'P',  0,   0,   0,   0,   0,   0},
  {2, 'Q',  0,   0,   0,   0,   0,   0},
  {2, 'R',  0,   0,   0,   0,   0,   0},
  {2, 'S',  0,   0,   0,   0,   0,   0},
  {2, 'E',  0,   0,   0,   0,   0,   0},
  {2, 'F',  0,   0,   0,   0,   0,   0},
  {2, 'G',  0,   0,   0,   0,   0,   0},
  {2, 'H',  0,   0,   0,   0,   0,   0},
  {2, 'O',  0,   0,   0,   0,   0,   0},
  {2, 'U',  0,   0,   0,   0,   0,   0},
  {2, 'V',  0,   0,   0,   0,   0,   0},
  {2, 'W',  0,   0,   0,   0,   0,   0},
#endif
  {{4, 'A', 'D', 'M',  0,   0,   0,   0}, "RESERVED_VARIABLE_ADM" },
  {{6, 'D', '.', 'M', 'A', 'X',  0,   0}, "RESERVED_VARIABLE_DENMAX" },
  {{4, 'I', 'S', 'M',  0,   0,   0,   0}, "RESERVED_VARIABLE_ISM" },
  {{7, 'R', 'E', 'A', 'L', 'D', 'F',  0}, "RESERVED_VARIABLE_REALDF" },
  {{5, '$', 'D', 'E', 'C',  0,   0,   0}, "RESERVED_VARIABLE_NDEC" },
  {{4, 'A', 'C', 'C',  0,   0,   0,   0}, "RESERVED_VARIABLE_ACC" },
  {{6, 161, 145, 'L', 'i', 'm',  0,   0}, "RESERVED_VARIABLE_ULIM" },
  {{6, 161, 147, 'L', 'i', 'm',  0,   0}, "RESERVED_VARIABLE_LLIM" },
  {{3, 'F', 'V',  0,   0,   0,   0,   0}, "RESERVED_VARIABLE_FV" },
  {{5, 'I', '%', '/', 'a',  0,   0,   0}, "RESERVED_VARIABLE_IPONA" },
  {{6, 'N', 'P', 'P', 'E', 'R',  0,   0}, "RESERVED_VARIABLE_NPPER" },
  {{7, 'P', 'P', 'E', 'R', '/',  'a', 0}, "RESERVED_VARIABLE_PPERONA" },
  {{4, 'P', 'M', 'T',  0,   0,   0,   0}, "RESERVED_VARIABLE_PMT" },
  {{3, 'P', 'V',  0,   0,   0,   0,   0}, "RESERVED_VARIABLE_PV" },
  {{7, 'G', 'R', 'A', 'M', 'O', 'D',  0}, "RESERVED_VARIABLE_GRAMOD" },
  {{4, 161, 145, 'X',  0,   0,   0,   0}, "RESERVED_VARIABLE_UX" },
  {{4, 161, 147, 'X',  0,   0,   0,   0}, "RESERVED_VARIABLE_LX" },
  {{7, 'C', 'P', 'E', 'R', '/', 'a',  0}, "RESERVED_VARIABLE_CPERONA" },
  {{6, 161, 145, 'E', 'S', 'T',  0,   0}, "RESERVED_VARIABLE_UEST" },
  {{6, 161, 147, 'E', 'S', 'T',  0,   0}, "RESERVED_VARIABLE_LEST" },
  {{4, 161, 145, 'Y',  0,   0,   0,   0}, "RESERVED_VARIABLE_UY" },
  {{4, 161, 147, 'Y',  0,   0,   0,   0}, "RESERVED_VARIABLE_LY" },
};

int main() {
  int i, j;

  puts("struct reservedRegister {");
  puts("  char name[7];");
  puts("  register_t reg;");
  puts("};\n");
  puts("%%");
  for(i=0; i < sizeof(names)/sizeof(*names); i++) {
    int n = names[i].name[0];

    for(j=1; j<= n; j++) {
      putchar(names[i].name[j]);
    }
    printf(",%s\n", names[i].reg);
  }
  return 0;
}
