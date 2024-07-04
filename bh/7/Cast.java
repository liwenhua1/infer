public class Cast {
    static class Supertype {
           
            public String foo(Object b) 
             //seems input parameter has no type, but constructed parameter has type
             //static //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
             //dynamic //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
             {
              
              Supertype q = (Supertype) b;
              if (b instanceof Subtype ) {
                 {
          
                  Sub c = (Sub) b;}}
                  
      
            //       if (b instanceof Subtype2) {
            //           Subtype z = (Subtype) b;
            //       }
            //       return null;}
            //   } else {
            //       Object t = b;
            //       Subtype c = (Subtype) t;
            //   return "null";}
             return "s";}
    }
    static class Subtype extends Supertype {}
    static class Sub extends Supertype{}
    static class Sub1 extends Sub{}
}
