// Host implementation of the functions that DoorInterlock declares.

final class DoorInterlockHost {
    private DoorInterlockHost() {
    }

    static boolean isSafe(boolean closed) {
        return closed;
    }

    static void logEvent(int event) {
        System.out.print("log " + event + "\n");
    }
}
