import java.util.Scanner;

class insert {

    public static void main(String[] args) {

        int n, pos, val;

        Scanner scn = new Scanner(System.in);

        System.out.println("Enter the size of array: ");
        
        n = scn.nextInt();

        int[] a = new int[n];
        int[] b = new int[n + 1];

        System.out.println("Enter the elements of array: ");

        for (int i = 0; i < n; i++) {
            a[i] = scn.nextInt();
        }

        System.out.println("Enter the index position of new value to be inserted: ");
        pos = scn.nextInt();

        System.out.println("Enter the new value to be inserted: ");
        val = scn.nextInt();

        for (int i = 0; i < n + 1; i++) {

            if (i < pos) {
                b[i] = a[i];
            } else if (i == pos) {
                b[i] = val;
            } else {
                b[i] = a[i - 1];
            }
        }

        System.out.println("The new array: ");

        for (int i = 0; i < n + 1; i++) {
            System.out.print(b[i] + " ");
        }

        scn.close();
    }
}
