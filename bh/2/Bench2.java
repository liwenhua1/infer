
public class Bench2 {

    public static void main(String[] args) {
        Test i = new Test();
        i.foo(new AbstractEventHandler());

    }

   
    
    }
    
    class SignalEventHandler extends AbstractEventHandler {
      
       Object event;
    
       public Object getEventHandlerType() 
       {
        Object x = this.event;
        return x;
      }
    
    
    }
    
   


class EventSubscription {
    
    Object created;
    Object activity;
    Object execution;

    EventSubscription (Object a) 
    {
        this.created = a;
    }

    public Object getExecution() 
    {
    Object x = this.execution;
    return x;
    }

    public Object getActivity() 
    {
    Object x = this.activity;
    return x;
    }

}

class AbstractEventHandler {

    public void handleEvent(EventSubscription eventSubscription)

    {
        Object execution = eventSubscription.getExecution();
        Object activities = eventSubscription.getActivity();
  
        if (true) {
            execution.toString();
            activities.toString();
           }
    } 
}
class Test {
    
    public void foo(AbstractEventHandler b) 
    {
        Object c = 1;
        EventSubscription a = new EventSubscription(c);
        b.handleEvent(a);
    }
}