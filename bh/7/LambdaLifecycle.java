import java.util.function.Consumer;

public class LambdaLifecycle {
    private String enclosingField = "Hi";
  
    public void main() {
      String myStr = "local var";
      Consumer<String> lambdaPrinter = str -> {
      this.superPrint(myStr); // compile error
     // myStr = "foo";  // because of this
      enclosingField = "bar";
};
      Printer myPrinter = new Printer();
    }
  
    void superPrint(String str) {
      System.out.println(str);
    }
  
    class Printer {
      public void accept(String str) {
        superPrint(str); // can't use `this` here because of different scope
      }
    }
  }