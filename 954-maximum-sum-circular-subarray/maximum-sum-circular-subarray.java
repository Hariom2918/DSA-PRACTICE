class Solution {
    public int maxSubarraySumCircular(int[] nums) {
        int currmax = 0;
        int maxsum = Integer.MIN_VALUE;

        int currmin = 0;
        int minsum = Integer.MAX_VALUE;
        int totalsum = 0;

        for(int num : nums){
            currmax = Math.max(num , currmax + num);
            maxsum = Math.max(currmax , maxsum);

            currmin = Math.min(num , currmin + num);
            minsum = Math.min(currmin , minsum);

            totalsum += num;
        }

        if(maxsum < 0){
            return maxsum;
        }
        return Math.max(maxsum , totalsum - minsum);
    }
}