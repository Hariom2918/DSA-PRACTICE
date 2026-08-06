class Solution {
    public int leastInterval(char[] tasks, int n) {
        
        int[] freq = new int[26];

        for(char ch : tasks){
            freq[ch - 'A']++;
        }
        int maxFreq = 0;
        for(int i : freq){
            maxFreq = Math.max(maxFreq,i);
        }
        int countMax = 0;
        for(int i : freq){
            if(i == maxFreq) countMax++;
        }

        int part = (maxFreq - 1) * (n+1) + countMax;

        return Math.max(tasks.length, part);
    }
}