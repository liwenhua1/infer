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
  C callCallBuildC(A a1, A a2) {
    return a1.callBuildC(a2);
  }

  C buildCTransitivelyAndDerefGood() {
    A a1 = new A_Bad();
    A a2 = new A_Good();
    return this.callCallBuildC(a1,a2 ).f;
  }


}