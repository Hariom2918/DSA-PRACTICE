class Solution {
    public int[] relativeSortArray(int[] arr1, int[] arr2) {
        int[] freq = new int[1001];

        // Count frequency of each number
        for (int num : arr1) {
            freq[num]++;
        }

        int index = 0;

        // Place elements in arr2 order
        for (int num : arr2) {
            while (freq[num] > 0) {
                arr1[index++] = num;
                freq[num]--;
            }
        }

        // Place remaining elements in ascending order
        for (int i = 0; i < freq.length; i++) {
            while (freq[i] > 0) {
                arr1[index++] = i;
                freq[i]--;
            }
        }

        return arr1;
    }
}