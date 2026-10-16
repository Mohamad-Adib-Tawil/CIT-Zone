/// Safe domain codes only; no provider exceptions, signed URLs or license data.
enum MediaFailure {
  network,
  unauthenticated,
  notEntitled,
  notReady,
  drmUnsupported,
  licenseDenied,
  licenseExpired,
  insufficientStorage,
  canceled,
  unexpected,
}
