/// Base exception for comment-related errors.
class CommentException implements Exception {
  const CommentException(this.message, [this.code]);

  final String message;
  final String? code;

  @override
  String toString() => 'CommentException: $message${code != null ? ' ($code)' : ''}';
}

/// Thrown when a comment cannot be found.
class CommentNotFoundException extends CommentException {
  const CommentNotFoundException() : super('Comment not found', 'NOT_FOUND');
}

/// Thrown when a user is not authorized to perform an action on a comment.
class CommentUnauthorizedException extends CommentException {
  const CommentUnauthorizedException()
      : super('Not authorized to perform this action', 'UNAUTHORIZED');
}

/// Thrown when the comment content is invalid.
class InvalidCommentContentException extends CommentException {
  const InvalidCommentContentException()
      : super('Comment content is invalid', 'INVALID_CONTENT');
}
