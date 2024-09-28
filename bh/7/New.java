public class New {
    
}

class Specialization {

    static class C {
      C f;
    }
  
    abstract static class A {
      abstract C buildC();
  
      abstract C callBuildC(A a);
    }
  
    static class A_Good extends A {
      C buildC() {
        return new C();
      }
  
      C callBuildC(A a) {
        return a.buildC();
      }
    }
  
    static class A_Bad extends A {
      C buildC() {
        return null;
      }
  
      C callBuildC(A a) {
        return a.buildC();
      }
    }
  
    // basic specialization on parameters
    C callBuildCGood(A a) {
      return a.buildC();
    }
  
    C buildCAndDerefBad() {
      return callBuildCGood(new A_Bad()).f;
    }}
