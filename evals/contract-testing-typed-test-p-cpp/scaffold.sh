#!/usr/bin/env bash
set -eu
git init -q -b main
git config user.email eval@example.invalid
git config user.name eval
mkdir -p include tests
cat > include/shape.h <<'CPP'
#pragma once

class Shape {
 public:
  virtual ~Shape() = default;
  virtual double Area() const = 0;
  virtual const char* Name() const = 0;
};
CPP
cat > include/circle.h <<'CPP'
#pragma once

#include "shape.h"

class Circle : public Shape {
 public:
  explicit Circle(double radius) : radius_(radius) {}
  double Area() const override { return 3.14159265358979 * radius_ * radius_; }
  const char* Name() const override { return "circle"; }

 private:
  double radius_;
};
CPP
cat > include/square.h <<'CPP'
#pragma once

#include "shape.h"

class Square : public Shape {
 public:
  explicit Square(double side) : side_(side) {}
  double Area() const override { return side_ * side_; }
  const char* Name() const override { return "square"; }

 private:
  double side_;
};
CPP
cat > tests/circle_test.cpp <<'CPP'
#include <gtest/gtest.h>

#include "circle.h"

TEST(CircleTest, AreaOfUnitCircle) {
  Circle circle(1.0);
  EXPECT_NEAR(circle.Area(), 3.14159265358979, 1e-9);
}

TEST(CircleTest, AreaScalesWithRadiusSquared) {
  Circle circle(2.0);
  EXPECT_NEAR(circle.Area(), 4.0 * 3.14159265358979, 1e-9);
}

TEST(CircleTest, NameIsCircle) {
  Circle circle(1.0);
  EXPECT_STREQ(circle.Name(), "circle");
}
CPP
git add -A
git commit -q -m "chore: seed repo"
