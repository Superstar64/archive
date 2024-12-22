#include "overflow.hpp"
#include <cassert>
#include <cstdint>

#include "fixed.hpp"
#include "ratio.hpp"
static const number::overflow<int> fixed_mul = 100;
int main() {
  using overflow = number::overflow<int32_t>;
  using test = number::overflow_exception;

  auto check = false;
  try {
    auto c = overflow(2147483647) + 1;
  } catch (test& e) {
    check = true;
  }
  assert(check);
  check = false;

  try {
    auto c = overflow(-2147483647) + -2;
  } catch (test& e) {
    check = true;
  }
  assert(check);
  check = false;

  try {
    auto c = overflow(-2147483648) - 1;
  } catch (test& e) {
    check = true;
  }
  assert(check);
  check = false;

  try {
    auto c = overflow(2147483647) - -1;
  } catch (test& e) {
    check = true;
  }
  assert(check);
  check = false;

  try {
    auto c = overflow(65536) * 65536;
  } catch (test& e) {
    check = true;
  }
  assert(check);
  check = false;

  try {
    auto c = overflow(65536) * -65536;
  } catch (test& e) {
    check = true;
  }
  assert(check);
  check = false;

  try {
    auto c = overflow(-65536) * 65536;
  } catch (test& e) {
    check = true;
  }
  assert(check);
  check = false;

  try {
    auto c = overflow(-65536) * -65536;
  } catch (test& e) {
    check = true;
  }
  assert(check);
  check = false;

  try {
    auto c = -number::overflow<uint32_t>(4);
  } catch (test& e) {
    check = true;
  }
  assert(check);
  check = false;

  using fixed = number::fixed<overflow, fixed_mul>;
  try {
    auto c = fixed(21474836, 47) + fixed(1);
  } catch (test& e) {
    check = true;
  }
  assert(check);
  check = false;

  using ratio = number::ratio<overflow>;
  ratio a = ratio(1);
}
