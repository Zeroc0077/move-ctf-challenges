module solution::exploit {
    use challenge::sage;

    public entry fun solve() {
        sage::challenge(vector[22, 12, 17, 6, 17, 0, 19, 20, 33, 0, 19, 8, 14, 13, 18, 24, 36, 20, 0, 10, 37, 0, 28, 4, 3, 41, 36, 1, 17, 37, 0, 32, 19, 7, 4, 29, 8, 11, 11, 34, 18, 39, 35, 32, 5, 11, 4, 16, 30, 39, 11, 4, 7, 0, 22, 8, 28, 15, 33, 0, 13, 4, 41], vector[25, 11, 6, 32, 13, 3, 12, 19, 2]);
    }
}
