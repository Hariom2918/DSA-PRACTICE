class Solution {
    public int findKthLargest(int[] nums, int k) {
        int count[]=new int[200001];
        
        for(int num:nums){
            count[num+100000]++;
        }

        for(int i = count.length -1;i>=0;i--){
            if(count[i]>0){
                k-=count[i];
                if(k<=0) return i - 100000;
            }
        }
        return -1;
        //Arrays.sort(nums);
        //return nums[nums.length - k];
    }
}