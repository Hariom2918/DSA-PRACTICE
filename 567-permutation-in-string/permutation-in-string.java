class Solution {
    public boolean checkInclusion(String s1, String s2) {
        int[] count = new int[26];

        for (char c : s1.toCharArray())
            count[c - 'a']++;

        int left = 0;

        for (int right = 0; right < s2.length(); right++) {
            count[s2.charAt(right) - 'a']--;

            if (right - left + 1 > s1.length()) {
                count[s2.charAt(left) - 'a']++;
                left++;
            }

            if (right - left + 1 == s1.length()) {
                boolean found = true;

                for (int x : count) {
                    if (x != 0) {
                        found = false;
                        break;
                    }
                }

                if (found) return true;
            }
        }

        return false;
    }
}