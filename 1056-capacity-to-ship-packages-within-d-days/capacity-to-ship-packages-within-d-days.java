class Solution {
    public int shipWithinDays(int[] weights, int days) {
        int low = 0, high = 0;

        for (int w : weights) {
            low = Math.max(low, w);
            high += w;
        }

        while (low < high) {
            int mid = low + (high - low) / 2;
            int day = 1, load = 0;

            for (int w : weights) {
                if (load + w > mid) {
                    day++;
                    load = 0;
                }
                load += w;
            }

            if (day <= days)
                high = mid;
            else
                low = mid + 1;
        }

        return low;
    }
}