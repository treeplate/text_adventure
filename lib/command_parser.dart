import 'dart:io';

import 'package:text_adventure/word_iterator.dart';

import 'text_adventure.dart';

Command? parseCommand(Set<Atom> allAtoms, Person person, String command,
    void Function(Object?) print) {
  WordIterator iterator = WordIterator(command);
  switch (iterator.getWord()) {
    case 'l':
    case 'look':
    case 'look/l':
      if (!iterator.complete) {
        switch (iterator.getWord()) {
          case 'at':
            if (iterator.complete) {
              print('"look" syntax: look/l [<direction> / at <something>]\n');
              return null;
            }
            String targetName = iterator.getRemainder();
            Atom? target =
                findAtom(targetName, print, person.accessibleAtoms(), person);
            if (target == null) return null;
            return LookAtCommand(target);
          case '[at':
            print('The square brackets mean "optional"!\n');
            return null;
          case 'n':
          case 'north':
            if (!iterator.complete) {
              print('"look" syntax: look/l [<direction> / at <something>]\n');
              return null;
            }
            return LookDirCommand(Direction.north);
          case 'e':
          case 'east':
            if (!iterator.complete) {
              print('"look" syntax: look/l [<direction> / at <something>]\n');
              return null;
            }
            return LookDirCommand(Direction.east);
          case 'w':
          case 'west':
            if (!iterator.complete) {
              print('"look" syntax: look/l [<direction> / at <something>]\n');
              return null;
            }
            return LookDirCommand(Direction.west);
          case 's':
          case 'south':
            if (!iterator.complete) {
              print('"look" syntax: look/l [<direction> / at <something>]\n');
              return null;
            }
            return LookDirCommand(Direction.south);
          case 'u':
          case 'up':
            if (!iterator.complete) {
              print('"look" syntax: look/l [<direction> / at <something>]\n');
              return null;
            }
            return LookDirCommand(Direction.up);
          case 'd':
          case 'down':
            if (!iterator.complete) {
              print('"look" syntax: look/l [<direction> / at <something>]\n');
              return null;
            }
            return LookDirCommand(Direction.down);
          case '<direction>':
            print('<direction> was a placeholder!');
            return null;
          default:
            print('"look" syntax: look/l [<direction> / at <something>]\n');
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
      Atom? target =
          findAtom(targetName, print, person.accessibleAtoms(), person);
      if (target == null) return null;
      return TakeCommand(target);
    case 'drop':
      if (iterator.complete) {
        print('"drop" syntax: drop <something>\n');
        return null;
      }
      String targetName = iterator.getRemainder();
      Atom? target =
          findAtom(targetName, print, person.accessibleAtoms(), person);
      if (target == null) return null;
      return DropCommand(target);
    case 'climb':
      if (iterator.complete) {
        print('"climb" syntax: climb <something>\n');
        return null;
      }
      String targetName = iterator.getRemainder();
      Atom? target =
          findAtom(targetName, print, person.accessibleAtoms(), person);
      if (target == null) return null;
      return ClimbCommand(target);
    case 'enter':
      if (iterator.complete) {
        print('"enter" syntax: enter <something>\n');
        return null;
      }
      String targetName = iterator.getRemainder();
      Atom? target =
          findAtom(targetName, print, person.accessibleAtoms(), person);
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
      Atom? target =
          findAtom(targetName, print, person.accessibleAtoms(), person);
      if (target == null) return null;
      return OpenCommand(target);
    case 'close':
      if (iterator.complete) {
        print('"close" syntax: close <something>\n');
        return null;
      }
      String targetName = iterator.getRemainder();
      Atom? target =
          findAtom(targetName, print, person.accessibleAtoms(), person);
      if (target == null) return null;
      return CloseCommand(target);
    case 'put':
    case 'p':
    case 'put/p':
      if (iterator.complete) {
        print('"put" syntax: put/p <something> in/on <something>\n');
        return null;
      }
      String targetName = iterator.getUntilKeywords(['in', 'on', 'in/on']);
      Atom? src = findAtom(targetName, print, person.accessibleAtoms(), person);
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
      Atom? dest =
          findAtom(targetName, print, person.accessibleAtoms(), person);
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
    case 'find':
      bool debug = iterator.getWord() == 'debug';
      if (!debug) iterator.ungetWord();
      String name = iterator.getRemainder();
      Atom? atom = findAtom(
          name, print, debug ? allAtoms : person.accessibleAtoms(), person);
      if (atom == null) {
        return null;
      }
      if (atom is SingletonAllAtom) {
        if (debug) {
          for (Atom atom2 in allAtoms) {
            if (atom2 is Surface) continue;
            print('${atom2.toStringFromPerspective(person)}: ');
            atom2.printPosition(print, false, person);
            print('\n');
          }
        } else {
          for (Atom atom2 in person.accessibleAtoms()) {
            if (atom2 is Surface) continue;
            print('${atom2.toStringFromPerspective(person)}: ');
            atom2.printPosition(print, false, person);

            print('\n');
          }
        }
        return null;
      }
      if (atom is Ground) {
        if (person.rootT<Container>().ground == atom) {
          atom.findSurface(person, print);
        } else {
          atom.findSurface(person, print);
        }
      } else {
        atom.printPosition(print, false, person);
      }
      print('\n');
      return null;
    case 'e':
    case 'east':
      return EastCommand();
    case 'w':
    case 'west':
      return WestCommand();
    default:
      print(
          'Valid commands:\nlook\ntake\ndrop\nclimb\nenter\ninventory\nbug\nclose\nopen\nclear\nput\neast\nwest\n');
      return null;
  }
}

Atom? findAtom(String targetName, void Function(Object?) print,
    Set<Atom> accessibleAtoms, Person person) {
  if (targetName.toLowerCase() == '<something>') {
    print('<something> was a placeholder!\n');
    return null;
  }
  if (targetName.toLowerCase() == 'all') {
    return SingletonAllAtom();
  }
  if (targetName.toLowerCase() == 'ground' ||
      targetName.toLowerCase() == 'the ground') {
    return person.rootT<Container>().ground;
  }

  if (targetName.toLowerCase() == 'ceiling' ||
      targetName.toLowerCase() == 'the ceiling') {
    return person.rootT<Container>().ceiling;
  }
  Atom? target;
  for (Atom atom in accessibleAtoms) {
    if (atom.stringRepresentsThis(targetName)) {
      if (target == null) {
        target = atom;
      } else {
        print(
            '"$targetName" is not specific enough (it matches ${atom.toStringFromPerspective(person)} and ${target.toStringFromPerspective(person)}).\n');
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
