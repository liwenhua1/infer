public class Cast {
    static class Supertype {

         
           
            public String foo() 
             //seems input parameter has no type, but constructed parameter has type
             //static //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
             //dynamic //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
             {
              
              Supertype q = get();
              Subtype b = (Subtype) q;
              if (b instanceof Subtype ) {
                 {
          
                  Sub c = (Sub) b;}}

            //   Object a = new Object();
            //   Supertype o = (Supertype) a;
                  
      
            //       if (b instanceof Subtype2) {
            //           Subtype z = (Subtype) b;
            //       }
            //       return null;}
            //   } else {
            //       Object t = b;
            //       Subtype c = (Subtype) t;
            //   return "null";}
             return "s";}

             public Supertype get() { return this;}
    }
    static class Subtype extends Supertype {}
    static class Sub extends Subtype{}
    static class Sub1 extends Sub{}
}
