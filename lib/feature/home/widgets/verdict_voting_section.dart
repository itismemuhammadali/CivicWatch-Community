import 'dart:math';
import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/firebase/firestore_service.dart';
import 'package:cctv_app/core/network/models/active_post.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/feature/home/widgets/vote_container.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

class VerdictVotingSection extends StatefulWidget {
  final ActivePost post;
  final String ownerName;
  final String defendantName;
  final String? selectedVote;
  final bool isSubmittingVote;
  final bool isFollowerOfCreator;
  final bool isCheckingFollowerStatus;
  final Future<void> Function(BuildContext, {required ActivePost post, required String selectedVote, required String selectedName}) onVote;

  const VerdictVotingSection({
    super.key,
    required this.post,
    required this.ownerName,
    required this.defendantName,
    required this.selectedVote,
    required this.isSubmittingVote,
    required this.isFollowerOfCreator,
    required this.isCheckingFollowerStatus,
    required this.onVote,
  });

  @override
  State<VerdictVotingSection> createState() => _VerdictVotingSectionState();
}

class _VerdictVotingSectionState extends State<VerdictVotingSection> {
  late ConfettiController _confettiController;
  bool _hasTriggeredNotification = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVerdict();
    });
  }

  @override
  void didUpdateWidget(covariant VerdictVotingSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkVerdict();
  }

  void _checkVerdict() {
    final pollEndDateString = widget.post.casePollCount?.pollEndDate;
    final pollEndDate = pollEndDateString != null ? DateTime.tryParse(pollEndDateString) : null;
    final isPollEnded = pollEndDate != null && DateTime.now().toUtc().isAfter(pollEndDate.toUtc());

    if (isPollEnded) {
      final ownerVotes = widget.post.casePollCount?.ownerCount ?? 0;
      final defVotes = widget.post.casePollCount?.defendantCount ?? 0;
      final totalVotes = widget.post.casePollCount?.totalCount ?? (ownerVotes + defVotes);

      final hasWinner = ownerVotes != defVotes;
      if (hasWinner) {
        _confettiController.play();
      }

      if (!_hasTriggeredNotification) {
        _hasTriggeredNotification = true;
        final isTie = ownerVotes == defVotes;
        final winnerName = ownerVotes > defVotes ? widget.ownerName : widget.defendantName;
        final winnerVotes = ownerVotes > defVotes ? ownerVotes : defVotes;
        final winnerPct = totalVotes > 0 ? ((winnerVotes / totalVotes) * 100).round() : 50;

        int? defId;
        final defDetails = widget.post.defendantDetails;
        if (defDetails.isNotEmpty) {
          defId = defDetails.first.defendentId;
        }

        FirestoreDataService().checkAndDeliverVerdictNotification(
          caseId: widget.post.postId,
          postTitle: widget.post.caseDetail?.caseTitle ?? widget.post.postDescription,
          creatorId: widget.post.createdBy ?? 0,
          defendantId: defId,
          winnerName: isTie ? 'Tie' : winnerName,
          winnerPercentage: winnerPct,
          isTie: isTie,
        );
      }
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pollEndDateString = widget.post.casePollCount?.pollEndDate;
    final pollEndDate = pollEndDateString != null ? DateTime.tryParse(pollEndDateString) : null;
    final isPollEnded = pollEndDate != null && DateTime.now().toUtc().isAfter(pollEndDate.toUtc());
    final bool isJuryGated = widget.post.caseDetail?.isJuryPost == true && !widget.isFollowerOfCreator;

    final ownerVotes = widget.post.casePollCount?.ownerCount ?? 0;
    final defVotes = widget.post.casePollCount?.defendantCount ?? 0;
    final totalVotes = widget.post.casePollCount?.totalCount ?? (ownerVotes + defVotes);

    final isOwnerWinner = ownerVotes > defVotes;
    final isDefWinner = defVotes > ownerVotes;
    final isTie = ownerVotes == defVotes && totalVotes > 0;
    final hasNoVotes = totalVotes == 0;

    String? countdownText;
    if (pollEndDate != null && !isPollEnded) {
      final diff = pollEndDate.toUtc().difference(DateTime.now().toUtc());
      if (diff.inDays > 0) {
        countdownText = '${diff.inDays} days left';
      } else if (diff.inHours > 0) {
        countdownText = '${diff.inHours} hours left';
      } else if (diff.inMinutes > 0) {
        countdownText = '${diff.inMinutes} mins left';
      } else {
        countdownText = 'Ending soon';
      }
    }

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isPollEnded) ...[
              // 🏆 Prominent Verdict Banner
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.shade50,
                      Colors.orange.shade50,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade400, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.shade200.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade600,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emoji_events,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "OFFICIAL VERDICT",
                                style: context.bold.copyWith(
                                  fontSize: 10,
                                  color: Colors.amber.shade900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade600,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  "Poll Closed",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          if (isOwnerWinner) ...[
                            Text(
                              "🏆 Winner: ${widget.ownerName} (${((ownerVotes / totalVotes) * 100).round()}% of votes)",
                              style: context.bold.copyWith(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ] else if (isDefWinner) ...[
                            Text(
                              "🏆 Winner: ${widget.defendantName} (${((defVotes / totalVotes) * 100).round()}% of votes)",
                              style: context.bold.copyWith(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ] else if (isTie) ...[
                            Text(
                              "⚖️ Split Decision: It's a Tie (50% - 50%)",
                              style: context.bold.copyWith(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ] else if (hasNoVotes) ...[
                            Text(
                              "⚖️ Closed without votes",
                              style: context.bold.copyWith(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (countdownText != null) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kPrimaryColor, width: 1),
                      ),
                      child: Text(
                        countdownText,
                        style: context.semiBold.copyWith(
                          fontSize: 12,
                          color: kPrimaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (widget.isCheckingFollowerStatus)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else
              VotingResultExample(
                leftLabel: 'A.',
                leftText: widget.ownerName,
                rightLabel: 'B.',
                rightText: widget.defendantName,
                leftVotes: ownerVotes,
                rightVotes: defVotes,
                totalVotesCount: totalVotes,
                selectedOption: widget.selectedVote,
                isSubmitting: widget.isSubmittingVote,
                isPollEnded: isPollEnded,
                onLeftTap: (isPollEnded || isJuryGated)
                    ? null
                    : () => widget.onVote(
                          context,
                          post: widget.post,
                          selectedVote: 'owner',
                          selectedName: widget.ownerName,
                        ),
                onRightTap: (isPollEnded || isJuryGated)
                    ? null
                    : () => widget.onVote(
                          context,
                          post: widget.post,
                          selectedVote: 'defendant',
                          selectedName: widget.defendantName,
                        ),
              ),
          ],
        ),
        // Confetti burst on winner
        Align(
          alignment: isOwnerWinner
              ? Alignment.topLeft
              : (isDefWinner ? Alignment.topRight : Alignment.topCenter),
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: isOwnerWinner ? -pi / 4 : (isDefWinner ? -3 * pi / 4 : -pi / 2),
            blastDirectionality: BlastDirectionality.directional,
            emissionFrequency: 0.08,
            numberOfParticles: 20,
            gravity: 0.25,
            colors: const [
              Colors.amber,
              Colors.orange,
              Colors.blue,
              Colors.green,
              Colors.pink,
            ],
          ),
        ),
      ],
    );
  }
}
