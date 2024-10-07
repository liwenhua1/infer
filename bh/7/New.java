import java.util.*;

public class New {
    
}

class A {
  public A x;
  public Object foo(){ return new Object();} }
class B extends A {public Object foo(){return null;}}
class DynamicDispatch {

 public void clearCausesEmptinessNPEBad(A l) {
     if (l.x instanceof B) {
    
     }
     if (l.x instanceof A){
    B h = (B) l.x;}
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