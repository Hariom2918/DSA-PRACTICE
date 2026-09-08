class Solution {
    int[] parent;

    public int[] findRedundantConnection(int[][] edges) {
        parent = new int[edges.length + 1];

        for (int i = 0; i < parent.length; i++)
            parent[i] = i;

        for (int[] e : edges) {
            int a = find(e[0]);
            int b = find(e[1]);

            if (a == b)
                return e;

            parent[a] = b;
        }

        return new int[0];
    }

    int find(int x) {
        if (parent[x] != x)
            parent[x] = find(parent[x]);

        return parent[x];
    }
}