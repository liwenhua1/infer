public class Supertype {
      
         public String foo(Object b) 
       //seems input parameter has no type, but constructed parameter has type
       //static //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
       //dynamic //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
       {
      
        if (b instanceof Supertype ) {
           {
            return null;}
        }
        return "aaaa";
       }

       public void test() 
       //seems input parameter has no type, but constructed parameter has type
       //static //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
       //dynamic //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
       {
        Subtype a = new Subtype();
        String c = foo(a);
        c.toString();        
       }
    //    public Integer foo(int b) 
    //    //seems input parameter has no type, but constructed parameter has type
    //    //static //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
    //    //dynamic //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
    //    {
      
    //     if ( 8 > b && b > 0 ) {
    //         return null;
    //     }
    //     return 100;
    //    }

    //    public void test() 
    //    //seems input parameter has no type, but constructed parameter has type
    //    //static //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
    //    //dynamic //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
    //    {
        
    //     Integer c = foo(-1);
    //     int k = 6;
    //     Integer q = foo(k);
    //     q.toString();        
    //    }
       
   
     }
 class Subtype extends Supertype {}
   
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
