class InheritanceDispatch {
  class A {
    int foo() {
      return 32;
    }
  }

  class B extends A {
    int foo() {
      return 52;
    }
  }

  class C extends B {}

  A getB() {
    return new B();
  }

  A getC() {
    return new C();
  }

  void dispatch_to_C_bad() {
    A c = getC();
    // int b = c.foo();
    if (c.foo() == 52) {
      Object o = null;
      o.toString();
    }
  }
}