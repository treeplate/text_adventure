part of 'text_adventure.dart';

void connectRooms(Thing roomA, Thing roomB, Direction aToBDir, Direction bToADir) {
  ConnectedSurface aToB = ConnectedSurface._(roomA);
  ConnectedSurface bToA = ConnectedSurface._(roomB);
  aToB._otherSide = bToA;
  bToA._otherSide = aToB;
  roomA._surfaces[aToBDir] = (aToB, bToA);
  roomB._surfaces[bToADir] = (bToA, aToB);
}

Set<Atom> createWorld(void Function(Object?) print) {
  Container loc = Container._(
    null,
    RelativePosition.inParent,
    print,
    100,
    'the bedroom',
    RegExp(caseSensitive: false, '^(the )?(bed)?room\$'),
    'This is a mostly boring room.',
    false,
    false,
  );
  Container loc2 = Container._(
    null,
    RelativePosition.inParent,
    print,
    100,
    'the bedroom2',
    RegExp(caseSensitive: false, '^(the )?(bed)?room2\$'),
    'This is a mostly boring room.',
    false,
    false,
    (1, 0, 0),
  );
  connectRooms(loc, loc2, Direction.west, Direction.east);

  Person player =
      Person._(loc.ground, RelativePosition.onParent, print, 'Charles');
  Container container = Container._(
        loc.ground,
        RelativePosition.onParent,
        print,
        10,
        'box 2',
        RegExp(caseSensitive: false, '^(box|2|box 2)\$'),
        'This is a box. It has a 2 on it.',
      );
  Set<Atom> atoms = {
    loc,
    ...loc._surfaces.values.expand((e) => [e.$1, e.$2]),
    loc2,
    ...loc2._surfaces.values.expand((e) => [e.$1, e.$2]),
    player,
    Container._(
      loc.ground,
      RelativePosition.onParent,
      print,
      10,
      'box 1',
      RegExp(caseSensitive: false, '^(box|1|box 1)\$'),
      'This is a box. It has a 1 on it.',
    ),
    Button._(loc.ground, RelativePosition.onParent, print,
        loc2._surfaces[Direction.east]!.$1 as ConnectedSurface),
    Backpack._(
      container.ground,
      RelativePosition.onParent,
      print,
      10,
      'the backpack',
      RegExp(caseSensitive: false, '^(back)?pack\$'),
      'This is a backpack.',
    )
  };
  atoms.add((atoms.last as Thing)._parent!);
  return atoms;
}
