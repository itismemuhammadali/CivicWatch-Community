class FollowStats {
  final int followersCount;
  final int followingCount;
  final bool isFollowingCurrent;

  const FollowStats({
    required this.followersCount,
    required this.followingCount,
    required this.isFollowingCurrent,
  });

  factory FollowStats.empty() {
    return const FollowStats(
      followersCount: 0,
      followingCount: 0,
      isFollowingCurrent: false,
    );
  }
}
