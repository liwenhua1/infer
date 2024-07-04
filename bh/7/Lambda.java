import java.util.*; 
interface FuncInterface
{
    // An abstract function
    void abstractFun(Object x, FuncInterface2 y);

}

interface FuncInterface2
{
    // An abstract function
    Object abstractFun2(Object x);

}

interface FuncInterface3
{
    // An abstract function
    int abstractFun3(FuncInterface4 x);

}

interface FuncInterface4
{
    // An abstract function
    boolean abstractFun4(int x);

}

interface FuncInterface5
{
    // An abstract function
    void abstractFun5(Object x);

}

public class Lambda {
   

    public void test (FuncInterface b, Object a, FuncInterface2 y) {
        
    
    b.abstractFun(a,y);

    }

    public int test3 (Object a, FuncInterface3 b) {
      
        int i = b.abstractFun3(x->(x == 2));
        int j = b.abstractFun3(x->{a.toString();return (x == 30);});
        int k = b.abstractFun3(x->(x == 7));
        if (!(i == 12)) { return 1;} else {
            if (!(j == 5)) { return 2;} else {
                if (!(k == -2)) { return 3;} else
                {return 0;}
            }

        } 
       
    
    
        }

    // public void test2 () {
    //     FuncInterface3 x = (g) -> {if (g.abstractFun4(2)) {return 12;} else {if (g.abstractFun4(30)) {return 5;} else {return -2;}}}; 
    //     int q = test3(null, x);
    //     if (q == 0) {Object a = null; a.toString();};


    //     // Object a = null;
    //     // test((q,w) -> (w.abstractFun2(q)).toString(), a, x -> x);
    // }

    static public void foreach (ArrayList<Object> l, FuncInterface5 f){
        for (int counter = 0; counter < l.size(); counter++) { 		      
            f.abstractFun5(l.get(counter));; 		
        }   
    }

    public static void main(String[] args){
    ArrayList<Object> Numbers = new ArrayList<Object>(); 
  
        // Add Number to list 
        Numbers.add(null); 
        Numbers.add("32"); 
        Numbers.add("45"); 
        Numbers.add(null); 
      
        // while 
        //     (counter < Numbers.size()) { 		      
        //     System.out.println(Numbers.get(counter).toString()); 	
        //      counter++;	
        // }   
  
        // forEach method of ArrayList and 
        // print numbers 
       foreach(Numbers, (n) -> System.out.println(n.toString())); 
       Numbers.forEach((n) -> System.out.println(n.toString()));
}

   
}