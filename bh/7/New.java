import java.util.*;

public class New {
    
}

class A {
  int x;}
class DynamicDispatch {

  void clearCausesEmptinessNPEBad(List l) {
    l.clear();
    Object o = null;
    if (l.isEmpty()) {
      o.toString();
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