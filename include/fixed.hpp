#pragma once

#include "ratio.hpp"

namespace number {

template <typename T, const T& fixed_mul>
struct fixed {
 private:
  static fixed create(T val) {
    auto ret = fixed();
    ret.internal = val;
    return ret;
  }

 public:
  T internal;
  fixed() : internal(0) {}

  fixed(const T& rhs) : internal(0) { internal = rhs * fixed_mul; }

  fixed(const T& number, const T& frac) : internal(0) {
    internal = number * fixed_mul + frac;
  }

  fixed operator-() const { return create(-internal); }
  fixed operator+(const fixed& rhs) const {
    return create(internal + rhs.internal);
  }

  fixed operator-(const fixed& rhs) const {
    return create(internal - rhs.internal);
  }

  fixed operator*(const fixed& rhs) const {
    return create(internal * rhs.internal / fixed_mul);
  }

  fixed operator/(const fixed& rhs) const {
    return create(fixed_mul * internal / rhs.internal);
  }

  fixed operator%(const fixed& rhs) const {
    return create(internal % rhs.internal);
  }

  void operator+=(const fixed& rhs) { *this = *this + rhs; }

  void operator-=(const fixed& rhs) { *this = *this - rhs; }

  void operator*=(const fixed& rhs) { *this = *this * rhs; }

  void operator/=(const fixed& rhs) { *this = *this / rhs; }

  void operator%=(const fixed& rhs) { *this = *this % rhs; }

  bool operator==(const fixed& rhs) const { return internal == rhs.internal; }

  bool operator!=(const fixed& rhs) const { return internal != rhs.internal; }

  bool operator>(const fixed& rhs) const { return internal > rhs.internal; }

  bool operator<(const fixed& rhs) const { return internal < rhs.internal; }

  bool operator>=(const fixed& rhs) const { return internal >= rhs.internal; }

  bool operator<=(const fixed& rhs) const { return internal <= rhs.internal; }

  ratio<T> to_ratio() const { return ratio<T>(internal, fixed_mul); }
};
}
