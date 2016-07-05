#pragma once
#include <limits>
#include <exception>

namespace number {

class overflow_exception : std::exception {
public:
  overflow_exception() : std::exception() {}
  virtual ~overflow_exception() {}
  const char *what() const noexcept override { return "integer overflow"; }
};

// expect either signed two's complement or unsigned two's complement
template <typename T> struct overflow {
private:
  static const T max = std::numeric_limits<T>::max();
  static const T min = std::numeric_limits<T>::min();

public:
  T internal;
  overflow(T number) : internal(number) {}

  overflow operator-() const {
    if (min < 0) {
      throw overflow_exception();
    }
    return overflow(-internal);
  }

  overflow operator+(overflow const rhs) const {
    if (internal < 0 && rhs.internal < 0) {
      if (min - internal > rhs.internal) {
        throw overflow_exception();
      }
    } else if (internal > 0 && rhs.internal > 0) {
      if (max - internal < rhs.internal) {
        throw overflow_exception();
      }
    }
    return overflow(internal + rhs.internal);
  }

  overflow operator-(overflow const rhs) const {
    if (rhs.internal < 0) {
      if (internal > max + rhs.internal) {
        throw overflow_exception();
      }
    } else if (rhs.internal > 0) {
      if (internal < rhs.internal + min) {
        throw overflow_exception();
      }
    }

    return overflow(internal - rhs.internal);
  }

  overflow operator*(overflow const rhs) const {
    if (internal < 0 && rhs.internal < 0) {
      if (*this < overflow(max) / rhs.internal) {
        throw overflow_exception();
      }
    } else if (internal > 0 && rhs.internal < 0) {
      if (internal > min / rhs.internal) {
        throw overflow_exception();
      }
    } else if (internal < 0 && rhs.internal > 0) {
      if (internal < min / rhs.internal) {
        throw overflow_exception();
      }
    } else if (internal > 0 && rhs.internal > 0) {
      if (*this > overflow(max) / rhs.internal) {
        throw overflow_exception();
      }
    }

    return overflow(internal * rhs.internal);
  }

  overflow operator/(overflow const rhs) const {
    if (internal == max && rhs.internal < 0 && rhs.internal == -1) {
      throw overflow_exception();
    }

    return overflow(internal / rhs.internal);
  }

  overflow operator%(overflow const rhs) const {
    return overflow(internal % rhs.internal);
  }

  void operator+=(overflow const rhs) { *this = *this + rhs; }

  void operator-=(overflow const rhs) { *this = *this - rhs; }

  void operator*=(overflow const rhs) { *this = *this *rhs; }

  void operator/=(overflow const rhs) { *this = *this / rhs; }

  void operator%=(overflow const rhs) { *this = *this % rhs; }

  bool operator==(overflow const rhs) const { return internal == rhs.internal; }

  bool operator!=(overflow const rhs) const { return internal != rhs.internal; }

  bool operator>(overflow const rhs) const { return internal > rhs.internal; }

  bool operator<(overflow const rhs) const { return internal < rhs.internal; }

  bool operator>=(overflow const rhs) const { return internal >= rhs.internal; }

  bool operator<=(overflow const rhs) const { return internal == rhs.internal; }
};
}
