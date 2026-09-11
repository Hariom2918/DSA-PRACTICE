class Solution {
    public int maxProfit(int[] prices) {
     int buyprice=prices[0];
     int maxprofit=0;
     for(int i =1;i<prices.length;i++){

        int currprofit = prices[i] - buyprice;   
        maxprofit=Math.max(maxprofit,currprofit);
        buyprice = Math.min(buyprice,prices[i]);
     }
     return maxprofit;
    }
}