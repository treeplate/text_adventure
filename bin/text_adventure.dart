// remove the ignore when https://github.com/dart-lang/sdk/issues/52951 is fixed
// ignore_for_file: undefined_identifier, undefined_class, undefined_function, non_type_as_type_argument, cast_to_non_type
part of '../lib/text_adventure.dart';

void main(List<String> arguments) async {
  print("You are Charles.");
  Location loc = Location._(
      'the bedroom',
      RegExp(caseSensitive: false, '^(the )?(bed)?room\$'),
      'This is an empty room.');
  Person player = Person._(loc.ground, RelativePosition.onParent, 'Charles');
  List<Atom> atoms = [
    loc,
    player,
    Container._(
      loc.ground,
      RelativePosition.onParent,
      10,
      true,
      'box 1',
      RegExp(caseSensitive: false, '^(box|1|box 1)\$'),
    ),
    Container._(
      loc.ground,
      RelativePosition.onParent,
      10,
      true,
      'box 2',
      RegExp(caseSensitive: false, '^(box|2|box 2)\$'),
    ),
    Backpack._(
      Container._(
        loc.ground,
        RelativePosition.onParent,
        10,
        true,
        'box 3',
        RegExp(caseSensitive: false, '^(box|3|box 3)\$'),
      ),
      RelativePosition.inParent,
      10,
      'backpack',
      RegExp(caseSensitive: false, '^(back)?pack\$'),
    )
  ];
  atoms.add((atoms.last as Thing)._parent);

  while (true) {
    stdout.write('> ');
    String rawCommand = stdin.readLineSync()!;
    Command? command = parseCommand(atoms, player, rawCommand, stdout.write);
    if (command == null) continue;
    player.handleCommand(command, stdout.write);
  }
}
