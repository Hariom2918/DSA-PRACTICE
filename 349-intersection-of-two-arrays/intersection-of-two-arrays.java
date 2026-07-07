class Solution {
    public int[] intersection(int[] nums1, int[] nums2) {
        int[] frarr = new int[1001];
        for(int nums : nums1){
            frarr[nums]++;
        }

        ArrayList<Integer> list = new ArrayList<>();
        for(int nums : nums2){
            if(frarr[nums]>0){
                list.add(nums);
                frarr[nums]--;
                frarr[nums]=0;
            }
        }
        int k  = list.size();
        int[] r = new int[k];
        for(int i = 0;i<k;i++){
            r[i]=list.get(i);
        } 
        return r;
    }
}