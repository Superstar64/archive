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

  fixed(T rhs) : internal(0) { internal = rhs * fixed_mul; }

  fixed(T number, T frac) : internal(0) {
    internal = number * fixed_mul + frac;
  }

  fixed operator-() const { return create(-internal); }
  fixed operator+(fixed const rhs) const {
    return create(internal + rhs.internal);
  }

  fixed operator-(fixed const rhs) const {
    return create(internal - rhs.internal);
  }

  fixed operator*(fixed const rhs) const {
    return create(internal * rhs.internal / fixed_mul);
  }

  fixed operator/(fixed const rhs) const {
    return create(fixed_mul * internal / rhs.internal);
  }

  fixed operator%(fixed const rhs) const {
    return create(internal % rhs.internal);
  }

  void operator+=(fixed const rhs) { *this = *this + rhs; }

  void operator-=(fixed const rhs) { *this = *this - rhs; }

  void operator*=(fixed const rhs) { *this = *this * rhs; }

  void operator/=(fixed const rhs) { *this = *this / rhs; }

  void operator%=(fixed const rhs) { *this = *this % rhs; }

  bool operator==(fixed const rhs) const { return internal == rhs.internal; }

  bool operator!=(fixed const rhs) const { return internal != rhs.internal; }

  bool operator>(fixed const rhs) const { return internal > rhs.internal; }

  bool operator<(fixed const rhs) const { return internal < rhs.internal; }

  bool operator>=(fixed const rhs) const { return internal >= rhs.internal; }

  bool operator<=(fixed const rhs) const { return internal <= rhs.internal; }

  ratio<T> to_ratio() const { return ratio<T>(internal, fixed_mul); }
};
}
