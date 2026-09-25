/**
 * Definition for a binary tree node.
 * public class TreeNode {
 *     int val;
 *     TreeNode left;
 *     TreeNode right;
 *     TreeNode() {}
 *     TreeNode(int val) { this.val = val; }
 *     TreeNode(int val, TreeNode left, TreeNode right) {
 *         this.val = val;
 *         this.left = left;
 *         this.right = right;
 *     }
 * }
 */
class Solution {
    public TreeNode sortedArrayToBST(int[] nums) {
        return q(nums,0,nums.length-1);
        
    }
    private TreeNode q(int nums[], int left,int right){
        if(left>right) return null;

        int mid  = left + (right - left)/2;

        TreeNode r = new TreeNode(nums[mid]);

        r.left = q(nums,left,mid - 1);
        r.right = q(nums,mid + 1,right);
        return r;

    }
}