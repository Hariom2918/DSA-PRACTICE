class Solution {
    public String makeFancyString(String s) {
        char[] arr = s.toCharArray();
        int j = 0;

        for (int i = 0; i < arr.length; i++) {
            if (j >= 2 && arr[j - 1] == arr[i] && arr[j - 2] == arr[i]) {
                continue;
            }

            arr[j++] = arr[i];
        }

        return new String(arr, 0, j);
    }
}