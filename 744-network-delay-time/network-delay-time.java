import java.util.*;

class Solution {
    public int networkDelayTime(int[][] times, int n, int k) {

        // Adjacency list
        List<int[]>[] graph = new ArrayList[n + 1];

        for (int i = 1; i <= n; i++) {
            graph[i] = new ArrayList<>();
        }

        for (int[] time : times) {
            int u = time[0];
            int v = time[1];
            int w = time[2];

            graph[u].add(new int[]{v, w});
        }

        // distance[i] = shortest time from k to i
        int[] distance = new int[n + 1];
        Arrays.fill(distance, Integer.MAX_VALUE);

        distance[k] = 0;

        // {node, distance}
        PriorityQueue<int[]> pq =
            new PriorityQueue<>((a, b) -> a[1] - b[1]);

        pq.offer(new int[]{k, 0});

        while (!pq.isEmpty()) {

            int[] current = pq.poll();

            int node = current[0];
            int time = current[1];

            // Ignore outdated entry
            if (time > distance[node]) {
                continue;
            }

            for (int[] edge : graph[node]) {

                int next = edge[0];
                int weight = edge[1];

                int newTime = time + weight;

                if (newTime < distance[next]) {
                    distance[next] = newTime;
                    pq.offer(new int[]{next, newTime});
                }
            }
        }

        // Find maximum shortest distance
        int answer = 0;

        for (int i = 1; i <= n; i++) {

            if (distance[i] == Integer.MAX_VALUE) {
                return -1;
            }

            answer = Math.max(answer, distance[i]);
        }

        return answer;
    }
}