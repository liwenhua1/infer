public class Supertype {
  
     
         public String foo(Object b) 
       //seems input parameter has no type, but constructed parameter has type
       //static //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
       //dynamic //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
       {
        
        Supertype q = (Supertype) b;
        if (b instanceof Subtype ) {
           {
            // q.toString();
            // Subtype2 c = (Subtype2) b;
            

            // if (b instanceof Subtype2) {
            //     Subtype z = (Subtype) b;
            // }
            
            return null;}
        } else {
            // Subtype c = (Subtype) b;
        return "null";}
       }

      public void tt() {
        Supertype a = new Supertype();
        foo (a);
      }
      //  public void tt2() {
      //   Supertype a = new Subtype();
      //   foo (a);
      // }

//     //    public Supertype sre(){
//     //         return new Supertype();

//     //    }
//     //     public Supertype test3() 
//     //    //seems input parameter has no type, but constructed parameter has type
//     //    //static //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
//     //    //dynamic //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
//     //    {
        
//     //     Supertype a = sre();
//     //     return a; }  

      //  public void test(int x) 
      //  //seems input parameter has no type, but constructed parameter has type
      //  //static //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
      //  //dynamic //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
      //  {
      //   if (x>0){
      //   Sub1 a = (Sub1) this;}
      //   }  

      //    public void test2(int x) 
      //  //seems input parameter has no type, but constructed parameter has type
      //  //static //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
      //  //dynamic //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
      //  {
      //   test(10);
      //   }  

        
      //    public void test2() 
      //  //seems input parameter has no type, but constructed parameter has type
      //  //static //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
      //  //dynamic //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
      //  {
      //   Sub x = new Sub();
      //  String a = foo(x);
      // a.toString(); }  

       

        
       
    //    public Integer foo(int b) 
    //    //seems input parameter has no type, but constructed parameter has type
    //    //static //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
    //    //dynamic //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
    //    {
      
    //     if ( 8 > b ) {
    //         Object a = null;
    //         a.toString();
    //         return null;
    //     }
    //     return 100;
    //    }

//        public void test5() {
//         Integer k = foo(4);
//        }

//        public void wrap() {
//         test5();
//        }

//     //    public void test() 
//     //    //seems input parameter has no type, but constructed parameter has type
//     //    //static //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
//     //    //dynamic //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
//     //    {
        
//     //     Integer c = foo(-1);
//     //     int k = 6;
//     //     Integer q = foo(k);
//     //     q.toString();        
//     //    }
       
   
     }
 class Subtype extends Supertype {
    // public void test() 
    //    //seems input parameter has no type, but constructed parameter has type
    //    //static //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
    //    //dynamic //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
    //    {
    //     Object a = null;
    //      a.toString();}  
 }
 class Subtype2 extends Supertype {}
 class Sub extends Subtype{}
//  class Sub1 extends Sub{}
   
//        public Object foo() 
//        //static //presumes this::Subtype<> achieves this::Subtype<> & res = null;
//        //dynamic //presumes this::Subtype<> achieves this::Subtype<> & res = null; 
//        //dynamic //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>; 	
//        {
//          return new Object();
//        }
   
//     //  public void dynamicDispatchShouldNotReportWhenCallingSupertypeOK(Supertype a) 
//     //  //static //presumes this::Subtype<> * o::Supertype<> achieves this::Subtype<> * o::Supertype<> * temp::Objec<>;
//     //  //static //presumes this::Subtype<> * o::Subtype<> achieves err this::Subtype<> * o::Subtype<> & temp = null;
//     //  {
//     //   if (a instanceof Supertype){
//     //    a = (Subtype) a;
//     //    Object temp =  a.foo();
//     //    temp.toString();}
//     //   else {(new Object()).toString();}
//     //  }
   
//     //  public void dynamicDispatchShouldReportWhenCalledWithSubtypeParameterBad_FN(Subtype o) 
//     //  //static //presumes this::Subtype<> * o::Subtype<> achieves err this::Subtype<> * o::Subtype<>;
//     //  {
//     //    this.dynamicDispatchShouldNotReportWhenCallingSupertypeOK(o);
//     //  }
   
     
// }

// class I {
//         public Object defaultMethod1() 
//         //static //presumes this::I<> achieves ok this::I<> & res = null;
//         //dynamic //presumes this::I<> achieves ok this::I<> & res = null;
//         {
//           return new Object();
//         }
//       }
    
//      class A extends I {
    
      
    
//         public Object defaultMethod1() 
//         //static //presumes this::A<> achieves ok this::A<> & res = null;
//         //dynamic //presumes this::I<>A<>  achieves ok this::I<>A<> & res = null;
//         {
//             return null;
//         }
    
//         public void defaultCallNPE(I i) 
//         //static //presumes this::A<> achieves err this::A<> & temp = null;
//         {
//           Object temp = i.defaultMethod1();
//           temp.toString();
//         }
    
//       }
