class Solution {
    public void rotate(int[][] matrix) {
        int n = matrix.length;
        //clockwise 
        transpose(matrix,n);
        for(int i =0;i<n;i++){//n/2 for anticlockwise
            for(int j =0;j<n/2;j++){//n
                int temp = matrix[i][j];
                matrix[i][j] = matrix[i][n-1-j];//n-1-iand j
                matrix[i][n-1-j] = temp;
            }
        }
    }

    static void transpose(int matrix[][], int n){
     for(int i =0;i<n;i++){
        for(int j =0;j<i;j++){
            int temp = matrix[i][j];
            matrix[i][j] = matrix[j][i];
            matrix[j][i] = temp;

        }
     }
    }
}