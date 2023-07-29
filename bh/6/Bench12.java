

public class Bench12 {
    
    class DefaultPieDataset {
        int k;
        int v;
    
        public void setValue (int a, int b)
        //presumes this::DefaultPieDataset<k:m,v:n> & a = f & b = u achieves this::DefaultPieDataset<k:f,v:u> & a = f & b = u ;
        {
            this.k = a;
            this.v = b;
        } 
    
      
    }
    
    class Stack {
       
      
        
    
        public void push (int a)
        //presumes this::Stack<> achieves this::Stack<> ;
        {
    
        } 
    
         public Object peek()
    
         //presumes this::Stack<> achieves this::Stack<> * res::Objec<>;
        {
                return new Object();
        } 
    }
    
    class RootHandler {
    
        Stack subHandlers;
        
        RootHandler() 
        //presumes true achieves new_this::RootHandler<subHandlers:sb> * sb::Stack<>;
        {
            Stack sb = new Stack();
            this.subHandlers  = sb;
            
        }
    
        public Stack getSubHandlers() 
        //static //presumes this::RootHandler<subHandlers:ww> achieves this::RootHandler<subHandlers:ww> & res = ww;
        //dynamic //presumes this::RootHandler<subHandlers:ww> achieves this::RootHandler<subHandlers:ww> & res = ww;
        {
            Stack e = this.subHandlers;
            return e;
        }
    
         public RootHandler getCurrentHandler() 
        //static //presumes this::RootHandler<subHandlers:sb> * sb::Stack<> achieves this::RootHandler<subHandlers:sb> * sb::Stack<> & res = this;
        //dynamic //presumes this::RootHandler<subHandlers:sb> * sb::Stack<> achieves this::RootHandler<subHandlers:sb> * sb::Stack<> & res = this;
        {
            RootHandler result = this;
            Stack temp = this.subHandlers;
             if ( temp != null) {
                    Stack top1 = this.subHandlers;
                    Object top = top1.peek();
                    if (top != null) {
                        return result;
                    }
                
            }
            return result;
    
        }
    
        public void startElement (String namespaceURI, String localName, int qName)
        //static //presumes this::RootHandler<subHandlers:sb> & qName = 2 achieves ok this::RootHandler<subHandlers:sb> * sb::Stack<> & qName = 2;
        //dynamic //presumes this::RootHandler<subHandlers:sb>  & qName = 2 achieves ok this::RootHandler<subHandlers:sb> * sb::Stack<> & qName = 2;
    
        {
        
        }
        public void endElement(String namespaceURI,
                               String localName,
                               int qName)  
                               
        //static //presumes this::RootHandler<subHandlers:sbw> achieves this::RootHandler<subHandlers:sbw> * sbw::Stack<> ;
        //dynamic //presumes this::RootHandler<subHandlers:sb> achieves this::RootHandler<subHandlers:sb> * sb::Stack<>;
               
                               {
    
            
            }
    
        
    
    
    }
    
    class PieDatasetHandler extends RootHandler {
    
     
        DefaultPieDataset dataset;
    
      
        PieDatasetHandler() 
        //presumes true achieves new_this::PieDatasetHandler<subHandlers:sb,dataset:null> * sb::Stack<>;
        {
           Stack sb = new Stack();
           this.subHandlers = sb;
        }
    
        public Stack getSubHandlers() 
        //static //presumes this::PieDatasetHandler<subHandlers:sb,dataset:da> achieves this::PieDatasetHandler<subHandlers:sb,dataset:da> & res = sb;
        //dynamic //presumes this::RootHandler<subHandlers:sb>PieDatasetHandler<dataset:da> achieves this::RootHandler<subHandlers:sb>PieDatasetHandler<dataset:da> & res = sb;
        {
           return this.subHandlers;
        }
    
    
       
        public DefaultPieDataset getDataset() 
        //presumes this::PieDatasetHandler<subHandlers:sb,dataset:q> achieves this::PieDatasetHandler<subHandlers:sb,dataset:q> & res = q;
        {
            DefaultPieDataset e = this.dataset;
            return e;
        }
    
          public void addItem(int key, int value) 
          //presumes this::PieDatasetHandler<subHandlers:sb,dataset:g> * g::DefaultPieDataset<k:j,v:k> & key = z & value = c achieves this::PieDatasetHandler<subHandlers:sb,dataset:g> * g::DefaultPieDataset<k:z,v:c>& key = z & value = c;
    
          {
            DefaultPieDataset v = this.dataset;
            v.setValue(key, value);
        }
    
       
    
         
        public void endElement(String namespaceURI,
                               String localName,
                               int qName)  
                               
        //static //presumes this::PieDatasetHandler<subHandlers:sbw,dataset:g> achieves this::PieDatasetHandler<subHandlers:sbw,dataset:g> * sbw::Stack<> & current = this;
        //dynamic //presumes this::RootHandler<subHandlers:sb>PieDatasetHandler<dataset:g> achieves this::RootHandler<subHandlers:sb>PieDatasetHandler<dataset:g> * sb::Stack<> & current = this;
               
                               {
    
            RootHandler current = this.getCurrentHandler();
            if (current != this) {
                current.endElement(namespaceURI, localName, qName);
            }
    
        }
    
          public void startElement(String namespaceURI, String localName, int qName)
            //static //presumes this::PieDatasetHandler<subHandlers:sb6,dataset:g> & qName = 2 achieves ok this::PieDatasetHandler<subHandlers:sb6,dataset:g> * sb6::Stack<> & qName = 2;
            //static //presumes this::PieDatasetHandler<subHandlers:sb6,dataset:g> & qName = 2 achieves err this::PieDatasetHandler<subHandlers:sb6,dataset:g> * sb6::Stack<> & qName = 2;
            //dynamic //presumes this::RootHandler<subHandlers:sb6>PieDatasetHandler<dataset:g>  & qName = 2 achieves ok this::RootHandler<subHandlers:sb6>PieDatasetHandler<dataset:g> * sb6::Stack<> & qName = 2;
                        
                                 {
    
             RootHandler current = this.getCurrentHandler();
            if (current != this) {
                } else {
                if (qName == 1) {
                this.dataset = new DefaultPieDataset();
            } else {
                if (qName == 2) {
                int subhandler= 6;
                Stack temp = this.getSubHandlers();
                temp.push(subhandler);
            }
                else {}
            }}
    
        }
    
        public PieDatasetHandler test() 
        //presumes true achieves ok y::PieDatasetHandler<subHandlers:sb,dataset:g> & sb=null;
    
        {
            PieDatasetHandler y = new PieDatasetHandler();
            return y;
        }
    
    }
    
    class CategoryDatasetHandler extends RootHandler {
        
      
    
         public void endElement(String namespaceURI,
                               String localName,
                               int qName)  
                               
        //static //presumes this::CategoryDatasetHandler<subHandlers:sbw> achieves this::CategoryDatasetHandler<subHandlers:sbw> * sbw::Stack<> & current = this;
        //dynamic //presumes this::RootHandler<subHandlers:sb>CategoryDatasetHandler<> achieves this::RootHandler<subHandlers:sb>CategoryDatasetHandler<> * sb::Stack<> & current = this;
               
                               {
    
            RootHandler current = this.getCurrentHandler();
            if (current != this) {
                current.endElement(namespaceURI, localName, qName);
            }
    
        }
        
    
    
        public void startElement(String namespaceURI,String localName, int qName) 
        //static //presumes this::CategoryDatasetHandler<subHandlers:sb6> & qName = 2 achieves ok this::CategoryDatasetHandler<subHandlers:sb6> * sb6::Stack<> & qName = 2;
        //static //presumes this::CategoryDatasetHandler<subHandlers:sb6> & qName = 2 achieves err this::CategoryDatasetHandler<subHandlers:sb6> * sb6::Stack<> & qName = 2;
        //dynamic //presumes this::RootHandler<subHandlers:sb6>CategoryDatasetHandler<>  & qName = 2 achieves ok this::RootHandler<subHandlers:sb6>CategoryDatasetHandler<> * sb6::Stack<> & qName = 2;
                
        {
    
            RootHandler current = this.getCurrentHandler();
            if (current != this) {
                } else {
                if (qName == 1) {
                this.subHandlers = new Stack();
            } else {
                if (qName == 2) {
                int subhandler= 6;
                Stack temp = this.getSubHandlers();
                temp.push(subhandler);
            }
                else {}
            }}
        }
    
    }
    
    class Map {
    
    }
    
    class CustomPieURLGenerator {
        int index;
        int count;
    
        public int getListCount() 
        //presumes this::CustomPieURLGenerator<index:z,count:x> achieves this::CustomPieURLGenerator<index:z,count:x> & res = x;
    
        {   
            int temp = this.count;
            return temp;
        }
    
        public Object getObj(int t)
        //static //presumes this::CustomPieURLGenerator<index:z,count:x> & t > 0 achieves this::CustomPieURLGenerator<index:z,count:x> * res::Objec<>& t > 0;
    
        //static //presumes this::CustomPieURLGenerator<index:z,count:x> & t <= 0 achieves this::CustomPieURLGenerator<index:z,count:x> & res=null& t <= 0 ;
    
    
        {   
            if (t > 0) {return new Object();} else {return null;}
        }
    
        public Object getURL(Object key, int mapIndex) 
        //presumes this::CustomPieURLGenerator<index:q,count:x> * key::Objec<> & x < mapIndex achieves this::CustomPieURLGenerator<index:q,count:x> * key::Objec<> & x < mapIndex & res = null;
    
        {
            String result = null;
            int temp = this.getListCount();
            if (mapIndex < temp) {
                int temp2 = this.index;
                Object urlMap = this.getObj(temp2);
                if (urlMap != null) {
                    result = (String) urlMap.toString();
                }
            }
            return result;
        }
    
        public boolean equals(Object m) 
        //static //presumes this::CustomPieURLGenerator<index:z,count:l> * m::CustomPieURLGenerator<index:u,count:i> & l<i achieves err this::CustomPieURLGenerator<index:z,count:l> * k::Objec<> *m::CustomPieURLGenerator<index:u,count:i> & l<i & g=null;
    
        {
            
            boolean h = m instanceof CustomPieURLGenerator;
            if (h) {
                int t1 = this.getListCount();
                int t2 = ((CustomPieURLGenerator) m).getListCount();
                if ( t1 != t2) {
                    int pieItem = t2;
                    Object k = new Object();
                    Object g = this.getURL(k, pieItem);
                    g.toString();
                    return false;
                }
               
            }
            return true;
        }
    
    
    }
}
