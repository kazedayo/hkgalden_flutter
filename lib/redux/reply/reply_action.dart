class SendReplyAction {
  final int threadId;
  final String parentId;
  final String html;

  SendReplyAction(this.threadId, this.html, {this.parentId});

}

class SendReplySuccessAction {}

class SendReplyErrorAction{}