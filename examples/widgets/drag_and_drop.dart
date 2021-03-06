// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

class ExampleDragTarget extends StatefulComponent {
  ExampleDragTargetState createState() => new ExampleDragTargetState();
}

class ExampleDragTargetState extends State<ExampleDragTarget> {
  Color _color = Colors.grey[500];

  void _handleAccept(Color data) {
    setState(() {
      _color = data;
    });
  }

  Widget build(BuildContext context) {
    return new DragTarget<Color>(
      onAccept: _handleAccept,
      builder: (BuildContext context, List<Color> data, List<Color> rejectedData) {
        return new Container(
          height: 100.0,
          margin: new EdgeDims.all(10.0),
          decoration: new BoxDecoration(
            border: new Border.all(
              width: 3.0,
              color: data.isEmpty ? Colors.white : Colors.blue[500]
            ),
            backgroundColor: data.isEmpty ? _color : Colors.grey[200]
          )
        );
      }
    );
  }
}

class Dot extends StatelessComponent {
  Dot({ Key key, this.color, this.size, this.child }) : super(key: key);
  final Color color;
  final double size;
  final Widget child;
  Widget build(BuildContext context) {
    return new Container(
      width: size,
      height: size,
      decoration: new BoxDecoration(
        backgroundColor: color,
        shape: BoxShape.circle
      ),
      child: child
    );
  }
}

class ExampleDragSource extends StatelessComponent {
  ExampleDragSource({
    Key key,
    this.color,
    this.heavy: false,
    this.under: true,
    this.child
  }) : super(key: key);

  final Color color;
  final bool heavy;
  final bool under;
  final Widget child;

  static const double kDotSize = 50.0;
  static const double kHeavyMultiplier = 1.5;
  static const double kFingerSize = 50.0;

  Widget build(BuildContext context) {
    double size = kDotSize;
    if (heavy)
      size *= kHeavyMultiplier;

    Widget contents = new DefaultTextStyle(
      style: Theme.of(context).text.body1.copyWith(textAlign: TextAlign.center),
      child: new Dot(
        color: color,
        size: size,
        child: new Center(child: child)
      )
    );

    Widget feedback = new Opacity(
      opacity: 0.75,
      child: contents
    );

    Offset feedbackOffset;
    DragAnchor anchor;
    if (!under) {
      feedback = new Transform(
        transform: new Matrix4.identity()
                     ..translate(-size / 2.0, -(size / 2.0 + kFingerSize)),
        child: feedback
      );
      feedbackOffset = const Offset(0.0, -kFingerSize);
      anchor = DragAnchor.pointer;
    } else {
      feedbackOffset = Offset.zero;
      anchor = DragAnchor.child;
    }

    if (heavy) {
      return new LongPressDraggable<Color>(
        data: color,
        child: contents,
        feedback: feedback,
        feedbackOffset: feedbackOffset,
        dragAnchor: anchor
      );
    } else {
      return new Draggable<Color>(
        data: color,
        child: contents,
        feedback: feedback,
        feedbackOffset: feedbackOffset,
        dragAnchor: anchor
      );
    }
  }
}

class DashOutlineCirclePainter extends CustomPainter {
  const DashOutlineCirclePainter();

  static const int segments = 17;
  static const double deltaTheta = math.PI * 2 / segments; // radians
  static const double segmentArc = deltaTheta / 2.0; // radians
  static const double startOffset = 1.0; // radians

  void paint(Canvas canvas, Size size) {
    final double radius = size.shortestSide / 2.0;
    final Paint paint = new Paint()
      ..color = const Color(0xFF000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius / 10.0;
    final Path path = new Path();
    final Rect box = Point.origin & size;
    for (double theta = 0.0; theta < math.PI * 2.0; theta += deltaTheta)
      path.addArc(box, theta + startOffset, segmentArc);
    canvas.drawPath(path, paint);
  }

  bool shouldRepaint(DashOutlineCirclePainter oldPainter) => false;
}

class MovableBall extends StatelessComponent {
  MovableBall(this.position, this.ballPosition, this.callback);
  final int position;
  final int ballPosition;
  final ValueChanged<int> callback;
  static const double kBallSize = 50.0;
  Widget build(BuildContext context) {
    Widget ball = new DefaultTextStyle(
      style: Theme.of(context).text.body1.copyWith(
        textAlign: TextAlign.center,
        color: Colors.white
      ),
      child: new Dot(
        color: Colors.blue[700],
        size: kBallSize,
        child: new Center(child: new Text('BALL'))
      )
    );
    Widget dashedBall = new Container(
      width: kBallSize,
      height: kBallSize,
      child: new CustomPaint(
        painter: const DashOutlineCirclePainter()
      )
    );
    if (position == ballPosition) {
      return new Draggable<bool>(
        data: true,
        child: ball,
        childWhenDragging: dashedBall,
        feedback: ball,
        maxSimultaneousDrags: 1
      );
    } else {
      return new DragTarget<bool>(
        onAccept: (bool data) { callback(position); },
        builder: (BuildContext context, List<bool> accepted, List<bool> rejected) {
          return dashedBall;
        }
      );
    }
  }
}

class DragAndDropApp extends StatefulComponent {
  DragAndDropAppState createState() => new DragAndDropAppState();
}

class DragAndDropAppState extends State<DragAndDropApp> {
  int position = 1;
  void moveBall(int newPosition) {
    setState(() { position = newPosition; });
  }
  Widget build(BuildContext context) {
    return new Scaffold(
      toolBar: new ToolBar(
        center: new Text('Drag and Drop Flutter Demo')
      ),
      body: new Column(
        children: <Widget>[
          new Flexible(
            child: new Row(
              children: <Widget>[
                new ExampleDragSource(
                  color: Colors.yellow[300],
                  under: true,
                  heavy: false,
                  child: new Text('under')
                ),
                new ExampleDragSource(
                  color: Colors.green[300],
                  under: false,
                  heavy: true,
                  child: new Text('long-press above')
                ),
                new ExampleDragSource(
                  color: Colors.indigo[300],
                  under: false,
                  heavy: false,
                  child: new Text('above')
                ),
              ],
              alignItems: FlexAlignItems.center,
              justifyContent: FlexJustifyContent.spaceAround
            )
          ),
          new Flexible(
            child: new Row(
              children: <Widget>[
                new Flexible(child: new ExampleDragTarget()),
                new Flexible(child: new ExampleDragTarget()),
                new Flexible(child: new ExampleDragTarget()),
                new Flexible(child: new ExampleDragTarget()),
              ]
            )
          ),
          new Flexible(
            child: new Row(
              children: <Widget>[
                new MovableBall(1, position, moveBall),
                new MovableBall(2, position, moveBall),
                new MovableBall(3, position, moveBall),
              ],
              justifyContent: FlexJustifyContent.spaceAround
            )
          ),
        ]
      )
    );
  }
}

void main() {
  runApp(new MaterialApp(
    title: 'Drag and Drop Flutter Demo',
    routes: <String, RouteBuilder>{
     '/': (RouteArguments args) => new DragAndDropApp()
    }
  ));
}
