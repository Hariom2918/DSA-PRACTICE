class Solution {
    public int findTheCity(int n, int[][] edges, int threshold) {

        int[][] d = new int[n][n];

        for (int i = 0; i < n; i++) {
            for (int j = 0; j < n; j++) {
                d[i][j] = 1000000;
            }
            d[i][i] = 0;
        }

        for (int[] e : edges) {
            d[e[0]][e[1]] = e[2];
            d[e[1]][e[0]] = e[2];
        }

        for (int k = 0; k < n; k++)
            for (int i = 0; i < n; i++)
                for (int j = 0; j < n; j++)
                    d[i][j] = Math.min(d[i][j], d[i][k] + d[k][j]);

        int ans = 0;
        int min = n;

        for (int i = 0; i < n; i++) {
            int count = 0;

            for (int j = 0; j < n; j++)
                if (d[i][j] <= threshold)
                    count++;

            if (count <= min) {
                min = count;
                ans = i;
            }
        }

        return ans;
    }
}