import java.util.*;

public class New {
    
}

class A {
  int x;}
class DynamicDispatch {

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

//   static interface Interface {
//     public String foo();
//   }

//   static class Impl implements Interface {
//     @Override
//     public String foo() {
//       List<String> list = new ArrayList<>();
//       return null;
//     }
//   }


//   static void FN_interfaceShouldNotCauseFalseNegativeHardOK(Interface i) {
    
//     i.foo().toString();
//   }
// }