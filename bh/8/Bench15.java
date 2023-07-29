

public class Bench15 {
    
      
      class A extends Object{
        int x;
    
     
    
      public int get()
      //static //presumes this::A<x:n> achieves this::A<x:n> & res = n;
      {
        int temp = this.x;
        return temp;
      }
    
    
      public Object match(int d)
      //static //presumes this::A<x:q2> & d = q2 achieves ok this::A<x:q2> & d = q2 & res = d;
      //static //presumes this::A<x:q2> & d != q2 achieves ok this::A<x:q2> & d != q2 & res = null;
      {
        int temp = this.x;
        if (temp == d) {return d;} else {return null;}
      }
    
    
    
        public void nullPointerExceptionFromNotKnowingThatThisIsNotNull() 
        //static //presumes this=null achieves err this=null ;
        //static //presumes this::A<x:v> achieves ok this::A<x:4> ;
        {
        if (this == null) {} else {}
        this.x = 4;
      }
    
        public int thisNotNullOk() 
        //static 
            //presumes this::A<x:v> achieves ok this::A<x:v> & res = 0 ;
        //static 
            //presumes this=null achieves err this=null & a=null ;
        
        {
          if (this == null) {
            A a = null;
            int z = a.x;
            return z;
          } else {
          
          return 0;}
        }
    
    
        public int thisNotNullBad() 
        //static 
            //presumes this::A<x:v> achieves err this::A<x:v> & a=null ;
        
        {
          if (this != null) {
            A a = null;
            int z = a.x;
            return z;
          }
         else {
          
          return 0;}
        }
    
        public void method() 
            //static 
                //presumes this::A<x:q> achieves ok this::A<x:q> ;
        {}
    
        
        
        public int nullPointerException() 
        //static 
                //presumes this::A<x:v> achieves err this::A<x:v> & a = null ;
        {
        A a = null;
        int z = a.x;
            return z;
      }
    
        public A canReturnNullObject(boolean o) 
        //static 
                //presumes this::A<x:v> & o=1 achieves ok this::A<x:v> * a::A<x:null> & res=a & o=1;
        //static 
                //presumes this::A<x:v> & o=0 achieves ok this::A<x:v> * a::A<x:null> & res=null & o=0;
        {
        A a = new A();
        if (o) {return a;}
        else {return null;}
      }
    
        public void expectNotNullObjectParameter(A a) 
        //static 
                //presumes this::A<x:v> & a=null achieves err this::A<x:v> & a=null;
        //static 
                //presumes this::A<x:v> * a::A<x:w> achieves ok this::A<x:v> * a::A<x:w>;
        {
        a.method();
      }
    
      public int nullPointerExceptionInterProc() 
      //static 
            //presumes this::A<x:v> achieves err this::A<x:v> * a::A<x:null> & b=null & o=1;
      {
        boolean i = false;
        A b = this.canReturnNullObject(i);
        int temp = b.x;
        return temp;
      }
      
      }
    
      class B {
        A a;
    
        B()
      //static
        //presumes true achieves new_this::B<a:null> ;
      {
    
      }
    
        public A get()
        //static //presumes this::B<a:r>  achieves ok this::B<a:r> & res = r;
        {
          A temp = this.a;
          return temp;
        }
      }
    
      class C {
        B b;
    
    
      C()
      //static
        //presumes true achieves new_this::C<b:null> ;
      {
    
      }
    
       public void method(A a) 
            //static 
                //presumes this::C<b:q1> * a::A<x:w1> achieves ok this::C<b:q1> * a::A<x:w1> ;
                //presumes this::C<b:q1> & a=null achieves err this::C<b:q1> & a=null ;
        {a.method();}
      
    
      public int FN_nullPointerExceptionWithAChainOfFields(C c) 
        //static //presumes this::C<b:v1> * c::C<b:w1> achieves err this::C<b:v1> * c::C<b:temp> * temp::B<a:null> ;
      {
        B temp = new B();
        c.b = temp;
        B temp2 = c.b;
        A temp3 = temp2.a;
        int temp4 = temp3.x;
        return temp4;
      }
    
        public void nullPointerExceptionWithNullObjectParameter() 
        //static 
                //presumes this::C<b:q1>  achieves err this::C<b:q1> & temp = null ;
        {
          A temp = null;
        this.method(temp);
      }
    
        public A id_generics(A o) 
        //static //presumes this::C<b:q1> * o::Object<>A<x:v> achieves ok this::C<b:q1> * res::Object<>A<x:v> ;
        {
        o.toString();
        return o;
       }
    
        public A frame(A g) 
        //static //presumes this::C<b:q1> * g::A<x:v> achieves ok this::C<b:q1> * res::A<x:v> ;
        {
          A temp = this.id_generics(g);
        return temp;
      }
    
        public void nullPointerExceptionUnlessFrameFails() 
        //static //presumes this::C<b:q1> achieves err this::C<b:q1> * temp::A<x:null> & a=temp & s = null ;
        {
        A s = null;
        A temp = new A();
        Object a = this.frame(temp);
        boolean y = a instanceof A;
        if (y ) {
          s.method();
        } else {}
      }
      }
    
      class D {
        int x;
      
      public int preconditionCheckStateTest(D d) 
      //static //presumes this::D<x:q1> * d::D<x:q2> achieves ok this::D<x:q1> * d::D<x:q2> & res=q2;
      { 
        int temp = d.x;
        return temp;
      }
    
      public void genericMethodSomewhereCheckingForNull(Object s) 
      //static //presumes this::D<x:q1> * s::Object<>A<x:v> achieves ok this::D<x:q1> * s::Object<>A<x:v>;
      {
        if (s == null) {} else {}
      }
    
      public void noNullPointerExceptionAfterSkipFunction() 
      //static //presumes this::D<x:q1> achieves ok this::D<x:q1> * t::A<x:null> * a::A<x:null> *s1::A<x:null> & s1 = a;
      {
        A t = new A();
        boolean temp = true;
        Object s1 = t.canReturnNullObject(temp);
        this.genericMethodSomewhereCheckingForNull(s1);
        s1.toString();
      }
    
      public A hfoo(B h) 
      //static //presumes this::D<x:q1> * h::B<a:i> * i::A<x:p> achieves ok this::D<x:q1> * h::B<a:i> * i::A<x:p>  & res = i & i = temp;
      {
        A temp = h.get();
        temp.toString();
        return temp;
      }
    
      public int hashNPE(A h, int k) 
      //static //presumes this::D<x:q1> * h::A<x:i> & k = i achieves ok this::D<x:q1> * h::A<x:i> & k = i & res = k + 1;
      //static //presumes this::D<x:q1> * h::A<x:i> & k != i achieves err this::D<x:q1> * h::A<x:i> & k != i;
      {
        Object temp = h.match(k);
        int temp2 = ((int )temp) + 1;
        return temp2;
      }
    
       public int NPEhashmapProtectedByContainsKey(A h, int k) 
       //static //presumes this::D<x:q1> * h::A<x:i> & k = i achieves ok this::D<x:q1> * h::A<x:i> & k = i & res = k + 1;
       //static //presumes this::D<x:q1> * h::A<x:i> & k != i achieves ok this::D<x:q1> * h::A<x:i> & k != i & res = 0;
       {
        int temp = h.x;
        if (temp != k) {
          return 0;
        } else {
        int temp2 = this.hashNPE(h, k);
        return temp2;
      }
      }
    
      }
      
      class Nullable {
      Object mFld;
    
      public void FN_nullableFieldNPE() 
      //static //presumes this::Nullable<mFld:null> achieves err this::Nullable<mFld:null> & temp = null;
      //static //presumes this::Nullable<mFld:v> * v::Object<> achieves ok this::Nullable<mFld:v> * v::Object<> * temp::Object<> & temp = v;
      {
        Object temp = this.mFld;
        temp.toString();
      }
    
      public void guardedNullableFieldDeref() 
      //static //presumes this::Nullable<mFld:null> achieves ok this::Nullable<mFld:null> & temp = null;
      //static //presumes this::Nullable<mFld:v> * v::Object<> achieves ok this::Nullable<mFld:v> * v::Object<> * temp::Object<> & temp = v;
    
      {
        Object temp = this.mFld;
        if (temp != null) {temp.toString();} else {};
      }
    
      public void allocNullableFieldDeref() 
      //static //presumes this::Nullable<mFld:v> achieves ok this::Nullable<mFld:temp> * temp::Object<> * temp2::Object<> & temp2 = temp;
      //static //presumes this::Nullable<mFld:v> * v::Object<> achieves ok this::Nullable<mFld:temp> * temp::Object<> * temp2::Object<> * v::Object<>& temp2 = temp;
    
      {
        Object temp = new Object();
        this.mFld = temp;
        Object temp2 = this.mFld;
        temp2.toString();
      }
    
      public void nullableParamNPE() 
      //static //presumes this::Nullable<mFld:v> * v::Object<> achieves ok this::Nullable<mFld:v> * v::Object<> & temp = v ;
      {
        Object temp = this.mFld;
        temp.toString();
      }
    
      public void guardedNullableParamDeref( Object param) 
      //static //presumes this::Nullable<mFld:v> * param::Object<> achieves ok this::Nullable<mFld:v> * param::Object<> ;
       //static //presumes this::Nullable<mFld:v> & param = null achieves ok this::Nullable<mFld:v> & param = null  ;
    
      {
        if (param != null) {param.toString();}
      }
    
      public void allocNullableParamDeref(Object param) 
      //static //presumes this::Nullable<mFld:v> * param::Object<> achieves ok this::Nullable<mFld:v> * param::Object<> ;
      {
        param = new Object();
        param.toString();
      }
    
      public void nullableParamReassign1(Object o) 
      //static //presumes this::Nullable<mFld:v> & o = null achieves ok this::Nullable<mFld:v> * o::Object<>;
      {
        if (o == null) {
          o = new Object();
        }
        o.toString();
      }
    
      public void nullableParamReassign2(Object o, Object okObj) 
      //static //presumes this::Nullable<mFld:v> * okObj::Object<> & o = null achieves ok this::Nullable<mFld:v> * okObj::Object<> & o = okObj;
      {
        if (o == null) {
          o = okObj;
        }
        o.toString();
      }
    
       public void nullableFieldReassign3(Object o, Object param) 
       //static //presumes this::Nullable<mFld:v> * o::Object<> * param::Object<> achieves ok this::Nullable<mFld:v> * o::Object<> & o = param ;
       {
        o = param;
        o.toString();
      }
    
        public Object nullableGetter(Object o) 
        //static //presumes this::Nullable<mFld:v> * o::Object<> achieves ok this::Nullable<mFld:v> * o::Object<> & res = o;
        //static //presumes this::Nullable<mFld:v> & o = null achieves ok this::Nullable<mFld:v> & o = null & res = o;
        {
        return o;
      }
    
       public void FN_derefNullableGetter(Object p) 
        //static //presumes this::Nullable<mFld:v> * p::Object<> achieves ok this::Nullable<mFld:v> * p::Object<> & q = p;
        //static //presumes this::Nullable<mFld:v> & p = null achieves err this::Nullable<mFld:v> & p = null & q = p;
       {
        Object q = this.nullableGetter(p);
        q.toString();
      }
    
        public Object nullableRet(boolean b) 
          //static //presumes this::Nullable<mFld:v> & b = 1 achieves ok this::Nullable<mFld:v> & b = 1 & res = null;
          //static //presumes this::Nullable<mFld:v> & b = 0 achieves ok this::Nullable<mFld:v> * res::Object<> & b = 0 ;
        {
        if (b) {
          return null;
        } else {
        return new Object();}
      }
    
      public void derefNullableRet(boolean z) 
        //static //presumes this::Nullable<mFld:v> & z = 0 achieves ok this::Nullable<mFld:v> * ret::Object<> & z = 0;
        //static //presumes this::Nullable<mFld:v> & z = 1 achieves err this::Nullable<mFld:v> & ret = null & z = 1;
      {
        Object ret = this.nullableRet(z);
        ret.toString();
      }
    
      public void derefNullableRetOK(boolean z) 
        //static //presumes this::Nullable<mFld:v> & z = 0 achieves ok this::Nullable<mFld:v> * ret::Object<> & z = 0;
        //static //presumes this::Nullable<mFld:v> & z = 1 achieves ok this::Nullable<mFld:v> & ret = null & z = 1;
      {
        Object ret = this.nullableRet(z);
        if (ret != null) {
          ret.toString();
        }
      }
    
      public void derefUndefNullableRet(Object undefNullableRet) 
      //static //presumes this::Nullable<mFld:v> * undefNullableRet::Object<>  achieves ok this::Nullable<mFld:v> * undefNullableRet::Object<> & ret = undefNullableRet;
      //static //presumes this::Nullable<mFld:v> & undefNullableRet = null achieves err this::Nullable<mFld:v> & undefNullableRet = null & ret = undefNullableRet;
      {
        Object ret = undefNullableRet;
        ret.toString();
      }
    
      public void derefUndefNullableRetOK(Object undefNullableRet) 
      //static //presumes this::Nullable<mFld:v> * undefNullableRet::Object<>  achieves ok this::Nullable<mFld:v> * undefNullableRet::Object<> & ret = undefNullableRet;
      //static //presumes this::Nullable<mFld:v> & undefNullableRet = null achieves ok this::Nullable<mFld:v> & undefNullableRet = null & ret = undefNullableRet;
      {
        Object ret = undefNullableRet;
        if (ret != null) {
          ret.toString();
        }
      }
    
      public void assumeUndefNullableIdempotentOk(Object undefNullableRet) 
      //static //presumes this::Nullable<mFld:v> * undefNullableRet::Object<>  achieves ok this::Nullable<mFld:v> * undefNullableRet::Object<>;
      //static //presumes this::Nullable<mFld:v> & undefNullableRet = null achieves ok this::Nullable<mFld:v> & undefNullableRet = null;
      {
        if (undefNullableRet != null) {
          undefNullableRet.toString();
        }
      }
    
      public Object undefNullableWrapper(Object undefNullableRet) 
      //static //presumes this::Nullable<mFld:v> * undefNullableRet::Object<>  achieves ok this::Nullable<mFld:v> * undefNullableRet::Object<> & res = undefNullableRet;
      //static //presumes this::Nullable<mFld:v> & undefNullableRet = null achieves ok this::Nullable<mFld:v> & undefNullableRet = null & res = undefNullableRet;
      {
        return undefNullableRet;
      }
    
      public void derefUndefNullableRetWrapper(Object undef) 
      //static //presumes this::Nullable<mFld:v> * undef::Object<>  achieves ok this::Nullable<mFld:v> * undef::Object<> & q = undef;
      //static //presumes this::Nullable<mFld:v> & undef = null achieves err this::Nullable<mFld:v> & undef = null & q = undef;
      {
        Object q = this.undefNullableWrapper(undef);
        q.toString();
      }
    
      public int returnsThreeOnlyIfRetNotNull(Object obj) 
      //static //presumes this::Nullable<mFld:v> * obj::Object<>  achieves ok this::Nullable<mFld:v> * obj::Object<> & res = 3;
      //static //presumes this::Nullable<mFld:v> & obj = null achieves ok this::Nullable<mFld:v> & obj = null & res = 2;
      {
        if (obj == null) {
          return 2;
        } else {
        return 3;}
      }
    
      public void testNullablePrecision(Object undefNullableRet) 
      //static //presumes this::Nullable<mFld:v> * undefNullableRet::Object<>  achieves ok this::Nullable<mFld:v> * undefNullableRet::Object<> & ret = undefNullableRet;
      //static //presumes this::Nullable<mFld:v> & undefNullableRet = null achieves ok this::Nullable<mFld:v> & undefNullableRet = null & ret = undefNullableRet;
      {
        Object ret = undefNullableRet;
        int temp = this.returnsThreeOnlyIfRetNotNull(ret);
        if ( temp == 3) {
          ret.toString(); 
        }
      }
    
      }
    
    class Bl {
      boolean test1;
    
      boolean test2;
    
      public Object getObj() 
      //static //presumes this::Bl<test1:1,test2:v>  achieves ok this::Bl<test1:1,test2:v> * res::Object<>;
      //static //presumes this::Bl<test1:0,test2:v>  achieves ok this::Bl<test1:0,test2:v> & res=null;
      {
        boolean temp = this.test1;
        if (temp) {
          return new Object();
        } else {
          return null;
        }
      }
    
      public Boolean getBool() 
      //static //presumes this::Bl<test1:v1,test2:1>  achieves ok this::Bl<test1:v1,test2:1> & res=1;
      //static //presumes this::Bl<test1:v1,test2:0>  achieves ok this::Bl<test1:v1,test2:0> & res=null;
      {
        boolean temp = this.test2;
        if (temp) {
          return true;
        } else {
          return null;
        }
      }
    
      public void derefGetterAfterCheckShouldNotCauseNPE() 
      //static //presumes this::Bl<test1:1,test2:v1>  achieves ok this::Bl<test1:1,test2:v1> * temp::Object<>;
      //static //presumes this::Bl<test1:0,test2:v1>  achieves ok this::Bl<test1:0,test2:v1> & temp = null;
      {
        Object temp = this.getObj();
        if (temp != null ) {
          temp.toString();
        }
      }
    
      public void derefBoxedGetterAfterCheckShouldNotCauseNPE() 
      //static //presumes this::Bl<test1:v1,test2:0>  achieves ok this::Bl<test1:v1,test2:0> ; 
      //static //presumes this::Bl<test1:v1,test2:1>  achieves ok this::Bl<test1:v1,test2:1> ;
      {
        Boolean b1 = this.getBool();
         if (b1 != null) {
        Boolean b2 = this.getBool();
        b2 = b2 && b1;
        
        } else {Boolean b2 = false;}
      }
      
       public void badCheckShouldCauseNPE_latent() 
       //static //presumes this::Bl<test1:v1,test2:1>  achieves err this::Bl<test1:0,test2:1> & temp = null; 
       //static //presumes this::Bl<test1:1,test2:1>  achieves ok this::Bl<test1:1,test2:1> * temp::Object<> ; 
       {
        Boolean b1 = this.getBool();
        if (b1 != null) {
          Object temp = this.getObj();
          temp.toString();
        }
      }
    
    }
    
      class L {
        L next;
    
        public Object returnsNullAfterLoopOnList() 
        //static //presumes this::L<next:l>  achieves ok this::L<next:l> & res = null; 
        {
            return null;
      }
    
       public void dereferenceAfterLoopOnList() 
        //static //presumes this::L<next:l>  achieves err this::L<next:l> & obj = null; 
    
       {
        Object obj = this.returnsNullAfterLoopOnList();
        obj.toString();
      }
      }
    
      class E {
    
        Object nl;
    
      public Object getObject() 
      //static //presumes this::E<nl:l>  achieves ok this::E<nl:l> & res = null; 
      {
        return null;
      }
    
      public void incr_deref(A z) 
      //static //presumes this::E<nl:l> * z::A<x:v>  achieves ok this::E<nl:l> * z::A<x:v+1> ; 
      {
        int temp = z.x;
        temp = temp + 1;
        z.x = temp;
      }
    
      public void call_incr_deref_with_alias_bad() 
      //static //presumes this::E<nl:l>  achieves err this::E<nl:l> & a = null ; 
      {
        A a = new A();
        a.x = 0;
        this.incr_deref(a);
        this.incr_deref(a);
        int temp = a.x;
        if (temp == 2) {
          a = null;
        }
        a.x = 0;
      }
    
      public void call_incr_deref_with_alias_Ok() 
      //static //presumes this::E<nl:l>  achieves ok this::E<nl:l> * a::A<x:0> ; 
      {
        A a = new A();
        a.x = 0;
        this.incr_deref(a);
        this.incr_deref(a);
        int temp = a.x;
        if (temp != 2) {
          a = null;
        }
        a.x = 0;
      }
    
       public void call_incr_deref2_Ok() 
       //static //presumes this::E<nl:l>  achieves ok this::E<nl:l> * a::A<x:2> * a1::A<x:0> * a2::A<x:1> ; 
       {
        A a = new A();
        A a1 = new A();
        A a2 = new A();
        a.x = 0;
        a1.x = 0;
        a2.x = 0;
        this.incr_deref(a);
        this.incr_deref(a);
        this.incr_deref(a1);
        this.incr_deref(a2);
        int temp = a.x;
        int temp1 = a1.x;
        int temp2 = a2.x;
    
        
        if (temp1 != 1) { a1 = null;
        } else {
          if (temp2 != 1) {a1 = null;} else {
            if (temp != 2) {a1 = null;} else {
            }
    
          }
        }
        a1.x = 0;
      }
    
       public void call_incr_deref2_bad() 
       //static //presumes this::E<nl:l>  achieves err this::E<nl:l> * a::A<x:2> * a2::A<x:1> & a1 = null ; 
       {
        A a = new A();
        A a1 = new A();
        A a2 = new A();
        a.x = 0;
        a1.x = 0;
        a2.x = 0;
        this.incr_deref(a);
        this.incr_deref(a);
        this.incr_deref(a1);
        this.incr_deref(a2);
        int temp = a.x;
        int temp1 = a1.x;
        int temp2 = a2.x;
        if (temp1 == 1) 
          {if (temp2 == 1) 
            {if (temp == 2) 
              {a1 = null;}}}
    
        a1.x = 0;
      }
    
      public void incr_deref3(A aa, A ab, A ac) 
      //static //presumes this::E<nl:l> * aa::A<x:v> * ab::A<x:w> * ac::A<x:m>  achieves ok this::E<nl:l> * aa::A<x:v+1> * ab::A<x:w> * ac::A<x:m> ; 
      //static //presumes this::E<nl:l> * aa::A<x:null> * ab::A<x:w> * ac::A<x:m>  achieves err this::E<nl:l> * aa::A<x:null> * ab::A<x:w> * ac::A<x:m> ;
      //static //presumes this::E<nl:l> *  ab::A<x:w> * ac::A<x:m> & aa = null achieves err this::E<nl:l> *  ab::A<x:w> * ac::A<x:m> & aa = null ; 
    
      {
        int temp = aa.x;
        temp = temp + 1;
        aa.x = temp;
      }
    
      public void call_incr_deref3_bad() 
      //static //presumes this::E<nl:l> achieves err this::E<nl:l> * a1::A<x:null> * a2::A<x:null> * a3::A<x:null> ;
      {
        A a1 = new A();
        A a2 = new A();
        A a3 = new A();
        this.incr_deref3(a1, a2, a3);
      }
    
       public void test_capture_alias_bad() 
       //static //presumes this::E<nl:l>  achieves err this::E<nl:l> * a::A<x:2> & b = null ; 
       {
        A a = new A();
        a.x = 0;
        this.incr_deref(a);
        this.incr_deref(a);
        A b = a;
        int temp = a.x;
        if (temp == 2) {
          b = null;
        }
        b.x = 0;
      }
    
      public void test_capture_alias_bad2() 
       //static //presumes this::E<nl:l>  achieves err this::E<nl:l> * a1::A<x:2> * a2::A<x:null> * a3::A<x:null> & b = null ; 
       {
        A a1 = new A();
        A a2 = new A();
        A a3 = new A();
        a1.x = 0;
        this.incr_deref(a1);
        this.incr_deref3(a1,a2,a3);
        A b = a1;
        int temp = b.x;
        if (temp == 2) {
          b = null;
        }
        b.x = 0;
      }
    
      
      public void test_capture_alias_good_FP() 
      //static //presumes this::E<nl:l>  achieves ok this::E<nl:l> * a::A<x:0> & a = b ; 
      {
        A a = new A();
        a.x = 0;
        this.incr_deref(a);
        this.incr_deref(a);
        A b = a;
        int temp = a.x;
        if (temp != 2) {
          b = null;
        }
        b.x = 0;
      }
      }
}
