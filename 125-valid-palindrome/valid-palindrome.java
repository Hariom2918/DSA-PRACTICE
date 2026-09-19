class Solution {
    public boolean isPalindrome(String s) {
        
        String t ="";
        for(int i = 0;i<s.length();i++){
            char c = s.charAt(i);

            if(Character.isLetterOrDigit(c)){
                t += Character.toLowerCase(c);
            }
        }
        
        
        String ans="";
        for(int i = t.length()-1;i>=0;i--){
            ans += t.charAt(i);
        }
        return t.equals(ans);
    }
}