import 'package:flutter/widgets.dart';
import 'package:pao_ui/src/tokens/colors.dart';
import 'package:pao_ui/src/tokens/motion.dart';
import 'package:pao_ui/src/tokens/shape.dart';

/// One of the few shared-element moments (P27): a service icon into its page,
/// a booking card into its detail, a provider's photo into their profile, the
/// sign-in art into the code page. Off in the light motion set.
class PaoHero extends StatelessWidget {
  /// Flies [child] between routes that share [tag]. With [surface] only an
  /// empty card flies, for cards whose text differs at the two ends.
  const PaoHero({
    required this.tag,
    required this.child,
    this.surface = false,
    super.key,
  }) : vanish = false;

  /// The landing spot of a hero that only leaves: the other end's child flies
  /// here and fades out on the way (and back in when the route pops).
  const PaoHero.vanish({required this.tag, required this.child, super.key})
    : surface = false,
      vanish = true;

  /// Whether only the card surface flies.
  final bool surface;

  /// Whether the flying child fades out towards this end.
  final bool vanish;

  /// Shared by the two ends, e.g. [PaoHero.service].
  final String tag;

  /// What flies.
  final Widget child;

  /// The tag of a service's icon.
  static String service(String id) => 'service:$id';

  /// The tag of a booking's card.
  static String booking(String id) => 'booking:$id';

  /// The tag of a provider's photo.
  static String provider(String id) => 'provider:$id';

  /// The sign-in illustration.
  static const signInArt = 'sign-in-art';

  @override
  Widget build(BuildContext context) => HeroMode(
    enabled: !context.lightMotion,
    child: Hero(
      tag: tag,
      flightShuttleBuilder: surface
          ? _surface
          : vanish
          ? _fading
          : null,
      child: child,
    ),
  );

  static Widget _fading(
    BuildContext context,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext from,
    BuildContext to,
  ) {
    final leaving = direction == HeroFlightDirection.push ? from : to;
    return FadeTransition(
      opacity: ReverseAnimation(animation),
      child: (leaving.widget as Hero).child,
    );
  }

  static Widget _surface(
    BuildContext context,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext from,
    BuildContext to,
  ) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.pao.card,
      borderRadius: PaoShape.leaf,
    ),
  );
}
