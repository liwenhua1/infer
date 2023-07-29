public class Example2 {
    public static void main(String[] args) {
        CustomPieURLGenerator o = new CustomPieURLGenerator();
        CustomPieURLGenerator i = new CustomPieURLGenerator();
        o.equals(i);
    }
    
}

class CustomPieURLGenerator {
    int index;
    int count;

    public int getListCount() 
 
        {   
            int temp = this.count;
            return temp;
        }

        public Object getObj(int t)
  
        {   
            return null;
        }

    public Object getURL(Object key, int mapIndex) 
  
    {
        String result = null;
        int temp = this.getListCount();
        if (mapIndex < temp) {
            int temp2 = this.index;
            Object urlMap = this.getObj(temp2); 
            if (urlMap != null) { //urlMap is always null
                result = (String) urlMap.toString();
            }
        }
        return result;
    }

    public boolean equals(CustomPieURLGenerator m) 
  
    {
        if (true) {
            int t2 = m.getListCount();
                int pieItem = t2;
                Object k = new Object();
                Object g = this.getURL(k, pieItem);
                g.toString(); //null pointer here
                return false;
            
    }
    return true;
}
}