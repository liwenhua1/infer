public class Supertype {
    
       public Object foo() 
       //static //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
       //dynamic //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
       {
         return null;
       }
   
     }
class Subtype extends Supertype {
   
       public Object foo() 
       //static //presumes this::Subtype<> achieves this::Subtype<> & res = null;
       //dynamic //presumes this::Subtype<> achieves this::Subtype<> & res = null; 
       //dynamic //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>; 	
       {
         return new Object();
       }
   
     public void dynamicDispatchShouldNotReportWhenCallingSupertypeOK(Supertype a) 
     //static //presumes this::Subtype<> * o::Supertype<> achieves this::Subtype<> * o::Supertype<> * temp::Objec<>;
     //static //presumes this::Subtype<> * o::Subtype<> achieves err this::Subtype<> * o::Subtype<> & temp = null;
     {
       Object temp =  a.foo();
       temp.toString();
     }
   
     public void dynamicDispatchShouldReportWhenCalledWithSubtypeParameterBad_FN(Subtype o) 
     //static //presumes this::Subtype<> * o::Subtype<> achieves err this::Subtype<> * o::Subtype<>;
     {
       this.dynamicDispatchShouldNotReportWhenCallingSupertypeOK(o);
     }
   
     
}
