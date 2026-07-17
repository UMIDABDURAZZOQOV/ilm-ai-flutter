class SubscriptionStatus {
  final bool isPremium;
  final String? tier;
  final String? expiresAt;
  final String? plan;

  SubscriptionStatus({required this.isPremium, this.tier, this.expiresAt, this.plan});

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) => SubscriptionStatus(
        isPremium: json['is_premium'] as bool? ?? false,
        tier: json['tier'] as String?,
        expiresAt: json['expires_at'] as String?,
        plan: json['plan'] as String?,
      );

  static SubscriptionStatus free() => SubscriptionStatus(isPremium: false, tier: 'free');
}

class CheckoutResponse {
  final String checkoutUrl;
  final String sessionId;
  final bool? ok;

  CheckoutResponse({required this.checkoutUrl, required this.sessionId, this.ok});

  factory CheckoutResponse.fromJson(Map<String, dynamic> json) => CheckoutResponse(
        checkoutUrl: json['checkout_url'] as String? ?? '',
        sessionId: json['session_id'] as String? ?? '',
        ok: json['ok'] as bool?,
      );
}
