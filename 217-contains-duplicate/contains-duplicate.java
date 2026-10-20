class Solution {
    public boolean containsDuplicate(int[] nums) {
        HashMap<Integer,Boolean> s = new HashMap<>();
        
        for(int num:nums){
            if(s.containsKey(num)){
                return true;
            }
            s.put(num,true);
        }
        return false;
    }
}