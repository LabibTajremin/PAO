//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/account.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'token_pair.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TokenPair {
  /// Returns a new [TokenPair] instance.
  TokenPair({
    required this.accessToken,

    this.refreshToken,

    required this.expiresInSeconds,

    this.isNewAccount,

    required this.account,
  });

  @JsonKey(name: r'accessToken', required: true, includeIfNull: false)
  final String accessToken;

  /// Omitted for the admin web app, which receives it as an HttpOnly cookie.
  @JsonKey(name: r'refreshToken', required: false, includeIfNull: false)
  final String? refreshToken;

  @JsonKey(name: r'expiresInSeconds', required: true, includeIfNull: false)
  final int expiresInSeconds;

  @JsonKey(name: r'isNewAccount', required: false, includeIfNull: false)
  final bool? isNewAccount;

  @JsonKey(name: r'account', required: true, includeIfNull: false)
  final Account account;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TokenPair &&
            runtimeType == other.runtimeType &&
            equals(
              [
                accessToken,
                refreshToken,
                expiresInSeconds,
                isNewAccount,
                account,
              ],
              [
                other.accessToken,
                other.refreshToken,
                other.expiresInSeconds,
                other.isNewAccount,
                other.account,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        accessToken,
        refreshToken,
        expiresInSeconds,
        isNewAccount,
        account,
      ]);

  factory TokenPair.fromJson(Map<String, dynamic> json) =>
      _$TokenPairFromJson(json);

  Map<String, dynamic> toJson() => _$TokenPairToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
