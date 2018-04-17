library swipe_card;

import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Swipe card widget. The card can be swiped left or right and animate accordingly.
///
/// See the helper class [CardsDeck] to manage a deck of cards.
class SwipeCard extends StatefulWidget {
  const SwipeCard({
    this.key,
    this.child,
    this.onSwipe,
    this.onAnimationDone,
    this.minDragDistanceToValidate = 100.0,
    this.minDragVelocityToValidate = 1000.0,
    this.animationDistance = 500.0,
    this.maxAnimationDuration = 500,
    this.rotateCoefficient = 1.0,
  });

  SwipeCard copyWith({
    Key key,
    Widget child,
    ValueChanged<int> onSwipe,
    VoidCallback onAnimationDone,
    double minDragValueToValidate,
    double minDragVelocityToValidate,
    double animationDistance,
    int maxAnimationDuration,
    double rotateCoefficient,
  }) {
    return new SwipeCard(
      key: key ?? this.key,
      child: child ?? this.child,
      onSwipe: onSwipe ?? this.onSwipe,
      onAnimationDone: onAnimationDone ?? this.onAnimationDone,
      minDragDistanceToValidate:
          minDragValueToValidate ?? this.minDragDistanceToValidate,
      minDragVelocityToValidate:
          minDragVelocityToValidate ?? this.minDragVelocityToValidate,
      animationDistance: animationDistance ?? this.animationDistance,
      maxAnimationDuration: maxAnimationDuration ?? this.maxAnimationDuration,
      rotateCoefficient: rotateCoefficient ?? this.rotateCoefficient,
    );
  }

  /// Assigning a key with [UniqueKey] will ensure the card is disposed properly.
  final Key key;

  /// Contain the layout of the card.
  final Widget child;

  /// Triggers when a swipe is validated (but before the swipe animation is over).
  ///
  /// Will not trigger if the swipe is canceled.
  final ValueChanged<int> onSwipe;

  /// Triggers when the animation of a swipe is over (the card should be removed then).
  final VoidCallback onAnimationDone;

  /// Minimum drag distance (in pixels) for a swipe to be considered valid.
  ///
  /// If the swipe velocity is greater than [minDragVelocityToValidate] this will be ignored.
  final double minDragDistanceToValidate;

  /// Minimum drag velocity (in pixels/s) for a swipe to be considered valid.
  ///
  /// If the swipe drag distance is greater than [minDragDistanceToValidate] this will be ignored.
  final double minDragVelocityToValidate;

  /// Distance (in pixels) the card will move during the animation (after a swipe is validated).
  final double animationDistance;

  /// Max duration (in ms) of the animation (after a swipe is validated).
  ///
  /// If the swipe is done really slowly this value can prevent the animation to be also very slow.
  /// Reducing this value increase the minimum animation speed.
  final int maxAnimationDuration;

  /// Modify the strength of the rotation.
  ///
  /// Default value is 1.
  /// 0 will disable rotation, 2 will make it twice as big, 0.5 half as big and negative value will inverse the rotation.
  final double rotateCoefficient;

  /// Return value for [onSwipe].
  static final int leftSwipe = 0;

  /// Return value for [onSwipe].
  static final int rightSwipe = 1;

  @override
  createState() => new SwipeCardState();
}

class SwipeCardState extends State<SwipeCard>
    with SingleTickerProviderStateMixin {
  bool _isDisposed = false;
  bool _isDragging = false;
  double _dragValue = 0.0;
  Animation<double> _animation;
  AnimationController _controller;

  /// This coefficient was empirically tested to look good.
  final double _empiricalRotateCoefficient = 0.001;

  initState() {
    super.initState();
    _controller = new AnimationController(vsync: this);

    _animation = new Tween(begin: 0.0, end: widget.animationDistance)
        .animate(_controller)
          ..addListener(() {
            _setStateIfValid(() {});
            if (_animation.value == widget.animationDistance) {
              if (widget.onAnimationDone != null) widget.onAnimationDone();
            }
          });
  }

  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
      onHorizontalDragStart: _handleHorizontalDragStart,
      onHorizontalDragUpdate: _handleHorizontalDragUpdate,
      onHorizontalDragEnd: _handleHorizontalDragEnd,
      child: new Transform(
        transform: _isDragging
            ? _computeManualTransformMatrix()
            : _computeAnimatedTransformMatrix(),
        child: widget.child,
//        origin: Offset.,
        alignment: Alignment.center,
      ),
    );
  }

  void _handleHorizontalDragStart(DragStartDetails details) {
    _setStateIfValid(() {
      _isDragging = true;
      _dragValue = 0.0;
    });
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    _setStateIfValid(() {
      _dragValue += details.delta.dx;
    });
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    _setStateIfValid(() {
      _isDragging = false;
    });

    _runAnimation(details.primaryVelocity);

    if (_validateSwipe(details.primaryVelocity) && widget.onSwipe != null) {
      if (_dragValue > 0.0) {
        widget.onSwipe(SwipeCard.rightSwipe);
      } else {
        widget.onSwipe(SwipeCard.leftSwipe);
      }
    }
  }

  Matrix4 _computeManualTransformMatrix() {
    return Matrix4.translationValues(_dragValue, 0.0, 0.0)
      ..rotateZ(_dragValue.abs() *
          _empiricalRotateCoefficient *
          widget.rotateCoefficient);
  }

  Matrix4 _computeAnimatedTransformMatrix() {
    return Matrix4.translationValues(
        _animation.value * _dragValue.sign, 0.0, 0.0)
      ..rotateZ(_animation.value *
          _empiricalRotateCoefficient *
          widget.rotateCoefficient);
  }

  Duration _computeAnimationDuration(final double dragVelocity) {
    int animationDuration = 500;
    // Avoid dividing by 0.
    if (dragVelocity.abs() > 1.0) {
      animationDuration = (1000.0 *
              (widget.animationDistance - _dragValue.abs()) /
              dragVelocity.abs())
          .round();
    }

    // Make sure the animation is not too slow.
    animationDuration =
        math.min(animationDuration, widget.maxAnimationDuration);

    return new Duration(milliseconds: animationDuration);
  }

  void _runAnimation(final double dragVelocity) {
    final double currentPositionInAnimation =
        _dragValue.abs() / widget.animationDistance;
    _controller.duration = _computeAnimationDuration(dragVelocity);
    if (_validateSwipe(dragVelocity)) {
      _controller.forward(from: currentPositionInAnimation);
    } else {
      _controller.reverse(from: currentPositionInAnimation);
    }
  }

  bool _validateSwipe(final double dragVelocity) {
    return _dragValue.abs() >= widget.minDragDistanceToValidate ||
        dragVelocity.abs() > widget.minDragVelocityToValidate;
  }

  void _setStateIfValid(VoidCallback callback) {
    if (mounted && !_isDisposed) {
      setState(() => callback());
    }
  }

  @override
  dispose() {
    _controller.dispose();
    _isDisposed = true;
    super.dispose();
  }
}

/// Helper class to manage a deck of [SwipeCard].
class CardsDeck {
  final List<SwipeCard> _cards = <SwipeCard>[];

  /// Returns all the cards in the deck.
  ///
  /// When building the layout it's usually enough to draw the 2 cards on the top of the deck. See [topTwoCards].
  List<SwipeCard> allCards() => _cards;

  /// Returns the 2 cards on the top of the deck.
  List<SwipeCard> topTwoCards() =>
      _cards.sublist(_cards.length - 2, _cards.length);

  /// Add a card on top of the deck (the top card is the visible one).
  addTop(SwipeCard card) {
    _cards.add(_getAutoDisposeCard(card));
  }

  /// Add a card at the bottom of the deck.
  ///
  /// Use this when adding more cards to the deck.
  addBottom(SwipeCard card) {
    _cards.insert(0, _getAutoDisposeCard(card));
  }

  /// Insert a card at the given position in the deck.
  insert(int index, SwipeCard card) {
    _cards.insert(index, _getAutoDisposeCard(card));
  }

  /// Remove the given card from the deck.
  remove(SwipeCard card) {
    _cards.remove(card);
  }

  // Add some logic to dispose of the card when it's swiped out of the deck.
  _getAutoDisposeCard(SwipeCard card) {
    SwipeCard newCard = card;
    Key key = card.key;
    if (card.key == null) {
      // Having a key ensure the card is disposed when done.
      key = new UniqueKey();
    }

    if (card.onAnimationDone != null) {
      newCard = card.copyWith(
          key: key,
          onAnimationDone: () {
            card.onAnimationDone();
            _disposeCard(newCard);
          });
    } else {
      newCard =
          card.copyWith(key: key, onAnimationDone: () => _disposeCard(newCard));
    }
    return newCard;
  }

  _disposeCard(SwipeCard card) {
    remove(card);
  }
}
