class Number implements Comparable<Number>{
    int element ;
    int freq;
    Number(int element, int freq){
        this.element = element;
        this.freq = freq;
    }
    public int compareTo(Number that){
        return this.freq - that.freq;
    }
}
class Solution {
    public int[] topKFrequent(int[] nums, int k) {
        PriorityQueue<Number> pq = new PriorityQueue<>();
        HashMap<Integer,Integer> hm =  new HashMap<>();
        for(int element : nums){
            hm.put(element,hm.getOrDefault(element,0) + 1);
        }
        for(Map.Entry<Integer,Integer> entry : hm.entrySet()){
            Number n = new Number(entry.getKey(),entry.getValue());
            pq.offer(n);
            if(pq.size()>k){
                pq.poll();
            }
        }
        int res[] = new int[k];
        int index = 0;
        while(index<k){
            Number n = pq.poll();
            res[index]= n.element;
            index++;
        }
        return res;
    }

}