
class Supertype {
   
  int t;

  public void change(Supertype a) {
    int b = a.t;
    a.t = (-b);
  }
  

    //      public Integer foo(int b) 
    //    //seems input parameter has no type, but constructed parameter has type
    //    //static //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
    //    //dynamic //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
    //    {
      
    //     if ( 8 > b ) {
            
    //         return null;
    //     }
    //     return 100;
    //    }

    //    public void test5() {
    //     Integer k = foo(4);
    //     k.toString();
    //    }
     
         public String foo1(Object b) 
       //seems input parameter has no type, but constructed parameter has type
       //static //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
       //dynamic //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
       {
        
        Supertype q = (Supertype) b;
        if (b instanceof Subtype ) {
           {
            q.toString();
            Subtype c = (Subtype) b;
            

            if (b instanceof Subtype2) {
                Subtype z = (Subtype) b;
            }
            return null;}
        } else {
            Subtype c = (Subtype) b;
        return "null";}
       }
      //   public Supertype() {
      //     t = 4;
      //   }
      //    public String foo1(Object b) 
      //  //seems input parameter has no type, but constructed parameter has type
      //  //static //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
      //  //dynamic //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
      //  {
        
    
        // if (b instanceof Supertype ) {
        //    {
   
        //     // Supertype c = (Supertype) b;
            

            
        //     }
        // } 
        //     Supertype d = (Supertype) b;
        //      // Subtype c = (Subtype) b;
        // return "null";
       

      //   public void tt3(Object a) {
        
      //   String b =foo (a); //three disj all latent
      //   b.toString();
      //   }
      // public void tt4(Subtype a) {
        
      //   tt3 (a); 
        
      // }

      //  public void tt3() {
      //   Supertype a = new Supertype();
      //   if (a instanceof Object) {
      //     a.toString();
      //   } else {a.toString();}
      //   }

      // public void tt() {
      //   Object a = new Object();
      //  foo1 (a); //cast err 1 disj
        
      // }
    //    public void tt2() {
    //      Subtype2 a = new Subtype2();
    //      foo (a); // cast err 1 disj
         
    //   }
     

      //  public void tt5() {
         
      //   String x = foo (tt4());
      //   x.toString(); 
      // }

     

      // public void tt5(Subtype a) {
      //   if (a instanceof Object) {
      //   a.toString();} //2 disj cast err
      //   else {a.toString();}
      // }

      //  public void tt4() {
      //   Supertype a = new Supertype();
      //   if (a instanceof Supertype) {
      //   String b =null;
      //   b.toString();}

      //   else {
      //     a.toString();
      //   }
      // }

      // public Object tt4() {
      //   return new Object();
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
       
    public Object foo() {
      return new Object();
    }

  }
     
 class Subtype extends Supertype {
    // public void test() 
    //    //seems input parameter has no type, but constructed parameter has type
    //    //static //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
    //    //dynamic //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
    //    {
    //     Object a = null;
    //      a.toString();}  
    @Override
    public Object foo() {
      return null;
    }


  

  // static void dynamicDispatchShouldNotCauseFalseNegativeEasyBad() {
  //   Supertype o = new Subtype();
  //   // should report a warning because we know the dynamic type of o is Subtype
  //   o.foo().toString();
  // }

  // static void dynamicDispatchShouldNotCauseFalsePositiveEasyOK() {
  //   Supertype o = new Subtype();
  //   // should not report a warning because we know the dynamic type of o is Subtype
  //   o.bar().toString();
  // }

  public void typeOK(Supertype o) {
    // should not report a warning because the Supertype implementation
    // of foo() does not return null

    // Supertype x = new Subtype();
    o.foo().toString();
  }

  // public Supertype test(Supertype o) {
  //     return o;
  // }

  // public void try1(){
  //     Subtype a = new Subtype();
  //     test(a);
  // }

  // static void dynamicDispatchShouldReportWhenCalledWithSubtypeParameterBad_AUX() {
  //   // should report a warning because the Subtype implementation
  //   // of foo() returns null
  //   // Supertype o = new Supertype();
  //   dynamicDispatchShouldNotReportWhenCallingSupertypeOK(o);
  // }

  public void Bad_FN(Subtype o) {
    // should report a warning because the Subtype implementation
    // of foo() returns null
    // Supertype o = new Supertype();
    typeOK(o);
  }

  //   public void Bad_FN2() {
  //   // should report a warning because the Subtype implementation
  //   // of foo() returns null
  //   Subtype o = new Subtype();
  //   typeOK(o);
  // }



 }
 class Subtype2 extends Supertype {}
 class Sub extends Subtype{}
 class Sub1 extends Sub{}
   
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

 class ExternalContext_test { 

    public Object request ;
    public Object response;


    public  Object getRequest() {

      // request = new Object();
      return (Object) request;}

    public  Object getResponse() {return (Object) response;}
 }