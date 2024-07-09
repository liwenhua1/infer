public class Cast {
    static class Supertype {
            public boolean foo1(Object obj){
                if (this == obj)
                {
                    return true;
                }
                if (obj == null)
                {
                    return false;
                }
                if (getClass() != obj.getClass())
                {
                    if (obj instanceof Sub2)
                    {
                        // hitting this branch means that the warning on top of the class wasn't read
                        
                    }
                    return false;
                }
                final Supertype other = (Supertype) obj;
                return true;
            }
         
           
            public String foo() 
             //seems input parameter has no type, but constructed parameter has type
             //static //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
             //dynamic //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
             {
              
              Supertype q = get();
              Subtype b = (Subtype) q;
              if (b instanceof Sub2 ) {
                 {
          
                  Sub1 c = (Sub1) b;}}

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
    static class Sub2 extends Subtype{}
    static class Sub1 extends Subtype{}
{}
}
