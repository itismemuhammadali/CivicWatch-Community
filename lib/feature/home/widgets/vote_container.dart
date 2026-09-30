import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class VotingResultExample extends StatelessWidget {
  final String leftLabel;
  final String leftText;
  final String rightLabel;
  final String rightText;
  final VoidCallback? onLeftTap;
  final VoidCallback? onRightTap;
  final bool isSubmitting;
  final String? selectedOption;
  final int leftVotes;
  final int rightVotes;
  final int? totalVotesCount;
  final bool isPollEnded;

  const VotingResultExample({
    super.key,
    this.leftLabel = 'A.',
    this.leftText = 'Dennis Callis',
    this.rightLabel = 'B.',
    this.rightText = 'Katie Sims',
    this.onLeftTap,
    this.onRightTap,
    this.isSubmitting = false,
    this.selectedOption,
    this.leftVotes = 0,
    this.rightVotes = 0,
    this.totalVotesCount,
    this.isPollEnded = false,
  });

  @override
  Widget build(BuildContext context) {
    final apiTotalVotes = totalVotesCount ?? 0;
    final calculatedTotalVotes = leftVotes + rightVotes;
    final totalVotes = apiTotalVotes > 0 ? apiTotalVotes : calculatedTotalVotes;
    final leftProgress = totalVotes == 0 ? 0.0 : leftVotes / totalVotes;
    final rightProgress = totalVotes == 0 ? 0.0 : rightVotes / totalVotes;
    final leftPercentage = _buildPercentage(leftVotes, totalVotes);
    final rightPercentage = _buildPercentage(rightVotes, totalVotes);

    final hasWinner = leftVotes != rightVotes;
    final isLeftWinner = leftVotes > rightVotes;
    final isRightWinner = rightVotes > leftVotes;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _buildVoteOption(
            label: leftLabel,
            text: leftText,
            progress: leftProgress,
            percentage: leftPercentage,
            isSelected: selectedOption == 'owner',
            isWinner: isLeftWinner,
            isLosing: isPollEnded && hasWinner && !isLeftWinner,
            isPollEnded: isPollEnded,
            onTap: onLeftTap,
          ),
        ),
        SizedBox(width: 1.w),
        Expanded(
          child: _buildVoteOption(
            label: rightLabel,
            text: rightText,
            progress: rightProgress,
            percentage: rightPercentage,
            isSelected: selectedOption == 'defendant',
            isWinner: isRightWinner,
            isLosing: isPollEnded && hasWinner && !isRightWinner,
            isPollEnded: isPollEnded,
            onTap: onRightTap,
          ),
        ),
      ],
    );
  }

  int _buildPercentage(int votes, int totalVotes) {
    if (totalVotes <= 0) return 0;
    return ((votes / totalVotes) * 100).round().clamp(0, 100);
  }

  Widget _buildVoteOption({
    required String label,
    required String text,
    required double progress,
    required int percentage,
    required bool isSelected,
    required bool isWinner,
    required bool isLosing,
    required bool isPollEnded,
    required VoidCallback? onTap,
  }) {
    final hasVotes = percentage > 0;
    final fillColor = isSelected
        ? const Color(0xFF007BFF)
        : (isPollEnded && isWinner)
        ? const Color(0xFF007BFF).withValues(alpha: 0.85)
        : isWinner
        ? const Color(0xFF007BFF).withValues(alpha: 0.72)
        : const Color(0xFF007BFF).withValues(alpha: isLosing ? 0.10 : 0.22);

    final borderColor = (isPollEnded && isWinner)
        ? Colors.amber.shade700
        : (isSelected || isWinner
            ? const Color(0xFF007BFF)
            : (isLosing ? Colors.black12 : Colors.black26));

    final labelColor = isSelected ? Colors.white : (isLosing ? Colors.black54 : Colors.black87);
    final textColor = isSelected ? Colors.white : (isLosing ? Colors.black54 : Colors.black87);

    return GestureDetector(
      onTap: isSubmitting ? null : onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fillWidth = constraints.maxWidth * progress;

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: borderColor,
                width: (isPollEnded && isWinner) ? 2.2 : 1.5,
              ),
              boxShadow: (isPollEnded && isWinner)
                  ? [
                      BoxShadow(
                        color: Colors.amber.shade400.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Positioned.fill(child: Container(color: Colors.white)),
                  if (fillWidth > 0)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: fillWidth,
                      child: Container(color: fillColor),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: labelColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          ),
                        ] else if (isSubmitting && isSelected) ...[
                          const SizedBox(width: 6),
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        ],
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            text,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: (isPollEnded && isWinner)
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isPollEnded && isWinner) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade700,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '👑 WINNER',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ] else if (hasVotes || isPollEnded) ...[
                          const SizedBox(width: 4),
                          Text(
                            '$percentage%',
                            style: TextStyle(
                              color: labelColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
