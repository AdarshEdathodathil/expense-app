enum HouseholdRole { owner, member }

class Household {
  const Household({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.defaultCurrency,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String ownerId;
  final String defaultCurrency;
  final DateTime createdAt;
}

class HouseholdMember {
  const HouseholdMember({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.role,
    required this.joinedAt,
  });

  final String userId;
  final String displayName;
  final String email;
  final HouseholdRole role;
  final DateTime joinedAt;
}

class HouseholdInvitation {
  const HouseholdInvitation({
    required this.code,
    required this.householdId,
    required this.invitedEmail,
    required this.expiresAt,
  });

  final String code;
  final String householdId;
  final String invitedEmail;
  final DateTime expiresAt;
}
