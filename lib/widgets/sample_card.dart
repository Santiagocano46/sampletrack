
import 'package:flutter/material.dart';

import '../models/sample.dart';
import '../models/sample_event.dart';
import '../services/sample_logic.dart';
import 'delay_indicator.dart';

class SampleCard extends StatelessWidget {
  const SampleCard({
    super.key,
    required this.sample,
    required this.onTap,
    this.events = const [],
    this.currentTime,
  });

  final Sample sample;
  final VoidCallback onTap;
  final List<SampleEvent> events;
  final DateTime? currentTime;

  @override
  Widget build(BuildContext context) {
    final currentState = SampleLogic.getCurrentState(events);

    final isDelayed = SampleLogic.isDelayed(
      events: events,
      priority: sample.priority,
      now: currentTime,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.science_outlined,
                  color: Theme.of(context)
                      .colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sample.id,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(sample.type),
                    const SizedBox(height: 3),
                    Text(
                      sample.origin,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _PriorityChip(priority: sample.priority),
                  const SizedBox(height: 8),
                  if (isDelayed) ...[
                    const DelayIndicator(),
                    const SizedBox(height: 8),
                  ],
                  _StatusChip(status: currentState),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.priority});

  final String priority;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        priority,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context)
              .colorScheme
              .onSecondaryContainer,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}
