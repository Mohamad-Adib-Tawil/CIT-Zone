/// A domain-safe outcome. Transport exceptions are translated by data adapters.
sealed class Result<T, F> {
  const Result();

  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(F failure) onFailure,
  }) => switch (this) {
    Success<T, F>(:final value) => onSuccess(value),
    Failure<T, F>(:final failure) => onFailure(failure),
  };
}

final class Success<T, F> extends Result<T, F> {
  const Success(this.value);

  final T value;
}

final class Failure<T, F> extends Result<T, F> {
  const Failure(this.failure);

  final F failure;
}
