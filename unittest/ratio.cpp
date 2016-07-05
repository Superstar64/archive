#include "ratio.hpp"
#include "fixed.hpp"
#include <cassert>
int fixed_mul = 100;
int main() {
  using ratio = number::ratio<int>;
  using fixed = number::fixed<int, fixed_mul>;
  ratio a(5, 3);
  ratio b(4, 5);
  assert(a + b == ratio(37, 15));
  assert(a - b == ratio(13, 15));
  assert(a * b == ratio(20, 15));
  assert(a / b == ratio(25, 12));
  assert(a % b == ratio(1, 15));
  assert(a == a);
  assert(b == b);
  assert(a > b);
  assert(b < a);
  assert(a >= a);
  assert(a < ratio(2));
  assert(a > ratio(1));
  assert(a.template to_fixed<fixed_mul>() == fixed(1, 66));
  assert(ratio(-4, -6) == ratio(2, 3));
  assert(ratio(-4, 6) == ratio(2, -3));
}
