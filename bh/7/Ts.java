import java.util.Map;

public class Ts {
    private Map<Integer, Integer> datasets;

    public Integer getDataset(int index) {
        return this.datasets.get(index);
     
    }

    public void test (Ts a) {
        Integer b = a.getDataset(0);
        b.toString(); 
    }
}