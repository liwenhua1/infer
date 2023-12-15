public class DynamicDispatch {

//   static class Supertype {
//     Object foo() {
//       return new Object();
//     }

//   }

//   static class Subtype extends Supertype {
//     @Override
//     Object foo() {
//       return null;
//     }


//   }



//   static Object dynamicDispatchWrapperFoo(Supertype o) {
//     return o.foo();
//   }

 

//   static void dynamicDispatchCallsWrapperWithSupertypeOK() {
//     // Should not report because Supertype.foo() does not return null
//     Supertype o = new Supertype();
//     dynamicDispatchWrapperFoo(o).toString();
//   }

  static class C {
    C f;
  }

  abstract static class A {
    abstract C buildC();

    C callBuildC(A a) {
      return a.buildC();
    }
  }

  static class A_Good extends A {


    C buildC() {
      return new C();
    }

  }

  static class A_Bad extends A {
    C buildC() {
      return null;
    }

  }



  // require iterative specialization
  C callBuildCTwiceGood(A a1, A a2) {
    C c = (a1 == null) ? null : a1.buildC();
    return (a2 == null) ? null : a2.buildC();
  }

  C buildCAndDerefNeedPartialSpecializationBad(A a) {
    return callBuildCTwiceGood(a, new A_Bad()).f;
  }

}