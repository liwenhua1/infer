

public class Bench8 {
    class A {
        int i;
      }
      
      
      
      class NullPointerExceptionsMoreTests {
      
        public int testNullStringDereferencedBad() 
        //static  //presumes this::NullPointerExceptionsMoreTests<> achieves err this::NullPointerExceptionsMoreTests<> & s= null;
        {
          String s = "";
          int j = s.length();
          s = null;
          int temp = s.length();
          j = j + temp;
          return 42;
        }
      
        public int testBrachesAvoidNullPointerExceptionOK(int k) 
        //static  //presumes this::NullPointerExceptionsMoreTests<> & k > 10 achieves ok this::NullPointerExceptionsMoreTests<> & s= null & res = 100 & k >10;
        //static  //presumes this::NullPointerExceptionsMoreTests<> & k = 10 achieves ok this::NullPointerExceptionsMoreTests<> * s::Objec<> & res = 5 & k=10;
        //static  //presumes this::NullPointerExceptionsMoreTests<> & k < 10 achieves ok this::NullPointerExceptionsMoreTests<> * s::Objec<> & res = 100 & k < 10;
        {
          Object s = new Object();
          int j = 100;
          if (k > 10) {
            s = null; 
          }
          if (k == 10) {
            int temp = s.toString().length();
            j = temp;
          }
          return j;
        }
      
        public void testParameterOk(A arg) 
        //static  //presumes this::NullPointerExceptionsMoreTests<> * arg::A<i:v> achieves ok this::NullPointerExceptionsMoreTests<> * arg::A<i:17>;
        //static  //presumes this::NullPointerExceptionsMoreTests<> & arg = null achieves err this::NullPointerExceptionsMoreTests<> & arg = null;
        
        {
          arg.i = 17;
        }
      
        public int testArithmeticOk(int k) 
        //static  //presumes this::NullPointerExceptionsMoreTests<> & k > 10 achieves ok this::NullPointerExceptionsMoreTests<> & s= null & res = 100 & k >10;
        //static  //presumes this::NullPointerExceptionsMoreTests<> & k <= 10 achieves ok this::NullPointerExceptionsMoreTests<> * s::Objec<> & res = 5 & k=10;
        //static  //presumes this::NullPointerExceptionsMoreTests<> & k <= 10 achieves ok this::NullPointerExceptionsMoreTests<> * s::Objec<> & res = 5 & k<10;
      
          {
        
          Object s = new Object();
          int j = 100;
          if (k > 10) {
            s = null; 
          }
          if (k == 10) {
            int temp = s.toString().length();
            j = temp;
          }
          if (k < 10) {
            int temp =  s.toString().length();
            j = temp;
          }
          return j;
        }
      
         public int testArithmeticOneOK(int k) 
          //static  //presumes this::NullPointerExceptionsMoreTests<> & k > 10 achieves ok this::NullPointerExceptionsMoreTests<> & s= null & res = 100 & k >10;
          //static  //presumes this::NullPointerExceptionsMoreTests<> & k <= 10 achieves ok this::NullPointerExceptionsMoreTests<> * s::Objec<> & res = 5 & k=10;
          {Object s = new Object();
          int j = 100;
          if (k > 10) {
            s = null; 
          }
          int temp = k + k ;
          if (temp == 20) {
             int temp1 =  s.toString().length();
            j = temp1;
          }
          return j;
        }
      
        public int f_ident(int k) 
        //static  //presumes this::NullPointerExceptionsMoreTests<> & k = v achieves ok this::NullPointerExceptionsMoreTests<> & k = v & res = v;
      
        {
          return k;
        }
      
        public int FP_testArithmeticTwo(int k)
             //static  //presumes this::NullPointerExceptionsMoreTests<> & k > 10 achieves ok this::NullPointerExceptionsMoreTests<> & s= null & res = 100 & k >10;
             //static  //presumes this::NullPointerExceptionsMoreTests<> & k <= 10 achieves ok this::NullPointerExceptionsMoreTests<> * s::Objec<> & res = 5 & k=10;
      
         {
         
          Object s = new Object();
          int j = 100;
          if (k > 10) {
            s = null; 
          }
           int temp = this.f_ident(k);
          if ( temp == 10) {
      
            int temp1 =  s.toString().length();
            j = temp1;
          }
          return j;
        }
      
      }
      
      class OtherClass {
      
        OtherClass x;
      
        OtherClass ()
          //static 
              //presumes true achieves new_this::OtherClass<x:null>;
          {}
      
      
        public OtherClass canReturnNull() 
        //static  //presumes this::OtherClass<x:null> achieves ok this::OtherClass<x:null> & res = null;
      
        {
            OtherClass z = this.x;
          return z;
        }
      
        public String buggyMethodBad() 
        //static  //presumes this::OtherClass<x:null> achieves err this::OtherClass<x:null> * o::OtherClass<x:null>;
        {
          OtherClass o = new OtherClass();
          OtherClass temp = o.canReturnNull();
          return temp.toString();
        }
      
        public void testingNullsafeLocalMode() 
        //static  //presumes this::OtherClass<x:null> achieves err this::OtherClass<x:null> * o::OtherClass<x:null>;
      
        {
          OtherClass o = new OtherClass();
          OtherClass temp = o.canReturnNull();
          temp.getClass();
        }
      
       
      }
}
