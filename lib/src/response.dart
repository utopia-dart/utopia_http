class Response {
  String body;
  int _status = 200;
  Response(this.body, {int status = 200}) : _status = status;

  int get status => _status;

  end(message, {int status = 200}) {
    body = message;
    status = 200;
  }

  Response.s404(String message) : this(message);

  Response.send(String message, {int status = 200})
      : this(message, status: status);
}
