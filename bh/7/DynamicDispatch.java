// public class DynamicDispatch {



//   public void test(int x) {
//     if (x>7) {x = x+1;}
//     else {x = x-1;}
//     DynamicDispatch z = null;
//     z.toString();

//   }

// //   static class Supertype {
// //     Object foo() {
// //       return new Object();
// //     }

// //   }

// //   static class Subtype extends Supertype {
// //     @Override
// //     Object foo() {
// //       return null;
// //     }


// //   }



// //   static Object dynamicDispatchWrapperFoo(Supertype o) {
// //     return o.foo();
// //   }

 

// //   static void dynamicDispatchCallsWrapperWithSupertypeOK() {
// //     // Should not report because Supertype.foo() does not return null
// //     Supertype o = new Supertype();
// //     dynamicDispatchWrapperFoo(o).toString();
// //   }

//   static class C {
//     C f;
//   }

//   abstract static class A {
//     abstract C buildC();

//     C callBuildC(A a) {
//       return a.buildC();
//     }
//   }

//   static class A_Good extends A {


//     C buildC() {
//       return new C();
//     }

//   }

//   static class A_Bad extends A {
//     C buildC() {
//       return null;
//     }

//   }



//   // require iterative specialization
//   C callBuildCTwiceGood(A a1, A a2) {
//     C c = (a1 == null) ? null : a1.buildC();
//     return (a2 == null) ? null : a2.buildC();
//   }

//   C buildCAndDerefNeedPartialSpecializationBad(A a) {
//     return callBuildCTwiceGood(a, new A_Bad()).f;
//   }

// }

/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

// public class DynamicDispatch {
//   public static void main(String[] args) {
//     Object a = new Object();
//     DefaultInInterface b = new DefaultInInterface();
//     b.testCheckNotNullArgOk(a);
// }
// }

class DefaultInInterface {

  static class A{}

  public <T> T id_generics(T o) {
    o.toString();
    return o;
  }

  public A frame(A x) {
    return id_generics(x);
  }

  public void nullPointerExceptionUnlessFrameFails() {
    String s = null;
    Object a = frame(new A());
    if (a instanceof A) {
      s.length();
    }
  }
  
}
