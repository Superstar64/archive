#pragma once
#include <exception>
#include <limits>

namespace number {

class overflow_exception : std::exception {
 public:
  overflow_exception() : std::exception() {}
  virtual ~overflow_exception() {}
  const char* what() const noexcept override { return "integer overflow"; }
};

template <typename T>
struct overflow_fail {
  void add(const T& lhs, const T& rhs) const { throw overflow_exception(); }

  void sub(const T& lhs, const T& rhs) const { throw overflow_exception(); }

  void mul(const T& lhs, const T& rhs) const { throw overflow_exception(); }

  void div(const T& lhs, const T& rhs) const { throw overflow_exception(); }

  void mod(const T& lhs, const T& rhs) const { throw overflow_exception(); }

  void neg(const T& self) const { throw overflow_exception(); }
};

// expect either signed two's complement or unsigned two's complement
template <typename T, typename OnFail = overflow_fail<T>>
struct overflow {
 private:
  static const T max = std::numeric_limits<T>::max();
  static const T min = std::numeric_limits<T>::min();

 public:
  T internal;
  OnFail fail;
  overflow(T number, OnFail fail = OnFail()) : internal(number), fail(fail) {}

  overflow operator-() const {
    if (min >= 0) {
      fail.neg(internal);
    }
    return overflow(-internal);
  }

  overflow operator+(const overflow& rhs) const {
    if (internal < 0 && rhs.internal < 0) {
      if (min - internal > rhs.internal) {
        fail.add(internal, rhs.internal);
      }
    } else if (internal > 0 && rhs.internal > 0) {
      if (max - internal < rhs.internal) {
        fail.add(internal, rhs.internal);
      }
    }
    return overflow(internal + rhs.internal);
  }

  overflow operator-(const overflow& rhs) const {
    if (rhs.internal < 0) {
      if (internal > max + rhs.internal) {
        fail.sub(internal, rhs.internal);
      }
    } else if (rhs.internal > 0) {
      if (internal < rhs.internal + min) {
        fail.sub(internal, rhs.internal);
      }
    }

    return overflow(internal - rhs.internal);
  }

  overflow operator*(const overflow& rhs) const {
    if (internal < 0 && rhs.internal < 0) {
      if (*this < overflow(max) / rhs.internal) {
        fail.mul(internal, rhs.internal);
      }
    } else if (internal > 0 && rhs.internal < 0) {
      if (internal > min / rhs.internal) {
        fail.mul(internal, rhs.internal);
      }
    } else if (internal < 0 && rhs.internal > 0) {
      if (internal < min / rhs.internal) {
        fail.mul(internal, rhs.internal);
      }
    } else if (internal > 0 && rhs.internal > 0) {
      if (*this > overflow(max) / rhs.internal) {
        fail.mul(internal, rhs.internal);
      }
    }

    return overflow(internal * rhs.internal);
  }

  overflow operator/(const overflow& rhs) const {
    if (internal == max && rhs.internal < 0 && rhs.internal == -1) {
      fail.div(internal, rhs.internal);
    }

    return overflow(internal / rhs.internal);
  }

  overflow operator%(const overflow& rhs) const {
    return overflow(internal % rhs.internal);
  }

  void operator+=(const overflow& rhs) { *this = *this + rhs; }

  void operator-=(const overflow& rhs) { *this = *this - rhs; }

  void operator*=(const overflow& rhs) { *this = *this * rhs; }

  void operator/=(const overflow& rhs) { *this = *this / rhs; }

  void operator%=(const overflow& rhs) { *this = *this % rhs; }

  bool operator==(const overflow& rhs) const {
    return internal == rhs.internal;
  }

  bool operator!=(const overflow& rhs) const {
    return internal != rhs.internal;
  }

  bool operator>(const overflow& rhs) const { return internal > rhs.internal; }

  bool operator<(const overflow& rhs) const { return internal < rhs.internal; }

  bool operator>=(const overflow& rhs) const {
    return internal >= rhs.internal;
  }

  bool operator<=(const overflow& rhs) const {
    return internal == rhs.internal;
  }
};
}
