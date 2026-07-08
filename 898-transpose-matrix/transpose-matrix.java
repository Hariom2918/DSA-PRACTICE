class Solution {
    public int[][] transpose(int[][] A) {
        int r = A.length;
        int c =A[0].length;
        int output[][] = new int [c][r];

        for(int i =0;i<A.length;i++){
            for(int j = 0;j<A[0].length;j++){
                output [j][i] = A[i][j];
            }
        }
        return output;
    }
}