library ta;

// remove these ignores when https://github.com/dart-lang/sdk/issues/52951 is fixed
// ignore: unused_import
import 'dart:io';
// ignore: unused_import
import 'command_parser.dart';
// ignore: uri_does_not_exist
part '../bin/text_adventure.dart';

sealed class Atom {
  List<Thing> get _accessibleChildren;
  void describe(void Function(Object) print);
  Location findLocation();

  List<Atom> get accessibleAtoms;
  List<Atom> get accessibleAtomsTowardsLeaves;
  List<Atom> get accessibleAtomsTowardsRoot;

  bool stringRepresentsThis(String str);

  void _addThing(Thing t);
  void _removeThing(Thing t);

  void printPosition(void Function(Object) print, bool addComma);
}

enum RelativePosition {
  heldByParent,
  inParent,
  onParent,
}

String positionToString(RelativePosition rp) {
  switch (rp) {
    case RelativePosition.inParent:
      return 'in';
    case RelativePosition.onParent:
      return 'on';
    case RelativePosition.heldByParent:
      return 'being held by';
  }
}

abstract class Thing extends Atom {
  Atom _parent;
  RelativePosition _position;
  bool get hasSurface;
  bool get hasInterior;
  bool get open;

  @override
  void printPosition(void Function(Object) print, bool addComma) {
    if (addComma) print(', ');
    print('${positionToString(_position)} $_parent');
    _parent.printPosition(print, true);
  }

  @override
  Location findLocation() {
    return _parent.findLocation();
  }

  Thing._(this._parent, this._position) {
    _parent._addThing(this);
  }
}

class Ground extends Thing {
  Ground._(super.parent, super.position) : super._();

  @override
  String toString() => "the ground";

  @override
  final List<Thing> _accessibleChildren = [];

  @override
  bool get hasSurface => true;

  @override
  void describe(void Function(Object) print) {
    print("This is the ground.\n");
    if (_accessibleChildren.isNotEmpty) {
      print("\nOn the ground, you see the following:\n");
      for (Thing child in _accessibleChildren) {
        print('  $child\n');
      }
    }
  }

  @override
  List<Atom> get accessibleAtoms =>
      [this, _parent, ...accessibleAtomsTowardsLeaves];

  @override
  List<Atom> get accessibleAtomsTowardsRoot => [_parent];

  @override
  List<Atom> get accessibleAtomsTowardsLeaves => _accessibleChildren
      .expand((element) => [element, ...element.accessibleAtomsTowardsLeaves])
      .toList();

  @override
  bool stringRepresentsThis(String str) {
    return str.toLowerCase() == 'ground' || str.toLowerCase() == 'the ground';
  }

  @override
  void _addThing(Thing t) {
    assert(t._position == RelativePosition.onParent);
    _accessibleChildren.add(t);
  }

  @override
  void _removeThing(Thing t) {
    _accessibleChildren.remove(t);
  }

  @override
  bool get hasInterior => false;

  @override
  bool get open => throw UnsupportedError("Ground.open");
}

// e.g. boxes, backpacks, players
abstract class ThingWithInventory extends Thing {
  final List<Thing> _inventory = [];
  final List<Thing> _surfaceChildren = [];

  @override
  List<Thing> get _accessibleChildren =>
      (open ? _inventory : <Thing>[]) + _surfaceChildren;

  ThingWithInventory._(super.parent, super.position) : super._();
}

class Container extends ThingWithInventory {
  Container._(super.parent, super.position, this.capacity, this.hasSurface,
      this.name, this.nameRegex)
      : super._();

  final String name;
  final RegExp nameRegex;
  @override
  String toString() => name;

  final int capacity;
  @override
  final bool hasSurface;
  bool _open = false;
  @override
  bool get open => _open;

  @override
  void describe(void Function(Object) print) {
    print("This is $this.\n");
    if (_surfaceChildren.isNotEmpty) {
      print("\nOn $this, you see the following:\n");
      for (Thing child in _surfaceChildren) {
        print('  $child\n');
      }
    }
    if (_open && _inventory.isNotEmpty) {
      print("\nIn $this, you see the following:\n");
      for (Thing child in _inventory) {
        print('  $child\n');
      }
    }
  }

  @override
  List<Atom> get accessibleAtoms =>
      [...accessibleAtomsTowardsRoot, this, ...accessibleAtomsTowardsLeaves];

  @override
  List<Atom> get accessibleAtomsTowardsRoot => [
        _parent,
        ..._parent.accessibleAtomsTowardsRoot,
        ..._parent._accessibleChildren
            .where((element) => element != this)
            .expand((e) => [e, ...e.accessibleAtomsTowardsLeaves]),
      ];

  @override
  List<Atom> get accessibleAtomsTowardsLeaves => _accessibleChildren
      .expand((e) => [e, ...e.accessibleAtomsTowardsLeaves])
      .toList();

  @override
  bool stringRepresentsThis(String str) {
    return nameRegex.hasMatch(str);
  }

  @override
  void _addThing(Thing t) {
    if (!hasSurface) {
      assert(t._position == RelativePosition.inParent);
    }
    switch (t._position) {
      case RelativePosition.onParent:
        _surfaceChildren.add(t);
      case RelativePosition.inParent:
        _inventory.add(t);
      case RelativePosition.heldByParent:
        assert(false);
    }
  }

  @override
  void _removeThing(Thing t) {
    switch (t._position) {
      case RelativePosition.onParent:
        _surfaceChildren.remove(t);
      case RelativePosition.inParent:
        _inventory.remove(t);
      case RelativePosition.heldByParent:
        assert(false);
    }
  }

  @override
  bool get hasInterior => true;
}

class Backpack extends Container {
  Backpack._(
    Atom parent,
    RelativePosition position,
    int capacity,
    String name,
    RegExp regex,
  ) : super._(
          parent,
          position,
          capacity,
          false,
          name,
          regex,
        );
}

sealed class Command {}

class InventoryCommand extends Command {}

class LookCommand extends Command {}

class LookAtCommand extends Command {
  final Atom target;

  LookAtCommand(this.target);
}

class TakeCommand extends Command {
  final Atom target;

  TakeCommand(this.target);
}

class DropCommand extends Command {
  final Atom target;

  DropCommand(this.target);
}

class ClimbCommand extends Command {
  final Atom target;

  ClimbCommand(this.target);
}

class EnterCommand extends Command {
  final Atom target;

  EnterCommand(this.target);
}

class OpenCommand extends Command {
  final Atom target;

  OpenCommand(this.target);
}

class CloseCommand extends Command {
  final Atom target;

  CloseCommand(this.target);
}

class PutOnCommand extends Command {
  final Atom source;
  final Atom dest;

  PutOnCommand(this.source, this.dest);
}

class PutInCommand extends Command {
  final Atom source;
  final Atom dest;

  PutInCommand(this.source, this.dest);
}

class Person extends ThingWithInventory {
  Backpack? _backpack;

  void handleCommand(Command command, void Function(Object) print) {
    switch (command) {
      case InventoryCommand():
        print('You are holding ');
        if (_inventory.isEmpty) {
          print('nothing');
        } else {
          print(_inventory.single);
        }
        if (_backpack != null) {
          print(' and are wearing a backpack');
        }
        print('.\n');
      case LookCommand():
        print('(');
        printPosition(print, false);
        print(')\n');
        _parent.describe(print);
      case LookAtCommand(target: Atom target):
        print('(');
        target.printPosition(print, false);
        print(')\n');
        target.describe(print);
      case TakeCommand(target: Atom target):
        if (target is Location) {
          print('You cannot take a location!\n');
        } else if (target.accessibleAtomsTowardsLeaves.contains(this) ||
            target == this) {
          print('You cannot take something if it would cause recursion!\n');
        } else if (_inventory.isNotEmpty && _backpack == null) {
          if (_inventory.single is Backpack && _inventory.contains(target)) {
            print('You put it on your back.\n');
            _backpack = target as Backpack;
            target._position = RelativePosition.onParent;
            _inventory.remove(target);
          } else if (_inventory.contains(target)) {
            print('You are already holding $target!\n');
          } else {
            print(
                'You are already holding something! Maybe consider getting a backpack?\n');
            for (Atom a in accessibleAtoms) {
              if (a is Backpack) {
                print('There is a backpack ');
                a.printPosition(print, false);
                print('.\n');
              }
            }
          }
        } else if (_backpack == null) {
          if (target is Backpack) {
            print('You put it on your back.\n');
            _backpack = target;
          } else {
            _inventory.add(target as Thing);
          }
          if (target is! Thing) return;
          target._parent._removeThing(target);
          target._parent = this;
          if (target is Backpack) {
            target._position = RelativePosition.onParent;
          } else {
            target._position = RelativePosition.heldByParent;
          }
        } else {
          if (target == _backpack) {
            if (_inventory.isNotEmpty) {
              print(
                  'You are already holding something, and $target is already on your back!\n');
            } else {
              _backpack = null;
              _inventory.add(target as Thing);
              target._position = RelativePosition.heldByParent;
            }
          } else if (_backpack!._inventory.length >= _backpack!.capacity) {
            if (_inventory.isNotEmpty) {
              print(
                  'You are already holding something, and your backpack is full!\n');
            } else {
              _inventory.add(target as Thing);
              target._parent._removeThing(target);
              target._parent = this;
              target._position = RelativePosition.heldByParent;
            }
          } else {
            _backpack!._open = true;
            _backpack!._inventory.add(target as Thing);
            target._parent._removeThing(target);
            target._parent = _backpack!;
            target._position = RelativePosition.inParent;
          }
        }
      case DropCommand(target: Atom target):
        if (target is Location) {
          print('You cannot drop a location!\n');
        } else if (!_inventory.contains(target) &&
            !(_backpack?._inventory.contains(target) ?? false) &&
            _backpack != target) {
          print('You are not holding $target!\n');
        } else {
          if (_inventory.contains(target)) {
            _inventory.remove(target as Thing);
            target._parent = _parent;
            target._position = _position;
          } else if (target == _backpack) {
            _backpack = null;
            (target as Backpack)._parent = _parent;
            target._position = _position;
          } else {
            _backpack!._open = true;
            _backpack!._inventory.remove(target as Thing);
            target._parent = _parent;
            target._position = _position;
          }
          _parent._addThing(target as Thing);
        }
      case ClimbCommand(target: Atom target):
        if (target is Location) {
          print('You cannot climb a location!\n');
        } else if (accessibleAtomsTowardsLeaves.contains(target) ||
            target == this) {
          print('You cannot climb something if it would cause recursion!\n');
        } else if (target is Thing && !target.hasSurface) {
          print('You cannot climb $target, it has no surface!\n');
        } else {
          _parent._removeThing(this);
          _parent = target;
          _position = RelativePosition.onParent;
          _parent._addThing(this);
        }
      case EnterCommand(target: Atom target):
        _parent._removeThing(this);
        if (target is Location) {
          _parent = target.ground;
          _position = RelativePosition.onParent;
          _parent._addThing(this);
        } else if (target.accessibleAtomsTowardsRoot.contains(this)) {
          print('You cannot enter something if it would cause recursion!\n');
        } else if (target is Thing && !target.hasInterior) {
          print('You cannot enter $target, it has no interior!\n');
        } else if (target is Thing && !target.open) {
          print('You cannot enter $target, it\'s closed!\n');
        } else {
          _parent = target;
          _position = RelativePosition.inParent;
          _parent._addThing(this);
        }
      case CloseCommand(target: Atom target):
        if (target is! Container) {
          print('You cannot close something that is not a container!\n');
        } else if (!target._open) {
          print('You cannot close $target, it is already closed!\n');
        } else {
          target._open = false;
        }
      case OpenCommand(target: Atom target):
        if (target is! Container) {
          print('You cannot open something that is not a container!\n');
        } else if (target._open) {
          print('You cannot open $target, it is already open!\n');
        } else {
          target._open = true;
        }
      case PutOnCommand(source: Atom src, dest: Atom dest):
        if (_inventory.isNotEmpty && !_inventory.contains(src)) {
          print(
              'You are already holding something, consider dropping it first.\n');
        } else {
          throw UnimplementedError();
        }
      case PutInCommand(source: Atom src, dest: Atom dest):
        if (_inventory.isNotEmpty && !_inventory.contains(src)) {
          print(
              'You are already holding something, consider dropping it first.\n');
        } else {
          throw UnimplementedError();
        }
    }
  }

  Person._(Atom parent, RelativePosition position, this.name)
      : super._(parent, position);
  final String name;

  @override
  List<Atom> get accessibleAtoms =>
      accessibleAtomsTowardsRoot + [this, ...accessibleAtomsTowardsLeaves];
  @override
  bool get hasSurface => false;

  @override
  String toString() => name;

  @override
  void describe(void Function(Object) print) {
    print('This is $this.\n');
    for (Thing t in _inventory) {
      print('$this is holding $t.\n');
    }
    if (_backpack != null) {
      print('$_backpack is on $this.\n');
    }
  }

  @override
  List<Atom> get accessibleAtomsTowardsRoot => [
        _parent,
        ..._parent.accessibleAtomsTowardsRoot,
        ..._parent._accessibleChildren
            .where((element) => element != this)
            .expand((e) => [e, ...e.accessibleAtomsTowardsLeaves]),
      ];

  @override
  List<Atom> get accessibleAtomsTowardsLeaves =>
      <Atom>[..._inventory] +
      [
        if (_backpack != null) ...[
          _backpack!,
          ..._backpack!.accessibleAtomsTowardsLeaves,
        ]
      ];

  @override
  bool stringRepresentsThis(String str) {
    return str.toLowerCase() == name.toLowerCase() || str.toLowerCase() == 'me';
  }

  @override
  void _addThing(Thing t) {
    assert(false);
  }

  @override
  void _removeThing(Thing t) {
    assert(false);
  }

  @override
  bool get hasInterior => false;

  @override
  bool get open => true;
}

class Location extends Atom {
  Location._(this.name, this.nameRegex, this.description);

  final String name;
  final RegExp nameRegex;
  final String description;

  @override
  String toString() => name;

  @override
  Location findLocation() {
    return this;
  }

  late final Ground ground = Ground._(this, RelativePosition.inParent);

  @override
  late final List<Thing> _accessibleChildren = [ground];

  @override
  void printPosition(void Function(Object) print, bool addComma) {}

  @override
  void describe(void Function(Object) print) {
    print(description);
    if (ground._accessibleChildren.isNotEmpty) {
      print('\n\nOn the ground, you see:\n  ');
      print(ground._accessibleChildren.join('\n  '));
    }
    print('\n');
  }

  @override
  List<Atom> get accessibleAtoms => [this, ...accessibleAtomsTowardsLeaves];

  @override
  List<Atom> get accessibleAtomsTowardsLeaves =>
      [ground, ...ground.accessibleAtomsTowardsLeaves];

  @override
  List<Atom> get accessibleAtomsTowardsRoot => [];

  @override
  bool stringRepresentsThis(String str) {
    return nameRegex.hasMatch(str);
  }

  @override
  void _addThing(Thing t) {
    if (t is Ground) {
      // this must be our [ground] field
    } else {
      assert(false);
    }
  }

  @override
  void _removeThing(Thing t) {
    assert(false);
  }
}
