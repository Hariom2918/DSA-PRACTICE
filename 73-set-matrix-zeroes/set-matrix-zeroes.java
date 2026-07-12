class Solution {
    public void setZeroes(int[][] matrix) {
        int m = matrix.length;
        int n = matrix[0].length;
        //flags
        boolean firstRowHas0 = false;
        boolean firstColHas0 = false;

        for(int j = 0;j<n;j++){
            if(matrix[0][j] == 0){
                firstRowHas0 = true;
            }
        }

        for(int i=0;i<m;i++){
            if(matrix[i][0] == 0){
                firstColHas0 = true;
            }
        }
        //markers
        for(int i =1;i<m;i++){
            for(int j =1;j<n;j++){
                if(matrix[i][j]==0){
                    matrix[i][0] = 0;
                    matrix[0][j] = 0;
                }
            }
        }
        //placing 0 using markers
        for(int i=1;i<m;i++){
            for(int j =1;j<n;j++){
                if(matrix[i][0] == 0 || matrix[0][j] == 0){
                    matrix[i][j] = 0;
                }
            }
        }
        //update first row/col
        if(firstRowHas0 ){
            for(int j = 0;j<n;j++){
                matrix[0][j] =0;
            }
        }

        if(firstColHas0 ){
            for(int i =0;i<m;i++){
                matrix[i][0] = 0;
            }
        }
    }

}