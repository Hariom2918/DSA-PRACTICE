class Solution {
    int time = 0;
    List<List<Integer>> ans = new ArrayList<>();

    public List<List<Integer>> criticalConnections(int n, List<List<Integer>> connections) {
        List<Integer>[] graph = new ArrayList[n];

        for (int i = 0; i < n; i++)
            graph[i] = new ArrayList<>();

        for (List<Integer> e : connections) {
            graph[e.get(0)].add(e.get(1));
            graph[e.get(1)].add(e.get(0));
        }

        int[] disc = new int[n];
        int[] low = new int[n];
        Arrays.fill(disc, -1);

        dfs(0, -1, graph, disc, low);
        return ans;
    }

    void dfs(int u, int parent, List<Integer>[] graph, int[] disc, int[] low) {
        disc[u] = low[u] = time++;

        for (int v : graph[u]) {
            if (v == parent) continue;

            if (disc[v] == -1) {
                dfs(v, u, graph, disc, low);
                low[u] = Math.min(low[u], low[v]);

                if (low[v] > disc[u])
                    ans.add(Arrays.asList(u, v));
            } else {
                low[u] = Math.min(low[u], disc[v]);
            }
        }
    }
}