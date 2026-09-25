class Solution {
    public boolean isAnagram(String s, String t) {
        int[] sc = new int[26];
        int[] tc = new int[26];
        for (char ch : s.toCharArray()) {
            sc[ch-'a']++;
        }
        for (char ch : t.toCharArray()) {
            tc[ch-'a']++;
        }

        for (int i = 0; i < 26; i++) {
            if (sc[i] != tc[i]) return false;
        }

        return true;
    }
}