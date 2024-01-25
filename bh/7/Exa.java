
class C {}
class A {
    public C f;
    public boolean tag;
    public void set(C c){
        if (this.tag) {this.f = c;} 
    } 
}

class B extends A {
   
    public void set(C c){
        if (this.tag) {this.f = c;} 
        else {this.f = null;}

    } 
}

public class Exa {
   

    public void bug(A a, C c){

        if (a instanceof B) { 
            a.tag = false;
            } else {a.tag = true;}
        a.set(c);
        
    }

    public void bug2(A a){
        C c = null;
        bug(a,c);
        a.f.toString();
    }
}