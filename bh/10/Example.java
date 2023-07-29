public class Example{
    
class A {
   
    public int foo() 
    {
      return 32;
    }
  }

  class B extends A {

    public int foo() 
    {
      return 52;
    }
  }

  class C extends B {

  public A getB() 

  {
    return new B();
  }

  public void dispatch_to_B_ok() 
  {
    A b = this.getB();
    int temp = b.foo();
    if (temp == 32) {
      Object o = null;
      o.toString(); //false positive here
    }
  }}

}