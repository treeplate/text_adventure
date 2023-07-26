import 'dart:io';

import 'package:text_adventure/word_iterator.dart';

import 'text_adventure.dart';

Command? parseCommand(
    Person person, String command, void Function(Object) print) {
  WordIterator iterator = WordIterator(command);
  switch (iterator.getWord()) {
    case 'l':
    case 'look':
    case 'look/l':
      if (!iterator.complete) {
        switch (iterator.getWord()) {
          case 'at':
            if (iterator.complete) {
              print('"look" syntax: look/l [at <something>]\n');
              return null;
            }
            String targetName = iterator.getRemainder();
            Atom? target = findAtom(targetName, print, person);
            if (target == null) return null;
            return LookAtCommand(target);
          case '[at':
            print('The square brackets mean "optional"!\n');
            return null;
          case 'debug':
            for (Atom atom in person.accessibleAtoms) {
              print(atom);
              print(' (');
              atom.printPosition(print, false);
              print(')\n');
            }
            return null;
          default:
            print('"look" syntax: look/l [at <something>]\n');
            return null;
        }
      } else {
        return LookCommand();
      }
    case 'take':
    case 't':
    case 'take/t':
      if (iterator.complete) {
        print('"take" syntax: take/t <something>\n');
        return null;
      }
      String targetName = iterator.getRemainder();
      Atom? target = findAtom(targetName, print, person);
      if (target == null) return null;
      return TakeCommand(target);
    case 'drop':
      if (iterator.complete) {
        print('"drop" syntax: drop <something>\n');
        return null;
      }
      String targetName = iterator.getRemainder();
      Atom? target = findAtom(targetName, print, person);
      if (target == null) return null;
      return DropCommand(target);
    case 'climb':
      if (iterator.complete) {
        print('"climb" syntax: climb <something>\n');
        return null;
      }
      String targetName = iterator.getRemainder();
      Atom? target = findAtom(targetName, print, person);
      if (target == null) return null;
      return ClimbCommand(target);
    case 'enter':
      if (iterator.complete) {
        print('"enter" syntax: enter <something>\n');
        return null;
      }
      String targetName = iterator.getRemainder();
      Atom? target = findAtom(targetName, print, person);
      if (target == null) return null;
      return EnterCommand(target);
    case 'open':
    case 'o':
    case 'open/o':
      if (iterator.complete) {
        print('"open" syntax: open/o <something>\n');
        return null;
      }
      String targetName = iterator.getRemainder();
      Atom? target = findAtom(targetName, print, person);
      if (target == null) return null;
      return OpenCommand(target);
    case 'close':
      if (iterator.complete) {
        print('"close" syntax: close <something>\n');
        return null;
      }
      String targetName = iterator.getRemainder();
      Atom? target = findAtom(targetName, print, person);
      if (target == null) return null;
      return CloseCommand(target);
    case 'put':
    case 'p':
    case 'p/put':
      if (iterator.complete) {
        print('"put" syntax: put/p <something> in/on <something>\n');
        return null;
      }
      String targetName = iterator.getUntilKeywords(['in', 'on', 'in/on']);
      Atom? src = findAtom(targetName, print, person);
      if (src == null) return null;
      bool on; // as opposed to in
      switch (iterator.getWord()) {
        case 'in':
          on = false;
        case 'on':
          on = true;
        case 'in/on':
          print('Choose one: in or on\n');
          return null;
        default:
          print('"put" syntax: put/p <something> in/on <something>\n');
          return null;
      }
      targetName = iterator.getRemainder();
      Atom? dest = findAtom(targetName, print, person);
      if (dest == null) return null;

      if (on) {
        return PutOnCommand(src, dest);
      } else {
        return PutInCommand(src, dest);
      }
    case 'inventory':
    case 'i':
    case 'inventory/i':
      if (!iterator.complete) {
        print('"inventory" syntax: inventory/i\n');
        return null;
      }
      return InventoryCommand();
    case 'bug':
      File('bugs.txt').writeAsStringSync('${iterator.getRemainder()}\n',
          mode: FileMode.append);
      return null;
    case 'clear':
      print('\x1b[2J');
      return null;
    default:
      print(
          'Valid commands:\nlook\nl\ntake\nt\ndrop\nclimb\nenter\ninventory\ni\nbug\nclose\nopen\no\nclear\n');
      return null;
  }
}

Atom? findAtom(String targetName, void Function(Object) print, Person person) {
  if (targetName == '<something>') {
    print('<something> was a placeholder for a thing or location!\n');
    return null;
  }
  Atom? target;
  for (Atom atom in person.accessibleAtoms) {
    if (atom.stringRepresentsThis(targetName)) {
      if (target == null) {
        target = atom;
      } else {
        print(
            '"$targetName" is not specific enough (it matches $atom and $target).\n');
        return null;
      }
    }
  }
  if (target == null) {
    print('Cannot find anything named "$targetName".\n');
    return null;
  }
  return target;
}
