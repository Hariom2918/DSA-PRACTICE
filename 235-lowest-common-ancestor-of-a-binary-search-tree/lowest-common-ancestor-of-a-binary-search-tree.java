/**
 * Definition for a binary tree node.
 * public class TreeNode {
 *     int val;
 *     TreeNode left;
 *     TreeNode right;
 *     TreeNode(int x) { val = x; }
 * }
 */

class Solution {
    public TreeNode lowestCommonAncestor(TreeNode root, TreeNode p, TreeNode q) {
        int min=Math.min(p.val,q.val);
        int max =Math.max(q.val,p.val);
        while(root != null){
            int curr = root.val;
            if(min<curr && max<curr){
                root=root.left;
            }else if(min>curr && max>curr){
                root=root.right;
            }else{
                break;
            }
        }
        return root;
    }
}