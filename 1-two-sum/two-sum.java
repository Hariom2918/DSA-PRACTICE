class Solution{
    public int[] twoSum(int nums[],int target){
       HashMap<Integer,Integer> m = new HashMap<>();
       int n = nums.length;
       for(int i = 0;i<n;i++){
        int req = target - nums[i];
        if(m.containsKey(req)){
            int arr[] = {m.get(req), i};
            return arr;
        }
        m.put(nums[i],i);
       }
       return null;
    }
}