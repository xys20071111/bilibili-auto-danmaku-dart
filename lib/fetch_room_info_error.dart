class FetchRoomInfoError extends Error {
  String message = '';
  FetchRoomInfoError(this.message);
  @override
  String toString() {
    return message;
  }
}
