part of 'text_adventure.dart';

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
    (1, 0, 0),
  );
  loc._surfaces[Direction.west] = Surface._(loc2, loc);
  loc2._surfaces[Direction.east] = loc._surfaces[Direction.west]!;

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
    ...loc._surfaces.values,
    loc2,
    ...loc2._surfaces.values,
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
        loc2._surfaces[Direction.east]!),
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
