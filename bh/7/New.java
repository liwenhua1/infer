import java.util.*;

public class New {
    
}

class A {public Object foo(){ return new Object();} }
class B extends A {public Object foo(){return null;}}
class DynamicDispatch {

  void clearCausesEmptinessNPEBad(A l) {
     if (l instanceof B) {
      
     }
    else {l.toString();}
  }

  void clearCausesEmptinessNPEBad2(B l) {
    clearCausesEmptinessNPEBad(null);
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