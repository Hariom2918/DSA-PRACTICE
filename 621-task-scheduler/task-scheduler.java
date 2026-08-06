class Task implements Comparable<Task>{
    int freq;
    int et;
    Task(int f,int t){
        freq = f;
        et = t;
    }
    public int compareTo(Task that){
        return that.freq - this.freq;
    }
}
class Solution {
    public int leastInterval(char[] tasks, int n) {
        HashMap<Character,Integer> fm = new HashMap<>();
        for(char ch : tasks){
            fm.put(ch,fm.getOrDefault(ch,0)+1);
        }
        PriorityQueue<Task> pq = new PriorityQueue<>();
        for(Character ch: fm.keySet()){
            int fre = fm.get(ch);
            pq.offer(new Task(fre,0));
        }
        Queue<Task> q = new LinkedList<>();
        int time =0;
        while(!q.isEmpty() || !pq.isEmpty()){
            time++;
            if(!pq.isEmpty()){
                Task task = pq.poll();
                task.freq--;
                if(task.freq>0){
                    task.et = time + n;
                    q.offer(task);
                }
            }
            if(!q.isEmpty() && q.peek().et == time){
                pq.offer(q.poll());
            }
        }
        return time;
    }
}