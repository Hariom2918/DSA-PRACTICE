class Solution {
    public boolean hasSameDigits(String s) {
        int[] arr = new int[s.length()];

        for (int i = 0; i < s.length(); i++) {
            arr[i] = s.charAt(i) - '0';
        }
        int n = arr.length;

        while (n > 2) {
            for (int i = 0; i < n - 1; i++) {
                arr[i] = (arr[i] + arr[i + 1]) % 10;
            }
            n--;
        }
        return arr[0] == arr[1];
    }
}