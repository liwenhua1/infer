import java.io.IOException;

public class Cast {
    static class Supertype {

        public void test(Supertype a) {
         // Class b =  a.getClass();
         Subtype c = (Subtype) a;
        // Supertype d = get();
        Class b = c.getClass();
        }
            // public boolean foo1(Object obj){
            //     if (this == obj)
            //     {
            //         return true;
            //     }
            //     if (obj == null)
            //     {
            //         return false;
            //     }
            //     if (getClass() != obj.getClass())
            //     {
            //         if (obj instanceof Sub2)
            //         {
            //             // hitting this branch means that the warning on top of the class wasn't read
                        
            //         }
            //         return false;
            //     }
            //     final Supertype other = (Supertype) obj;
            //     return true;
            // }
         
           
            // public String foo() 
            //  //seems input parameter has no type, but constructed parameter has type
            //  //static //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
            //  //dynamic //presumes this::Supertype<> achieves this::Supertype<> * res::Objec<>;
            //  {
              
            //   Supertype q = get();
            //   Subtype b = (Subtype) q;
            //   if (b instanceof Sub2 ) {
            //      {
          
            //       Sub1 c = (Sub1) b;}}

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
            //  return "s";}

             public Supertype get() { return this;}


    //     protected Subtype convertCOSToPD( Supertype base ) throws IOException
    //     {
    //     Supertype destination = base;
    //     if( base instanceof Subtype )
    //     {
    //         //the destination is sometimes stored in the D dictionary
    //         //entry instead of being directly an array, so just dereference
    //         //it for now
    //         // destination = ((COSDictionary)base).getDictionaryObject( COSName.D );
    //     }
    //     return (Sub3)Subtype.create( destination );
    // }
   }
    static class Subtype extends Supertype { 
        
    // public static Subtype create( Supertype base ) throws IOException
    //     {
    //         Subtype retval = null;
    //         if( base == null )
    //         {
    //             return retval;
    //             //this is ok, just return null.
    //         }
           
                   
    //         else if( base instanceof Sub1 )
    //         {
    //             retval = new Sub1();
    //         }
    //         else if( base instanceof Sub2 )
    //         {
    //             retval = new Sub2();
    //         }
    //         else
    //         {
    //             throw new IOException( "Error: can't convert to Destination " + base );
    //         }
    //         return retval;
    //     }
    }
    static class Sub2 extends Subtype{
        // public Supertype test(Subtype a) {
        //     if (a == null) {return null;} return a;
        // }

        // public Object test2() {
        //     Object a = test(null);
        //     return a;
        // }
    }
    //static class Sub1 extends Subtype{}
    //static class Sub3 extends Subtype{}

    }
