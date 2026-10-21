class Solution {
    public List<String> letterCombinations(String digits) {
        List<String> ans = new ArrayList<>();
        if (digits.length() == 0) return ans;

        String[] map = {"", "", "abc", "def", "ghi", "jkl",
                        "mno", "pqrs", "tuv", "wxyz"};

        solve(digits, 0, "", ans, map);
        return ans;
    }

    void solve(String digits, int index, String path,
               List<String> ans, String[] map) {
        if (index == digits.length()) {
            ans.add(path);
            return;
        }

        String letters = map[digits.charAt(index) - '0'];

        for (char c : letters.toCharArray()) {
            solve(digits, index + 1, path + c, ans, map);
        }
    }
}