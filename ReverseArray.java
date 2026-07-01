class Reverse{
 static void reverse(int arr[]){
   int i = 0,j = arr.length - 1;
   while(i<j){
   int t = arr[i];
   arr[i] = arr[j];
   arr[j] = t;
   i++;
   j--;
  
}}

public static void main(String[] args){
  int[] arr = {2,4,6,8,10,12,14};

  System.out.println("Array Elements before reversing: ");
  for(int i = 0;i<arr.length;i++){
   System.out.print(arr[i] + " ");
  }

  reverse(arr);
     System.out.println(" ");

  System.out.println("Array Elements after reversing: ");
  for(int i = 0;i<arr.length;i++){
    System.out.print(arr[i] + " ");
  }

}}