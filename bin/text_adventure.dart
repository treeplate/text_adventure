import 'dart:io';

import 'package:text_adventure/command_parser.dart';
import 'package:text_adventure/text_adventure.dart';

void main(List<String> arguments) {
  print("You are Charles.");
  Set<Atom> atoms = createWorld(print);
  List<String>? commands;
  if (arguments.isNotEmpty) {
    if (arguments[0] == '-if') {
      commands = File(arguments[1]).readAsLinesSync();
    } else {
      throw UnsupportedError('argument ${arguments[0]}');
    }
  }
  int i = 0;
  while (true) {
    stdout.write('> ');
    String rawCommand;
    if (commands == null) {
      rawCommand = stdin.readLineSync()!;
    } else {
      if (commands.length > i) {
        rawCommand = commands[i];
        print(rawCommand);
      } else {
        throw exit(0);
      }
    }
    Person player = atoms.whereType<Person>().single;
    Command? command = parseCommand(atoms, player, rawCommand, stdout.write);
    i++;
    if (command == null) continue;
    player.handleCommand(command, stdout.write);
  }
}