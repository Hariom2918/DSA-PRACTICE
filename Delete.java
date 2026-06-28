import java.util.Scanner;

class Deletion{
  public static void main(String[] args){
    
    int n,pos;
    Scanner scn = new Scanner(System.in);
  
    System.out.println("Enter the Size of Array: ");
    n = scn.nextInt();
 
    int[] a = new int[n];
    int[] b = new int[n-1];

    System.out.println("Enter the elements of array: ");
    for(int i = 0;i<n;i++){
    a[i] = scn.nextInt();
    }


    System.out.println("Enter the index position to be deleted: ");
    pos = scn.nextInt();

    for(int i=0;i<a.length;i++){
    
    if(i<pos){
     b[i]=a[i];
    } else if(i==pos){
     continue;
    } else {
     b[i - 1] = a[i];
   }
  }

System.out.println("Array after Deletion: ");
for(int i = 0;i<n-1;i++){
  System.out.println(b[i]);
 }

}}