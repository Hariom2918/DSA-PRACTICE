class Solution {
    public boolean isPalindrome(String s) {
        
       /* String t ="";
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
        return t.equals(ans);*/
        int left = 0;
        int right = s.length() - 1;

        while( left < right){

            while(left < right && !Character.isLetterOrDigit(s.charAt(left))){
                left++;
            }
            while(left < right && !Character.isLetterOrDigit(s.charAt(right))){
                right--;
            }

            if(Character.toLowerCase(s.charAt(left)) != Character.toLowerCase(s.charAt(right))){
                return false;
            }
            left++;
            right--;
        }
        return true;
    }
}