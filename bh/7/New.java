import java.util.*;

public interface New {

  public void foo();
  
} 

class A implements New{
  public void foo() {
    "s".toString();
  }
}

class B extends A{
  public void foo() {
    "H".toString();
  }

  public void eeee(New x) {
    x.foo();
  }
}

/**
 * InnerNew
 */


  


 



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