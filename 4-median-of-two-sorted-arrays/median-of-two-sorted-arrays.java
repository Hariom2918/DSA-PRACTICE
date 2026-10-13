
class Solution {
    public double findMedianSortedArrays(int[] nums1, int[] nums2) {
        if (nums1.length > nums2.length) {
            return findMedianSortedArrays(nums2, nums1);
        }

        int m = nums1.length;
        int n = nums2.length;
        int low = 0;
        int high = m;

        while (low <= high) {
            int i = low + (high - low) / 2;
            int j = (m + n + 1) / 2 - i;

            int left1 = (i == 0) ? Integer.MIN_VALUE : nums1[i - 1];
            int right1 = (i == m) ? Integer.MAX_VALUE : nums1[i];

            int left2 = (j == 0) ? Integer.MIN_VALUE : nums2[j - 1];
            int right2 = (j == n) ? Integer.MAX_VALUE : nums2[j];

            if (left1 <= right2 && left2 <= right1) {
                if ((m + n) % 2 == 0) {
                    return ((double) Math.max(left1, left2)
                          + Math.min(right1, right2)) / 2;
                } else {
                    return Math.max(left1, left2);
                }
            } else if (left1 > right2) {
                high = i - 1;
            } else {
                low = i + 1;
            }
        }

        return 0.0;
    }
}

/*class Solution {
    public double findMedianSortedArrays(int[] nums1, int[] nums2) {
        int m = nums1.length, n = nums2.length;
        int[] arr = new int[m + n];

        int i = 0, j = 0, k = 0;

        while (i < m && j < n) {
            if (nums1[i] < nums2[j])
                arr[k++] = nums1[i++];
            else
                arr[k++] = nums2[j++];
        }

        while (i < m) arr[k++] = nums1[i++];
        while (j < n) arr[k++] = nums2[j++];

        int len = arr.length;

        if (len % 2 == 1)
            return arr[len / 2];

        return (arr[len / 2 - 1] + (double) arr[len / 2]) / 2;
    }
}*/
