import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/theme/gimmy_tokens.dart';
import '../../../core/theme/motion.dart';
import '../../../core/theme/tokens.dart';
import '../../../data/exercises/exercise_demos.dart';
import '../../../data/models/plan_step.dart';
import '../bloc/execution_bloc.dart';
import 'step_stage.dart';

/// Resolves the demo of [step] once, and builds with it — or with null
/// while it loads, and when there is none to show.
///
/// Key it by step, so a new step asks for its own demo.
class StepDemoLoader extends StatefulWidget {
  const StepDemoLoader({super.key, required this.step, required this.builder});

  final PlanStep step;
  final Widget Function(BuildContext context, ImageProvider? demo) builder;

  @override
  State<StepDemoLoader> createState() => _StepDemoLoaderState();
}

class _StepDemoLoaderState extends State<StepDemoLoader> {
  Future<ImageProvider?>? _demo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = widget.step.exerciseId;
    if (_demo != null || id == null) return;

    // A GIF loops for as long as it is on screen; under reduced motion the
    // still stands in for it.
    _demo = context.read<ExerciseDemos>().demoFor(
      id,
      still: GimmyMotion.isReduced(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final demo = _demo;
    if (demo == null) return widget.builder(context, null);

    return FutureBuilder(
      future: demo,
      builder: (context, snapshot) => widget.builder(context, snapshot.data),
    );
  }
}

/// The dial, and when the step has a demo, the demo one swipe to the left.
///
/// Key it by step: each step opens on its dial, since the clock is what
/// matters as a step starts. Without a demo — none chosen, or never
/// downloaded — this is exactly the [StepDial].
class StepDemoPager extends StatefulWidget {
  const StepDemoPager({
    super.key,
    required this.state,
    required this.step,
    required this.diameter,
  });

  final ExecutionState state;
  final PlanStep step;
  final double diameter;

  /// The page dots under the pages, a tap target in their own right.
  static const double dotsHeight = GimmyLayout.minTapTarget;

  @override
  State<StepDemoPager> createState() => _StepDemoPagerState();
}

class _StepDemoPagerState extends State<StepDemoPager> {
  final _pages = PageController();
  var _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _toggle() {
    final target = _page == 0 ? 1 : 0;
    if (GimmyMotion.isReduced(context)) {
      _pages.jumpToPage(target);
    } else {
      _pages.animateToPage(
        target,
        duration: GimmyMotion.stateChange,
        curve: GimmyMotion.enter,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dial = StepDial(
      state: widget.state,
      step: widget.step,
      diameter: widget.diameter,
    );

    return StepDemoLoader(
      step: widget.step,
      builder: (context, image) {
        if (image == null) return dial;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // A fixed height: the stage measures itself intrinsically, and a
            // PageView cannot answer that on its own.
            SizedBox(
              height: widget.diameter,
              child: PageView(
                controller: _pages,
                onPageChanged: (page) => setState(() => _page = page),
                children: [
                  Center(child: dial),
                  Center(
                    child: StepDemoFace(
                      image: image,
                      readout: stepReadout(widget.state, widget.step),
                      stepName: widget.step.name,
                      size: widget.diameter,
                    ),
                  ),
                ],
              ),
            ),
            _PageDots(isOnDemo: _page == 1, onTap: _toggle),
          ],
        );
      },
    );
  }
}

/// The demo in a [size] square, with the credit the media requires.
///
/// [readout] repeats the dial's figure under it where the dial is out of
/// sight; null where the dial stands beside it.
class StepDemoFace extends StatelessWidget {
  const StepDemoFace({
    super.key,
    required this.image,
    required this.stepName,
    required this.size,
    this.readout,
  });

  final ImageProvider image;
  final String? readout;
  final String stepName;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    return SizedBox.square(
      dimension: size,
      child: Column(
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: GimmyRadii.card,
                child: Image(
                  image: image,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  // The media is 180px; smooth it when scaled up.
                  filterQuality: FilterQuality.medium,
                  semanticLabel: 'How to do $stepName',
                ),
              ),
            ),
          ),
          const SizedBox(height: GimmySpacing.xs),
          if (readout case final readout?)
            Text(
              readout,
              style: tokens.metricLg.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          Text(
            'Demo ${AppConfig.exerciseMediaCredit}',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: tokens.labelMono.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Two dots saying which page is up. Tapping them turns the page, so the
/// swipe is never the only way to the demo.
class _PageDots extends StatelessWidget {
  const _PageDots({required this.isOnDemo, required this.onTap});

  final bool isOnDemo;
  final VoidCallback onTap;

  static const double _dot = GimmySpacing.sm;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget dot({required bool isCurrent}) => Container(
      width: _dot,
      height: _dot,
      margin: const EdgeInsets.symmetric(horizontal: GimmySpacing.xs),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCurrent ? scheme.primary : scheme.outlineVariant,
      ),
    );

    return Semantics(
      button: true,
      label: isOnDemo ? 'Show timer' : 'Show exercise demo',
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        child: SizedBox(
          height: StepDemoPager.dotsHeight,
          width: StepDemoPager.dotsHeight * 2,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              dot(isCurrent: !isOnDemo),
              dot(isCurrent: isOnDemo),
            ],
          ),
        ),
      ),
    );
  }
}
