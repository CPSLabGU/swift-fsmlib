// Host implementation of the functions that DoorInterlock declares.

func isSafe(_ closed: Bool) -> Bool {
    closed
}

func logEvent(_ event: Int) {
    print("log \(event)")
}
