#include "fixed.hpp"
#include <cassert>
#include <cstdio>

const int fixed_mul = 100;

int main() {
  using fixed = number::fixed<int, fixed_mul>;
  using ratio = number::ratio<int>;
  fixed a = 5;
  fixed b(4, 25);
  assert(a == a);
  assert(b == b);
  assert(a != b);
  assert(a + b == fixed(9, 25));
  assert(a - b == fixed(0, 75));
  assert(a * b == fixed(21, 25));
  assert(a / b == fixed(1, 17));
  assert(a % b == fixed(0, 75));
  assert(a + 5 == fixed(10, 0));
  assert(a == 5);
  assert(a < 6);
  assert(a <= 5);
  assert(a > 4);
  assert(a >= 5);

  assert(a > b);

  assert(a.to_ratio() == ratio(5, 1));
  assert(b.to_ratio() == ratio(425, 100));

  return 0;
}
