import java.util.Scanner;

class Linearsearch{
  public static void main(String[] args){
    int n,item,i;
    int c =0;

    Scanner scn = new Scanner(System.in);
    System.out.println("Enter the size of array: ");
    n = scn.nextInt();

    int[] a = new int[n];

    System.out.println("Enter the Elements of the Array: ");
    for(i = 0;i<n;i++){
     a[i] = scn.nextInt();
    }

    System.out.println("Enter the item to search: ");
    item = scn.nextInt();

    for(i = 0;i<a.length;i++){
     if(a[i] == item){
        c++;
        break;
     }
    }

    if(c>0){
    System.out.println("Item Exists at: " + i);
    } else {
    System.out.println("Item does not exist");
    }

 }
}