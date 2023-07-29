public class Bench1{
    
class ErrorMessage {
    int location;

     public ErrorMessage setLocation(Object value) 
     
     {
          
            if (true) {
                value.toString();
                this.location = (int) value;
                return this;
            } else {
                this.location =(int)  value;
                return this;
            }
        }

}
class ErrorCode {

     public Object convert()
     {
       
        return null;
    }

    public void convert1(int source, ErrorMessage throwable)
    {
        Object q = this.convert();
        throwable.setLocation( q);
        }
}
}