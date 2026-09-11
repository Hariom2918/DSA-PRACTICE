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
     /*int n = prices.length;
        int max_Profit = 0;
        int buyPrice = prices[0];

        for (int i = 1; i < n; i++) {

            int currProfit = prices[i] - buyPrice;

            if (currProfit > max_Profit) {
                max_Profit = currProfit;
            }

            if (prices[i] < buyPrice) {
                buyPrice = prices[i];
            }
        }

        return max_Profit;*/
    }
}
