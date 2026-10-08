class Solution {
    public int carFleet(int target, int[] position, int[] speed) {        
        double[] cars = new double[target + 1];

        for (int i = 0; i < position.length; i++) {            
            cars[position[i]] = (double) (target - position[i]) / speed[i];
        }        

        int fleet = 0;
        double lastTime = 0;

        for (int i = target; i >= 0; i--) {
            double time = cars[i];

            if (time > lastTime) {
                fleet++;
                lastTime = time;
            }
        }

        return fleet;
    }
}
/*class Solution {
    public int carFleet(int target, int[] position, int[] speed) {

        int n = position.length;
        int[][] cars = new int[n][2];

        for (int i = 0; i < n; i++) {
            cars[i][0] = position[i];
            cars[i][1] = speed[i];
        }
        // Sort by position from nearest to target
        Arrays.sort(cars, (a, b) -> b[0] - a[0]);

        int fleets = 0;
        double lastTime = 0;

        for (int i = 0; i < n; i++) {

            double time = (double)(target - cars[i][0]) / cars[i][1];

            if (time > lastTime) {
                fleets++;
                lastTime = time;
            }
        }
        return fleets;
    }
}*/