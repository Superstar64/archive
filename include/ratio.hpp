#pragma once

#include <iostream>

namespace number {

template <typename T, const T& ratio_mul>
struct fixed;

template <typename T>
struct ratio {
 private:
  static T gcf(T a, T b) {
    if (b == 0) {
      return a;
    } else {
      return gcf(b, a % b);
    }
  }
  static T abs(T a) {
    if (a < 0) {
      return -a;
    } else {
      return a;
    }
  }

 public:
  T top;
  T bottom;
  ratio(T num) : top(num), bottom(1) {}
  ratio(T up, T down) {
    top = up;
    bottom = down;
    if (bottom < 0) {
      top = -top;
      bottom = -bottom;
    }
    auto gcd = gcf(abs(top), abs(bottom));
    top /= gcd;
    bottom /= gcd;
  }

  ratio operator-() const { return ratio(-top, bottom); }

  ratio operator+(const ratio rhs) const {
    return ratio(top * rhs.bottom + bottom * rhs.top, bottom * rhs.bottom);
  }

  ratio operator-(const ratio rhs) const {
    return ratio(top * rhs.bottom - bottom * rhs.top, bottom * rhs.bottom);
  }

  ratio operator*(const ratio rhs) const {
    return ratio(top * rhs.top, bottom * rhs.bottom);
  }

  ratio operator/(const ratio rhs) const {
    return ratio(top * rhs.bottom, bottom * rhs.top);
  }

  ratio operator%(const ratio rhs) const {
    return ratio((top * rhs.bottom) % (bottom * rhs.top), bottom * rhs.bottom);
  }

  void operator+=(const ratio rhs) { *this = *this + rhs; }

  void operator-=(const ratio rhs) { *this = *this - rhs; }

  void operator*=(const ratio rhs) { *this = *this * rhs; }

  void operator/=(const ratio rhs) { *this = *this / rhs; }

  void operator%=(const ratio rhs) { *this = *this % rhs; }

  bool operator==(const ratio rhs) const {
    return top == rhs.top && bottom == rhs.bottom;
  }

  bool operator!=(const ratio rhs) const { return !(*this == rhs); }

  bool operator>(const ratio rhs) const {
    return top * rhs.bottom > bottom * rhs.top;
  }

  bool operator<(const ratio rhs) const {
    return top * rhs.bottom < bottom * rhs.top;
  }

  bool operator>=(const ratio rhs) const {
    return top * rhs.bottom >= bottom * rhs.top;
  }

  bool operator<=(const ratio rhs) const {
    return top * rhs.bottom <= bottom * rhs.top;
  }

  template <const T& fixed_mul>
  fixed<T, fixed_mul> to_fixed() const {
    return fixed<T, fixed_mul>(top / bottom, top % bottom * fixed_mul / bottom);
  }
};
}
