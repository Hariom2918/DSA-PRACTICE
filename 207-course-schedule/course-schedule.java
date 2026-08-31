class Solution {
    public boolean canFinish(int numCourses, int[][] prerequisites) {

        List<List<Integer>> graph = new ArrayList<>();

        for (int i = 0; i < numCourses; i++) {
            graph.add(new ArrayList<>());
        }

        // Build graph
        for (int[] p : prerequisites) {
            int course = p[0];
            int prerequisite = p[1];

            graph.get(prerequisite).add(course);
        }

        // 0 = not visited
        // 1 = currently visiting
        // 2 = completely visited
        int[] state = new int[numCourses];

        for (int i = 0; i < numCourses; i++) {
            if (state[i] == 0) {
                if (hasCycle(graph, i, state)) {
                    return false;
                }
            }
        }

        return true;
    }

    private boolean hasCycle(
        List<List<Integer>> graph,
        int course,
        int[] state
    ) {

        // Course is already in current DFS path
        if (state[course] == 1) {
            return true;
        }

        // Already completely explored
        if (state[course] == 2) {
            return false;
        }

        // Mark as currently visiting
        state[course] = 1;

        for (int next : graph.get(course)) {
            if (hasCycle(graph, next, state)) {
                return true;
            }
        }

        // Finished exploring this course
        state[course] = 2;

        return false;
    }
}