public class Supertype {
    
       public Integer foo(Object b) 
       //seems input parameter has no type, but constructed parameter has type
       //static //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
       //dynamic //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
       {
        Object y = new Supertype();
        if (y instanceof Object) {
            return null;
        }
        return 3;
       }

       
   
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
