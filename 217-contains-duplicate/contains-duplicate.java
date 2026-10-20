class Solution {
    public boolean containsDuplicate(int[] nums) {
        HashSet<Integer> s = new HashSet<>();
        
        for(int n:nums){
            if(s.contains(n)){
                return true;
            }else{
            s.add(n);
            }
        }
        return false;
    }
}

/* HashMap<Integer,Boolean> s = new HashMap<>();
        
        for(int num:nums){
            if(s.containsKey(num)){
                return true;
            }
            s.put(num,true);
        }
        return false;*/