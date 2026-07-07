class Solution {
    public int[] intersect(int[] nums1, int[] nums2) {
        int[] freqarr = new int[1001];

        for(int nums : nums1){
            freqarr[nums]++;
        }

        ArrayList<Integer> list = new ArrayList<>();
        for(int nums : nums2){
            if(freqarr[nums]>0){
                list.add(nums);
                freqarr[nums]--;
            }
        }
        int k = list.size();
        int[] result = new int[k];
        for(int i = 0;i<k;i++){
            result[i]=list.get(i);
        }
        return result;
    }
}