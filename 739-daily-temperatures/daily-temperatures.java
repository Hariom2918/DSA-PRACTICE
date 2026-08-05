class Solution {
    public int[] dailyTemperatures(int[] temperatures) {
        Stack<Integer> helperstack = new Stack<>();
        int n  = temperatures.length;
        int res[] = new int[n];

        for(int i = n -1;i>=0;i--){
            while(!helperstack.isEmpty() && temperatures[i] >= temperatures[helperstack.peek()]){
                helperstack.pop();
            }

            if(!helperstack.isEmpty()){
                res[i] = helperstack.peek() - i;
            }
            

            helperstack.push(i);
        }
        return res;
    }
}