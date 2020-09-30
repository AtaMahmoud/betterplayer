import 'package:better_player/src/controls/better_player_progress_colors.dart';
import 'package:better_player/src/video_player/video_player.dart';
import 'package:better_player/src/video_player/video_player_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../better_player.dart';

class BetterPlayerCupertinoVideoProgressBar extends StatefulWidget {
  BetterPlayerCupertinoVideoProgressBar(
    this.controller, {
    BetterPlayerProgressColors colors,
    this.onDragEnd,
    this.onDragStart,
    this.onDragUpdate,
  }) : colors = colors ?? BetterPlayerProgressColors();

  final VideoPlayerController controller;
  final BetterPlayerProgressColors colors;
  final Function() onDragStart;
  final Function() onDragEnd;
  final Function() onDragUpdate;

  @override
  _VideoProgressBarState createState() {
    return _VideoProgressBarState();
  }
}

class _VideoProgressBarState
    extends State<BetterPlayerCupertinoVideoProgressBar> {
  _VideoProgressBarState() {
    listener = () {
      setState(() {});
    };
  }

  VoidCallback listener;
  bool _controllerWasPlaying = false;
  bool _isSeekBack = true;

  VideoPlayerController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    try {
      controller.addListener(listener);
    } catch (error) {
      print("Error ==> $error");
    }
  }

  @override
  void deactivate() {
    try {
      controller.removeListener(listener);
    } catch (error) {
      print("Error ==> $error");
    }
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    void seekToRelativePosition(Offset globalPosition) {
      final box = context.findRenderObject() as RenderBox;
      final Offset tapPos = box.globalToLocal(globalPosition);
      final double relative = tapPos.dx / box.size.width;
      final Duration position = controller.value.duration * relative;

      controller.seekTo(position);
    }

    bool isMovingBack(Offset newPosition, Offset currentPosition) {
      final nBox = context.findRenderObject() as RenderBox;
      final Offset nTapPos = nBox.globalToLocal(newPosition);
      final double nRelative = nTapPos.dx / nBox.size.width;
      final Duration nPosition = controller.value.duration ?? 0 * nRelative;

      return nPosition.inSeconds < controller.value.position.inSeconds
          ? true
          : false;
    }

    return GestureDetector(
      child: Center(
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          color: Colors.transparent,
          child: CustomPaint(
            painter: _ProgressBarPainter(
              controller.value,
              widget.colors,
            ),
          ),
        ),
      ),
      onHorizontalDragStart: (DragStartDetails details) {
        _isSeekBack =
            isMovingBack(details.globalPosition, details.localPosition);
        if (!controller.value.initialized ||
            (!controller.value.enableSeeking && !_isSeekBack)) {
          return;
        }

        _controllerWasPlaying = controller.value.isPlaying;
        if (_controllerWasPlaying) {
          controller.pause();
        }

        if (widget.onDragStart != null) {
          widget.onDragStart();
        }
      },
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        _isSeekBack =
            isMovingBack(details.globalPosition, details.localPosition);
        if (!controller.value.initialized ||
            (!controller.value.enableSeeking && !_isSeekBack)) {
          return;
        }

        seekToRelativePosition(details.globalPosition);

        if (widget.onDragUpdate != null) {
          widget.onDragUpdate();
        }
      },
      onHorizontalDragEnd: (DragEndDetails details) {
        if (!controller.value.enableSeeking && !_isSeekBack) return;
        if (_controllerWasPlaying) {
          controller.play();
        }
        if (widget.onDragEnd != null) {
          widget.onDragEnd();
        }
      },
      onTapDown: (TapDownDetails details) {
        _isSeekBack =
            isMovingBack(details.globalPosition, details.localPosition);
        if (!controller.value.initialized ||
            (!controller.value.enableSeeking && !_isSeekBack)) {
          return;
        }

        seekToRelativePosition(details.globalPosition);
      },
    );
  }
}

class _ProgressBarPainter extends CustomPainter {
  _ProgressBarPainter(this.value, this.colors);

  VideoPlayerValue value;
  BetterPlayerProgressColors colors;

  @override
  bool shouldRepaint(CustomPainter painter) {
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final barHeight = 5.0;
    final handleHeight = 6.0;
    final baseOffset = size.height / 2 - barHeight / 2.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0.0, baseOffset),
          Offset(size.width, baseOffset + barHeight),
        ),
        Radius.circular(4.0),
      ),
      colors.backgroundPaint,
    );
    if (!value.initialized) {
      return;
    }
    final double playedPartPercent =
        value.position.inMilliseconds / value.duration.inMilliseconds;
    final double playedPart =
        playedPartPercent > 1 ? size.width : playedPartPercent * size.width;
    for (DurationRange range in value.buffered) {
      final double start = range.startFraction(value.duration) * size.width;
      final double end = range.endFraction(value.duration) * size.width;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromPoints(
            Offset(start, baseOffset),
            Offset(end, baseOffset + barHeight),
          ),
          Radius.circular(4.0),
        ),
        colors.bufferedPaint,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0.0, baseOffset),
          Offset(playedPart, baseOffset + barHeight),
        ),
        Radius.circular(4.0),
      ),
      colors.playedPaint,
    );

    final shadowPath = Path()
      ..addOval(Rect.fromCircle(
          center: Offset(playedPart, baseOffset + barHeight / 2),
          radius: handleHeight));

    canvas.drawShadow(shadowPath, Colors.black, 0.2, false);
    canvas.drawCircle(
      Offset(playedPart, baseOffset + barHeight / 2),
      handleHeight,
      colors.handlePaint,
    );
  }
}
