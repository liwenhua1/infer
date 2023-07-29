

public class Bench13 {
    class Interface{}

    
    
    class Impl extends Interface{
      
       public Object foo() 
       //static //presumes this::Impl<> achieves ok this::Impl<> & res = null;
       {
         return null;
       }
     
      
   
     public void interfaceShouldNotCauseFalseNegativeEasyBad() 
     //static //presumes this::Impl<> achieves err this::Impl<> * i::Impl<> & m = null;
     {
       Interface i = new Impl();
       Object m = ((Impl)i).foo();
       m.toString();
     }
   
     public void FN_interfaceShouldNotCauseFalseNegativeHardOK(Interface i) 
     //static //presumes this::Impl<> * i::Impl<> achieves err this::Impl<> * i::Impl<> & m = null;
     {
       Object m = ((Impl)i).foo();
       m.toString();
     }
   
     public void callWithBadImplementationBad_FN(Impl impl) 
     //static //presumes this::Impl<> * impl::Impl<> achieves err this::Impl<> * impl::Impl<>;
     {
       this.FN_interfaceShouldNotCauseFalseNegativeHardOK(impl);
     } 
    }
   
   class Supertype {
       Supertype ()
       //static
           //presumes true achieves new_this::Supertype<>;
       {}
   
   
       public Object foo() 
       //static //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
       //dynamic //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
       {
         return new Object();
       }
   
       public Object bar() 
       //static //presumes this::Supertype<> achieves this::Supertype<> & res = null;
       //dynamic //presumes this::Supertype<> achieves this::Supertype<> & res = null;
       {
         return null;
       }
     }
   
   class Subtype extends Supertype {
   
       Subtype ()
       //static
           //presumes true achieves new_this::Subtype<>;
       {}
      
       public Object foo() 
       //static //presumes this::Subtype<> achieves this::Subtype<> & res = null;
       //dynamic //presumes this::Subtype<> achieves this::Subtype<> & res = null; 
       //dynamic //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>; 	
       {
         return null;
       }
   
       
       public Object bar() 
       //static //presumes this::Subtype<> achieves this::Subtype<> * res::Objec<>;
       //dynamic //presumes this::Subtype<> achieves this::Subtype<> * res::Objec<>; 
       //dynamic //presumes this::Supertype<> achieves this::Supertype<> & res = null; 	
       {
         return new Object();
       }
   
       public void dynamicDispatchShouldNotCauseFalseNegativeEasyBad() 
       //static //presumes this::Subtype<> achieves  err this::Subtype<> * o::Subtype<> & temp = null;
       {
       Supertype o = new Subtype();
       Object temp =  o.foo();
       temp.toString();
     }
   
     public void dynamicDispatchShouldNotCauseFalsePositiveEasyOK() 
     //static //presumes this::Subtype<> achieves this::Subtype<> * o::Subtype<> * temp::Objec<>;
     {
       Supertype o = new Subtype();
       Object temp =  o.bar();
       temp.toString();
     }
   
     public void dynamicDispatchShouldNotReportWhenCallingSupertypeOK(Supertype o) 
     //static //presumes this::Subtype<> * o::Supertype<> achieves this::Subtype<> * o::Supertype<> * temp::Objec<>;
     //static //presumes this::Subtype<> * o::Subtype<> achieves err this::Subtype<> * o::Subtype<> & temp = null;
     {
       Object temp =  o.foo();
       temp.toString();
     }
   
     public void dynamicDispatchShouldReportWhenCalledWithSubtypeParameterBad_FN(Subtype o) 
     //static //presumes this::Subtype<> * o::Subtype<> achieves err this::Subtype<> * o::Subtype<>;
     {
       this.dynamicDispatchShouldNotReportWhenCallingSupertypeOK(o);
     }
   
     public Object dynamicDispatchWrapperFoo(Supertype o) 
     //static //presumes this::Subtype<> * o::Supertype<> achieves this::Subtype<> * o::Supertype<> * res::Objec<>;
     //static //presumes this::Subtype<> * o::Subtype<> achieves  this::Subtype<> * o::Subtype<> & res = null;
     {
       Object temp = o.foo();
       return temp;
     }
   
     public Object dynamicDispatchWrapperBar(Supertype o) 
       //static //presumes this::Subtype<> * o::Subtype<> achieves this::Subtype<> * o::Subtype<> * res::Objec<>;
       //static //presumes this::Subtype<> * o::Supertype<> achieves  this::Subtype<> * o::Supertype<> & res = null;
     {
        Object temp = o.bar();
       return temp;
     }
   
     public void dynamicDispatchCallsWrapperWithSupertypeOK() 
     //static //presumes this::Subtype<> achieves this::Subtype<> * q::Supertype<> * temp::Objec<>;
     {
      
       Supertype q = new Supertype();
       Object temp=this.dynamicDispatchWrapperFoo(q);
       temp.toString();
     }
   
     public void dynamicDispatchCallsWrapperWithSupertypeBad() 
     //static //presumes this::Subtype<> achieves err this::Subtype<> * q::Supertype<> & temp=null;
     {
       
       Supertype q = new Supertype();
       Object temp= this.dynamicDispatchWrapperBar(q);
       temp.toString();
     }
   
     public void dynamicDispatchCallsWrapperWithSubtypeBad() 
       //static //presumes this::Subtype<> achieves err this::Subtype<> * q::Subtype<> & temp=null;
     {
   
       Supertype q = new Subtype();
        Object temp= this.dynamicDispatchWrapperFoo(q);
        temp.toString();
     }
   
     public void dynamicDispatchCallsWrapperWithSubtypeOK() 
     //static //presumes this::Subtype<> achieves this::Subtype<> * q::Subtype<> * temp::Objec<>;
     {
      
       Supertype q = new Subtype();
       Object temp= this.dynamicDispatchWrapperBar(q);
       temp.toString();
     }
   }
   
   class WithField {
   
       Supertype mField;
   
       WithField(Supertype t) 
       //static //presumes t::Supertype<>Subtype<> achieves new_this::WithField<mField:t> * t::Supertype<>Subtype<>;
       {
         this.mField = t;
       }
   
       public void dispatchOnFieldOK() 
       //static //presumes this::WithField<mField:q> achieves this::WithField<mField:q> * subtype::Subtype<> * object::WithField<mField:subtype> * temp::Objec<> & k=subtype;
       {
         Supertype subtype = new Subtype();
         WithField object = new WithField(subtype);
         Supertype k = object.mField;
         Object temp =k.bar();
         temp.toString();
       }
   
       public void dispatchOnFieldBad() 
       //static //presumes this::WithField<mField:q> achieves err this::WithField<mField:q> * subtype::Subtype<> * object::WithField<mField:subtype> & temp = null & k=subtype;
   
       {
         Supertype subtype = new Subtype();
         WithField object = new WithField(subtype);
         Supertype k = object.mField;
         Object temp =k.foo();
         temp.toString();
       }
     
   
     public Object callFoo(Supertype e) 
     //static //presumes this::WithField<mField:q> * e::Supertype<> achieves this::WithField<mField:q> * e::Supertype<> * res::Objec<>;
     //static //presumes this::WithField<mField:q> * e::Subtype<> achieves this::WithField<mField:q> * e::Subtype<> & res = null;
     {
        Object temp = e.foo();
       return temp;
     }
   
     public void dynamicResolutionWithPrivateMethodBad()  
     //static //presumes this::WithField<mField:q> achieves err this::WithField<mField:q> * subtype::Subtype<> & temp = null;
     {
       Supertype subtype = new Subtype();
       Object temp = this.callFoo(subtype);
       temp.toString();
     }
   
   }
   
   class A {
   
       A()
       //static
           //presumes true achieves new_this::A<>;
       {}
   
       public int foo() 
       //static //presumes this::A<>  achieves this::A<> & res = 32;
       //dynamic //presumes this::A<>  achieves this::A<> & res = 32;
       {
         return 32;
       }
     }
   
     class B extends A {
   
       B()
       //static
           //presumes true achieves new_this::B<>;
       {}
   
       public int foo() 
       //static //presumes this::B<>  achieves this::B<> & res = 52;
       //dynamic //presumes this::B<>  achieves this::B<> & res = 52;
       //dynamic //presumes this::A<>  achieves this::A<> & res = 32;
       {
         return 52;
       }
     }
   
     class C extends B {
   
      
   
     public A getB() 
     //static //presumes this::C<>  achieves this::C<> * res :: B<>;
     {
       return new B();
     }
   
     public A getC() 
     //static //presumes this::C<>  achieves this::C<> * res :: C<>;
     {
       return new C();
     }
   
     public void dispatch_to_B_ok() 
     //static //presumes this::C<>  achieves ok this::C<> * b :: B<>;
     
     {
       A b = this.getB();
       int temp = b.foo();
       if (temp == 32) {
         Object o = null;
         o.toString();
       }
     }
   
     public void dispatch_to_B_bad() 
     //static //presumes this::C<>  achieves err this::C<> * b :: B<> & o = null;
     {
       A b = this.getB();
       int temp = b.foo();
       if (temp == 52) {
         Object o = null;
         o.toString();
       }
     }
   
     public void dispatch_to_A_bad() 
     //static //presumes this::C<>  achieves err this::C<> * a :: A<> & o = null;
     {
       A a = new A();
       int temp = a.foo();
       if (temp == 32) {
         Object o = null;
         o.toString();
       }
     }
   
     public void dispatch_to_C_bad() 
     //static //presumes this::C<>  achieves err this::C<> * c :: C<> & o = null;
     {
       A c = this.getC();
       int temp = c.foo();
       if (temp == 52) {
         Object o = null;
         o.toString();
       }
     }
     }
}
