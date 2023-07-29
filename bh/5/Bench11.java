
public class Bench11 {
    class CategoryAxis{
        public void setPlot(CategoryPlot t){}
        public void configure(){}
        public void addChangeListener(CategoryPlot t){}
    }
    
    class CategoryPlot{
        CategoryAxis pre;   
        CategoryAxis ax;
    
        public void setDomainAxis2(int index, CategoryAxis axis, int notify) 
        //static  //presumes this::CategoryPlot<pre:ppp,ax:iii> & index = u & notify = 1 & axis = null achieves this::CategoryPlot<pre:iii,ax:axis> & index = u & notify = 1 & axis = null;
        //dynamic //presumes this::CategoryPlot<pre:ppp,ax:iii> & index = u & notify = 1 & axis = null achieves this::CategoryPlot<pre:iii,ax:axis> & index = u & notify = 1 & axis = null;
    
        {
            CategoryAxis existing = this.ax;
            if (existing != null) {
                this.pre = existing;
            }
            if (axis != null) {
                axis.setPlot(this);
            }
            if (axis != null) {
                axis.configure();
                axis.addChangeListener(this);
            }
            if (notify == 1) {
                if (index > 0) {
                this.ax = axis;}
            }
        }
    
        public void setDomainAxis1(int ind, CategoryAxis axi) 
        //static  //presumes this::CategoryPlot<pre:pp,ax:ii> & ind = y & axi = null achieves this::CategoryPlot<pre:ii,ax:null> & ind = y & axi = null;
        //dynamic //presumes this::CategoryPlot<pre:pp,ax:ii> & ind = y & axi = null achieves this::CategoryPlot<pre:ii,ax:null> & ind = y & axi = null;
        {   
            int temp = 1;
            this.setDomainAxis2(ind, axi, temp);
        }
    
        public void setDomainAxis(CategoryAxis a) 
        //static  //presumes this::CategoryPlot<pre:p,ax:i> & a = null achieves this::CategoryPlot<pre:i,ax:a> & a = null;
        //dynamic //presumes this::CategoryPlot<pre:p,ax:i> & a = null achieves this::CategoryPlot<pre:i,ax:a> & a = null;
        {   
            int temp1 = 0;
            this.setDomainAxis1(temp1, a);
        }
    
        public void setRangeAxis2(int index, CategoryAxis axis, int notify) 
        //static  //presumes this::CategoryPlot<pre:ppp,ax:iii> & index = u & notify = 1 & axis = null achieves this::CategoryPlot<pre:iii,ax:axis> & index = u & notify = 1 & axis = null;
        //dynamic //presumes this::CategoryPlot<pre:ppp,ax:iii> & index = u & notify = 1 & axis = null achieves this::CategoryPlot<pre:iii,ax:axis> & index = u & notify = 1 & axis = null;
    
        {
            CategoryAxis existing = this.ax;
            if (existing != null) {
                this.pre = existing;
            }
            if (axis != null) {
                axis.setPlot(this);
            }
            if (axis != null) {
                axis.configure();
                axis.addChangeListener(this);
            }
            if (notify == 1) {
                if (index > 0) {
                this.ax = axis;}
            }
        }
    
        public void setRangeAxis1(int ind, CategoryAxis axi) 
        //static  //presumes this::CategoryPlot<pre:pp,ax:ii> & ind = y & axi = null achieves this::CategoryPlot<pre:ii,ax:null> & ind = y & axi = null;
        //dynamic //presumes this::CategoryPlot<pre:pp,ax:ii> & ind = y & axi = null achieves this::CategoryPlot<pre:ii,ax:null> & ind = y & axi = null;
        {   
            int temp = 1;
            this.setRangeAxis2(ind, axi, temp);
        }
    
        public void setRangeAxis(CategoryAxis a) 
        //static  //presumes this::CategoryPlot<pre:p,ax:i> & a = null achieves this::CategoryPlot<pre:i,ax:a> & a = null;
        //dynamic //presumes this::CategoryPlot<pre:p,ax:i> & a = null achieves this::CategoryPlot<pre:i,ax:a> & a = null;
        {   
            int temp1 = 0;
            this.setRangeAxis1(temp1, a);
        }
    
        
    }
    
    class CombinedRangeCategoryPlot extends CategoryPlot {
    
        public void setDomainAxis2(int index, CategoryAxis axis, int notify) 
         //static  //presumes this::CombinedRangeCategoryPlot<pre:ppp,ax:iii> & index = u & notify = 1 & axis = null achieves this::CombinedRangeCategoryPlot<pre:iii,ax:axis> & index = u & notify = 1 & axis = null;
         //dynamic //presumes this::CategoryPlot<pre:ppp,ax:iii>CombinedRangeCategoryPlot<> & index = u & notify = 1 & axis = null achieves this::CategoryPlot<pre:iii,ax:axis>CombinedRangeCategoryPlot<> & index = u & notify = 1 & axis = null;
        {
            
        }
    
        public void setDomainAxis1(int ind, CategoryAxis axi) 
        //static  //presumes this::CombinedRangeCategoryPlot<pre:pp,ax:ii> & ind = y & axi = null achieves this::CombinedRangeCategoryPlot<pre:ii,ax:null> & ind = y & axi = null;
        //dynamic //presumes this::CategoryPlot<pre:pp,ax:ii>CombinedRangeCategoryPlot<> & ind = y & axi = null achieves this::CategoryPlot<pre:ii,ax:null>CombinedRangeCategoryPlot<> & ind = y & axi = null;
        {   
         
        }
    
        public void setDomainAxis(CategoryAxis a) 
        //static  //presumes this::CombinedRangeCategoryPlot<pre:p,ax:i> & a = null achieves this::CombinedRangeCategoryPlot<pre:i,ax:a> & a = null;
        //dynamic //presumes this::CategoryPlot<pre:p,ax:i>CombinedRangeCategoryPlot<> & a = null achieves this::CategoryPlot<pre:i,ax:a>CombinedRangeCategoryPlot<> & a = null;
        {   
            
        }
    
        public void add(CategoryPlot subplot, int weight) 
        //static  //presumes subplot::CategoryPlot<pre:e,ax:u> & weight > 0 achieves subplot::CategoryPlot<pre:u,ax:null> & weight > 0;
        //static  //presumes subplot::CategoryPlot<pre:e,ax:u> & weight > 0 achieves err subplot::CategoryPlot<pre:u,ax:null> & weight > 0;
    
        {
            
            if (weight > 0) {
           
            subplot.setRangeAxis(null);
                  
        }
        }
    }
    
    class CombinedDomainCategoryPlot extends CategoryPlot {
        public void setDomainAxis2(int index, CategoryAxis axis, int notify) 
         //static  //presumes this::CombinedDomainCategoryPlot<pre:ppp,ax:iii> & index = u & notify = 1 & axis = null achieves this::CombinedDomainCategoryPlot<pre:iii,ax:axis> & index = u & notify = 1 & axis = null;
         //dynamic //presumes this::CategoryPlot<pre:ppp,ax:iii>CombinedDomainCategoryPlot<> & index = u & notify = 1 & axis = null achieves this::CategoryPlot<pre:iii,ax:axis>CombinedDomainCategoryPlot<> & index = u & notify = 1 & axis = null;
        {
            
        }
    
        public void setDomainAxis1(int ind, CategoryAxis axi) 
        //static  //presumes this::CombinedDomainCategoryPlot<pre:pp,ax:ii> & ind = y & axi = null achieves this::CombinedDomainCategoryPlot<pre:ii,ax:null> & ind = y & axi = null;
        //dynamic //presumes this::CategoryPlot<pre:pp,ax:ii>CombinedDomainCategoryPlot<> & ind = y & axi = null achieves this::CategoryPlot<pre:ii,ax:null>CombinedDomainCategoryPlot<> & ind = y & axi = null;
        {   
         
        }
    
        public void setDomainAxis(CategoryAxis a) 
        //static  //presumes this::CombinedDomainCategoryPlot<pre:p,ax:i> & a = null achieves this::CombinedDomainCategoryPlot<pre:i,ax:a> & a = null;
        //dynamic //presumes this::CategoryPlot<pre:p,ax:i>CombinedDomainCategoryPlot<> & a = null achieves this::CategoryPlot<pre:i,ax:a>CombinedDomainCategoryPlot<> & a = null;
        {   
            
        }
    
        public void add(CategoryPlot subplot, int weight) 
        //static  //presumes subplot::CategoryPlot<pre:e,ax:u> & weight > 0 achieves subplot::CategoryPlot<pre:u,ax:null> & weight > 0;
        //static  //presumes subplot::CategoryPlot<pre:e,ax:u> & weight > 0 achieves err subplot::CategoryPlot<pre:u,ax:null> & weight > 0;
    
        {
            
            if (weight > 0) {
           
            subplot.setDomainAxis(null);
                  
        }
        }
    
    }
    
    class CombinedCategoryPlot extends CategoryPlot {
        public void setDomainAxis2(int index, CategoryAxis axis, int notify) 
         //static  //presumes this::CombinedCategoryPlot<pre:ppp,ax:iii> & index = u & notify = 1 & axis = null achieves this::CombinedCategoryPlot<pre:axis,ax:ppp> & index = u & notify = 1 & axis = null;
         //dynamic //presumes this::CategoryPlot<pre:ppp,ax:iii> & index = u & notify = 1 & axis = null achieves this::CategoryPlot<pre:iii,ax:axis> & index = u & notify = 1 & axis = null;
         //dynamic //presumes this::CombinedCategoryPlot<pre:ppp,ax:iii> & index = u & notify = 1 & axis = null achieves this::CombinedCategoryPlot<pre:axis,ax:ppp> & index = u & notify = 1 & axis = null;
        {
            CategoryAxis existing = this.pre;
            if (existing != null) {
                this.ax = existing;
            }
            if (axis != null) {
                axis.setPlot(this);
            }
            if (axis != null) {
                axis.configure();
                axis.addChangeListener(this);
            }
            if (notify == 1) {
                if (index > 0) {
                this.pre = axis;}
            }
            
        }
    
        public void setDomainAxis1(int ind, CategoryAxis axi) 
        //static  //presumes this::CombinedCategoryPlot<pre:pp,ax:ii> & ind = y & axi = null achieves this::CombinedCategoryPlot<pre:axi,ax:pp> & ind = y & axi = null;
        //dynamic //presumes this::CombinedCategoryPlot<pre:pp,ax:ii> & ind = y & axi = null achieves this::CombinedCategoryPlot<pre:axi,ax:pp> & ind = y & axi = null;
        //dynamic //presumes this::CategoryPlot<pre:pp,ax:ii> & ind = y & axi = null achieves this::CategoryPlot<pre:ii,ax:null> & ind = y & axi = null;
        {   
            int temp = 1;
            this.setDomainAxis2(ind, axi, temp);
        }
    
        public void setDomainAxis(CategoryAxis a) 
        //static  //presumes this::CombinedCategoryPlot<pre:p,ax:i> & a = null achieves this::CombinedCategoryPlot<pre:a,ax:p> & a = null;
        //dynamic //presumes this::CombinedCategoryPlot<pre:p,ax:i> & a = null achieves this::CombinedCategoryPlot<pre:a,ax:p>& a = null;
        //dynamic //presumes this::CategoryPlot<pre:p,ax:i> & a = null achieves this::CategoryPlot<pre:i,ax:a> & a = null;
    
        {   
            int temp1 = 0;
            this.setDomainAxis1(temp1, a);
        }
    
        public void setRangeAxis2(int index, CategoryAxis axis, int notify) 
         //static  //presumes this::CombinedCategoryPlot<pre:ppp,ax:iii> & index = u & notify = 1 & axis = null achieves this::CombinedCategoryPlot<pre:axis,ax:axis> & index = u & notify = 1 & axis = null;
         //dynamic //presumes this::CombinedCategoryPlot<pre:ppp,ax:iii> & index = u & notify = 1 & axis = null achieves this::CombinedCategoryPlot<pre:axis,ax:axis> & index = u & notify = 1 & axis = null;
         //dynamic //presumes this::CategoryPlot<pre:ppp,ax:iii> & index = u & notify = 1 & axis = null achieves this::CategoryPlot<pre:iii,ax:axis> & index = u & notify = 1 & axis = null;
    
        {
            CategoryAxis existing = this.ax;
            if (existing != null) {
                this.ax = axis;
            }
            if (axis != null) {
                axis.setPlot(this);
            }
            if (axis != null) {
                axis.configure();
                axis.addChangeListener(this);
            }
            if (notify ==1) {
                if (index > 0) {
                this.pre = axis;}
            }
        }
    
        public void setRangeAxis1(int ind, CategoryAxis axi) 
        //static  //presumes this::CombinedCategoryPlot<pre:pp,ax:ii> & ind = y & axi = null achieves this::CombinedCategoryPlot<pre:axi,ax:null> & ind = y & axi = null;
        //dynamic //presumes this::CombinedCategoryPlot<pre:pp,ax:ii>& ind = y & axi = null achieves this::CombinedCategoryPlot<pre:axi,ax:null> & ind = y & axi = null;
        //dynamic //presumes this::CategoryPlot<pre:pp,ax:ii> & ind = y & axi = null achieves this::CategoryPlot<pre:ii,ax:null> & ind = y & axi = null;
    
        {   
            int temp = 1;
            this.setRangeAxis2(ind, axi, temp);
         
        }
    
        public void setRangeAxis(CategoryAxis a) 
        //static  //presumes this::CombinedCategoryPlot<pre:pd,ax:id> & a = null achieves this::CombinedCategoryPlot<pre:null,ax:null> ;
        //dynamic //presumes this::CombinedCategoryPlot<pre:p,ax:i> & a = null achieves this::CombinedCategoryPlot<pre:a,ax:a>& a = null;
        //dynamic //presumes this::CategoryPlot<pre:p,ax:i> & a = null achieves this::CategoryPlot<pre:i,ax:a> & a = null;
    
        {   
            int temp1 = 0;
            this.setRangeAxis1(temp1, a);
        }
    
        public void add(CategoryPlot subplot, int weight) 
        //static  //presumes subplot::CategoryPlot<pre:e,ax:u> & weight > 0 achieves subplot::CategoryPlot<pre:null,ax:null> & weight > 0;
        //static  //presumes subplot::CategoryPlot<pre:e,ax:u> & weight > 0 achieves err subplot::CategoryPlot<pre:null,ax:null> & weight > 0;
    
        {
            
            if (weight > 0) {
           
            subplot.setDomainAxis(null);
            subplot.setDomainAxis(null);
                  
        }
        }
    
    }
    
    class Test {
    
        public void test1 (CategoryPlot t1) 
        //static  //presumes this::Test<> * t1::CategoryPlot<pre:p,ax:i>CombinedCategoryPlot<> achieves this::Test<> * t1::CombinedCategoryPlot<pre:null,ax:null>;
        //static  //presumes this::Test<> * t1::CategoryPlot<pre:p,ax:i>CombinedCategoryPlot<> achieves this::Test<> * t1::CategoryPlot<pre:i,ax:null> ;
    
        {
            CategoryAxis l = null;
            t1.setRangeAxis(l);
        }
    
        public void test2 (CategoryPlot t1) 
        //static  //presumes this::Test<> * t1::CategoryPlot<pre:p,ax:i>CombinedCategoryPlot<> achieves this::Test<> * t1::CombinedCategoryPlot<pre:null,ax:null>;
        //static  //presumes this::Test<> * t1::CategoryPlot<pre:p,ax:i>CombinedCategoryPlot<> achieves this::Test<> * t1::CategoryPlot<pre:i,ax:null> ;
        {
            boolean k = t1 instanceof CombinedCategoryPlot;
            if (k) {
               
                t1.setRangeAxis(null);
            } else
            {
       
                t1.setRangeAxis(null);
            }
        }
    
        public void test3 (CategoryPlot t1) 
        //static  //presumes this::Test<> * t1::CategoryPlot<pre:p,ax:i>CombinedCategoryPlot<> achieves err this::Test<> * t1::CategoryPlot<pre:p,ax:i> ;
        //static  //presumes this::Test<> * t1::CombinedCategoryPlot<pre:p,ax:i> achieves ok this::Test<> * t1::CombinedCategoryPlot<pre:p,ax:i> ;
        //static  //presumes this::Test<> * t1::CategoryPlot<pre:p,ax:i>CombinedDomainCategoryPlot<> achieves err this::Test<> * t1::CategoryPlot<pre:p,ax:i>CombinedDomainCategoryPlot<>;
    
        {
            CombinedCategoryPlot z = (CombinedCategoryPlot) t1;
        }
    
        public void test4 (CategoryPlot t1) 
        //static  //presumes this::Test<> * t1::CategoryPlot<pre:p,ax:i>CombinedCategoryPlot<> achieves ok this::Test<> * t1::CombinedCategoryPlot<pre:p,ax:i> & z = t1;
        //static  //presumes this::Test<> * t1::CategoryPlot<pre:p,ax:i>CombinedDomainCategoryPlot<> achieves ok this::Test<> * t1::CategoryPlot<pre:p,ax:i>CombinedDomainCategoryPlot<>;
    
        {   
            boolean temp = t1 instanceof CombinedCategoryPlot;
            if (temp) {
            CombinedCategoryPlot z = (CombinedCategoryPlot) t1;
        }}
    
        public void test5 (CategoryPlot t1) 
        //static  //presumes this::Test<> * t1::CategoryPlot<pre:p,ax:i>CombinedDomainCategoryPlot<> achieves ok this::Test<> * t1::CategoryPlot<pre:p,ax:i>CombinedDomainCategoryPlot<>;
        {   
            this.test4(t1);
        }
    
        public void test6 (CategoryPlot t1) 
        //static  //presumes this::Test<> * t1::CategoryPlot<pre:p,ax:i>CombinedDomainCategoryPlot<> achieves err this::Test<> * t1::CategoryPlot<pre:p,ax:i>CombinedDomainCategoryPlot<>;
        {   
            this.test3(t1);
        }
    }
}
