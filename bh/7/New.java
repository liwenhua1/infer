public class New {
    
}
 class DynamicDispatch {

  static interface Interface {
    public Object foo();
  }

  static class Impl implements Interface {
    @Override
    public Object foo() {
      return null;
    }
  }


  static void FN_interfaceShouldNotCauseFalseNegativeHardOK(Interface i) {
    i.foo().toString();
  }
}