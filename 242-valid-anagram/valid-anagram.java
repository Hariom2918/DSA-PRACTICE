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

        return Arrays.equals(sc,tc);
    }
}