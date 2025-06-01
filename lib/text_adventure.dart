import 'dart:core' hide print;
part 'world_creation.dart';

sealed class Atom {
  /// Returns the children of this atom that can be seen from that side of the atom.
  Set<Thing> _accessibleChildren(bool? side1);

  /// Returns all the children of this atom.
  Set<Thing> get _allChildren;

  /// Returns all children that can be seen from this atom.
  // If you can see out of this atom, it defers to the parent. Otherwise, just call [_accessibleAtomsTowardsLeaves].
  Set<Atom> accessibleAtoms();

  String toStringFromPerspective(Thing perspective);
  @override
  String toString() => '<$runtimeType>';

  /// Prints this atom's parent chain up to an atom you can't see out of.
  void printPosition(
    void Function(Object?) print,
    bool addComma,
    Thing perspective,
  );

  void describe(Thing perspective, void Function(Object?) print);

  bool hasSurface(Thing perspective);

  Set<Atom> _accessibleAtomsTowardsLeaves(bool includeHiddenAtoms) =>
      (includeHiddenAtoms ? _allChildren : _accessibleChildren(null))
          .expand((element) =>
              element._accessibleAtomsTowardsLeaves(includeHiddenAtoms))
          .toSet()
        ..add(this);

  bool stringRepresentsThis(String str);

  void _addThing(void Function(Object?) print, Thing thing, Thing perspective);
  void _removeThing(
      void Function(Object?) print, Thing thing, Thing perspective);

  /// Walks up the tree to find the first [T]
  T rootT<T extends Atom>() {
    final Atom atom = this;
    return atom is T
        ? atom
        : atom is Thing
            ? atom._parent?.rootT<T>() ??
                (throw StateError('$runtimeType with no parent'))
            : atom is Surface
                ? atom._side1Parent?.rootT<T>() ??
                    (throw StateError(
                        'something on/in surface with no side1Parent'))
                : (throw UnimplementedError('non-thing-or-surface'));
  }

  void listChildren(
      void Function(Object?) print, int indent, Thing perspective) {
    for (Thing child in _accessibleChildren(true)) {
      print(
          '${'  ' * indent}${child.toStringFromPerspective(perspective)} (${positionToString(child._position)})\n');
      child.listChildren(print, indent + 1, perspective);
    }
  }
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

class SingletonAllAtom extends Atom {
  SingletonAllAtom._();
  static SingletonAllAtom instance = SingletonAllAtom._();
  factory SingletonAllAtom() {
    return instance;
  }
  @override
  Set<Thing> _accessibleChildren(bool? side1) =>
      throw UnsupportedError('SingletonAllAtom._accessibleChildren');
  @override
  Set<Thing> get _allChildren =>
      throw UnsupportedError('SingletonAllAtom._accessibleChildren');

  @override
  void _addThing(void Function(Object?) print, Thing thing, Thing perspective) {
    throw UnsupportedError('SingletonAllAtom._addThing');
  }

  @override
  void _removeThing(
      void Function(Object?) print, Thing thing, Thing perspective) {
    throw UnsupportedError('SingletonAllAtom._removeThing');
  }

  @override
  Set<Atom> accessibleAtoms() =>
      throw UnsupportedError('SingletonAllAtom.accessibleAtoms()');

  @override
  Set<Atom> _accessibleAtomsTowardsLeaves(bool includeHiddenAtoms) =>
      throw UnsupportedError('SingletonAllAtom.accessibleAtomsTowardsLeaves');

  @override
  void printPosition(
      void Function(Object p1) print, bool addComma, Thing perspective) {
    if (addComma) print(', ');
    print('everywhere');
  }

  @override
  bool stringRepresentsThis(String str) {
    return str == 'all';
  }

  @override
  String toStringFromPerspective(Thing perspective) => 'all';

  @override
  void describe(Thing perspective, void Function(Object? p1) print) {
    throw UnsupportedError('SingletonAllAtom.describe');
  }

  @override
  bool hasSurface(Thing perspective) => false;
}

enum Direction { up, down, north, east, south, west }

Map<Direction, Surface> surfaces(Thing thing) {
  return {
    Direction.up: Ground._(null, thing),
    Direction.down: Ground._(thing, null),
    Direction.north: Surface._(thing, null),
    Direction.east: Surface._(null, thing),
    Direction.west: Surface._(thing, null),
    Direction.south: Surface._(null, thing),
  };
}

abstract class Thing extends Atom {
  Atom? _parent;
  RelativePosition _position;
  final (int, int, int) localGridPosition;
  late final Map<Direction, Surface> _surfaces;
  // Whether you can put things in this thing
  bool get hasInterior;
  bool get open;

  Set<Atom> get parents => {
        if (_parent != null) ...{
          _parent!,
          if (_parent is Thing) ...(_parent as Thing).parents,
          if (_parent is Surface) ...{
            if ((_parent as Surface)._side1Parent != null) ...{
              (_parent as Surface)._side1Parent!,
              ...(_parent as Surface)._side1Parent!.parents
            },
            if ((_parent as Surface)._side2Parent != null) ...{
              (_parent as Surface)._side2Parent!,
              ...(_parent as Surface)._side2Parent!.parents
            },
          }
        }
      };

  bool indirectly(RelativePosition position, Atom potentialAncestor) {
    // indirectly <on/in/held by> <atom>
    if (_parent == potentialAncestor) {
      return position == _position;
    }
    return _parent is Thing
        ? (_parent as Thing).indirectly(position, potentialAncestor)
        : false;
  }

  @override
  void printPosition(
      void Function(Object?) print, bool addComma, Thing perspective) {
    if (addComma) print(', ');
    print(
        '${positionToString(_position)} ${_parent!.toStringFromPerspective(perspective)}');
    _parent!.printPosition(print, true, perspective);
  }

  Thing._(this._parent, this._position, void Function(Object?) print,
      [this.localGridPosition = (0, 0, 0),
      Map<Direction, Surface>? _surfaces]) {
    this._surfaces = _surfaces ?? surfaces(this);
    _parent?._addThing(print, this, this);
  }
}

// side 1: down (e.g. ground), north, west
// side 2: up (e.g. ceiling), south, east
class Surface extends Atom {
  // ignore: unused_field
  final Thing? _side1Parent;
  // ignore: unused_field
  final Thing? _side2Parent;

  Surface._(this._side1Parent, this._side2Parent);

  @override
  String toStringFromPerspective(Thing perspective) {
    return 'the wall';
  }

  @override
  Set<Thing> _accessibleChildren(bool? side1) => {};

  @override
  void _addThing(void Function(Object?) print, Thing thing, Thing perspective) {
    assert(false);
  }

  @override
  Set<Thing> get _allChildren => {};

  @override
  void _removeThing(
      void Function(Object?) print, Thing thing, Thing perspective) {
    assert(false);
  }

  @override
  Set<Atom> accessibleAtoms() =>
      throw UnsupportedError('Surface.accessibleAtoms()');

  @override
  void describe(Thing perspective, void Function(Object?) print) {
    print('This is a blank wall.\n');
  }

  @override
  void printPosition(
      void Function(Object?) print, bool addComma, Thing perspective) {
    if (perspective == this) {
      if (addComma) print(', ');
      if (_side1Parent == null) {
        print('in ${_side2Parent!.toStringFromPerspective(perspective)}');
      } else if (_side2Parent == null) {
        print('in ${_side1Parent!.toStringFromPerspective(perspective)}');
      } else {
        throw UnimplementedError();
      }
    }
  }

  @override
  bool stringRepresentsThis(String str) {
    return str.toLowerCase() == 'wall' || str.toLowerCase() == 'the wall';
  }

  @override
  bool hasSurface(Thing perspective) => false;
}

// Side 1 is ground, 2 is ceiling
class Ground extends Surface {
  Ground._(super.side1Parent, super.side2Parent) : super._();

  @override
  Set<Thing> _accessibleChildren(bool? side1) => side1! ? _children : {};

  @override
  String toStringFromPerspective(Thing perspective) =>
      perspective.parents.contains(this) ? "the ground" : 'the ceiling';

  final Set<Thing> _children = {};

  @override
  void describe(Thing perspective, void Function(Object?) print) {
    if (perspective.parents.contains(this)) {
      print("This is the ground.\n");
      if (_children.isNotEmpty) {
        print("\nOn the ground, you see the following:\n");
        listChildren(print, 1, perspective);
      }
    } else {
      print("This is a blank ceiling.\n");
    }
  }

  @override
  bool hasSurface(Thing perspective) =>
      !perspective.parents.contains(_side2Parent);

  @override
  Set<Atom> accessibleAtoms() => _side1Parent!.accessibleAtoms();

  @override
  bool stringRepresentsThis(String str) {
    return str.toLowerCase() == 'ground' ||
        str.toLowerCase() == 'the ground' ||
        str.toLowerCase() == 'ceiling' ||
        str.toLowerCase() == 'the ceiling';
  }

  @override
  void _addThing(void Function(Object?) print, Thing thing, Thing perspective) {
    assert(thing._position == RelativePosition.onParent);
    _children.add(thing);
  }

  @override
  void _removeThing(
      void Function(Object?) print, Thing thing, Thing perspective) {
    _children.remove(thing);
  }

  @override
  void printPosition(
      void Function(Object?) print, bool addComma, Thing perspective) {
    if (addComma) {
      print(', ');
    } else {
      throw UnsupportedError('Use findSurface() instead!');
    }
    print('in ${_side1Parent!.toStringFromPerspective(perspective)}');
  }

  void findSurface(Thing perspective, void Function(Object?) print) {
    if (perspective.parents.contains(this)) {
      print('in ${_side1Parent!.toStringFromPerspective(perspective)} (g)');
    } else {
      print('in ${_side2Parent!.toStringFromPerspective(perspective)} (c)');
    }
  }

  @override
  Set<Thing> get _allChildren => _children;
}

class OpeningSurface extends Surface {
  OpeningSurface._(super._side1Parent, super._side2Parent) : super._();
  @override
  void printPosition(
      void Function(Object?) print, bool addComma, Thing perspective) {
    if (addComma) {
      print(', ');
    }
    if (_side1Parent == null) {
      print('in ${_side2Parent!.toStringFromPerspective(perspective)}');
    } else if (_side2Parent == null) {
      print('in ${_side1Parent!.toStringFromPerspective(perspective)}');
    } else {
      print(
          'between ${_side1Parent!.toStringFromPerspective(perspective)} and ${_side2Parent!.toStringFromPerspective(perspective)}');
    }
  }

  @override
  void describe(Thing perspective, void Function(Object?) print) {
    print(
        'This is an opening to ${(perspective.parents.contains(_side1Parent)) ? _side1Parent : _side2Parent}.\n');
  }

  @override
  Set<Thing> _accessibleChildren(bool? side1) => side1 == null
      ? {}
      : side1
          ? {_side2Parent!}
          : {_side1Parent!};
  @override
  Set<Atom> accessibleAtoms() =>
      _side1Parent!.accessibleAtoms() + _side2Parent!.accessibleAtoms();

  @override
  String toString() {
    return 'an opening';
  }

  @override
  bool stringRepresentsThis(String str) {
    return super.stringRepresentsThis(str) ||
        str.toLowerCase() == 'opening' ||
        str.toLowerCase() == 'the opening';
  }
}

extension Plus<T> on Set<T> {
  Set<T> operator +(Set<T> other) {
    return union(other);
  }
}

// e.g. players
abstract class ThingWithInventory extends Thing {
  final Set<Thing> _inventory = {};
  final Set<Thing> _surfaceChildren = {};

  @override
  Set<Thing> _accessibleChildren(bool? side1) =>
      (open ? _inventory : <Thing>{}) + _surfaceChildren;

  @override
  Set<Thing> get _allChildren => _inventory + _surfaceChildren;

  ThingWithInventory._(super.parent, super.position, super.print) : super._();
}

class Container extends Thing {
  Container._(
    super.parent,
    super.position,
    super.print,
    this.capacity,
    this.name,
    this.nameRegex,
    this.description, [
    this.openable = true,
    super.localGridPosition,
    super._surfaces,
  ]) : super._();

  final String name;
  final RegExp nameRegex;
  final String description;
  @override
  String toStringFromPerspective(Thing perspective) => name;

  final int capacity;
  bool _open = false;
  @override
  bool get open => _open;
  final bool openable;

  Ground get ceiling => _surfaces[Direction.up] as Ground;
  Ground get ground => _surfaces[Direction.down] as Ground;
  Set<Thing> get _surfaceChildren =>
      Set.unmodifiable(ceiling._children.toList());
  Set<Thing> get _inventory => Set.unmodifiable(ground._children.toList());

  @override
  void describe(Thing perspective, void Function(Object?) print) {
    print("$description\n");
    if (_surfaceChildren.isNotEmpty &&
        (open || !perspective.parents.contains(ground))) {
      print(
          "\nOn ${toStringFromPerspective(perspective)}, you see the following:\n");
      for (Thing child in _surfaceChildren) {
        print('  ${child.toStringFromPerspective(perspective)}\n');
        child.listChildren(print, 2, perspective);
      }
    }
    if ((_open && _inventory.isNotEmpty) ||
        perspective.parents.contains(ground)) {
      print(
          "\nIn ${toStringFromPerspective(perspective)}, you see the following:\n");
      for (Thing child in _inventory) {
        print('  ${child.toStringFromPerspective(perspective)}\n');
        child.listChildren(print, 2, perspective);
      }
    }
  }

  @override
  void printPosition(
      void Function(Object?) print, bool addComma, Thing perspective) {
    if (addComma) print(', ');
    if (open ||
        !_inventory.any((e) =>
            e._accessibleAtomsTowardsLeaves(true).contains(perspective))) {
      if (_parent == null) {
        // not supposed to happen, but "debug find all" triggers it
        print('in the void');
      } else {
        print(
            '${positionToString(_position)} ${_parent!.toStringFromPerspective(perspective)}');
        _parent!.printPosition(print, true, perspective);
      }
    } else {
      print('somewhere');
    }
  }

  @override
  Set<Atom> accessibleAtoms() => open
      ? _parent!.accessibleAtoms()
      : (_inventory
              .map((e) => e._accessibleAtomsTowardsLeaves(false))
              .expand((element) => element)
              .toSet() +
          {..._surfaces.values, this});

// TODO: look into the reasonableness of this function
  @override
  Set<Atom> _accessibleAtomsTowardsLeaves(bool includeHiddenAtoms) =>
      open || includeHiddenAtoms
          ? super._accessibleAtomsTowardsLeaves(includeHiddenAtoms)
          : {..._surfaces.values, this};

  @override
  bool stringRepresentsThis(String str) {
    return nameRegex.hasMatch(str);
  }

  @override
  void _addThing(void Function(Object?) print, Thing thing, Thing perspective) {
    switch (thing._position) {
      case RelativePosition.onParent:
        ceiling._children.add(thing);
      case RelativePosition.inParent:
        ground._children.add(thing);
      case RelativePosition.heldByParent:
        assert(false);
    }
  }

  @override
  void _removeThing(
      void Function(Object?) print, Thing thing, Thing perspective) {
    switch (thing._position) {
      case RelativePosition.onParent:
        ceiling._children.remove(thing);
      case RelativePosition.inParent:
        ground._children.remove(thing);
      case RelativePosition.heldByParent:
        assert(false);
    }
  }

  @override
  bool get hasInterior => open;

  @override
  Set<Thing> _accessibleChildren(bool? side1) =>
      ceiling._children + (open ? ground._children : {});

  @override
  Set<Thing> get _allChildren => ceiling._children + ground._children;

  @override
  bool hasSurface(Thing perspective) {
    return true;
  }
}

class Button extends Thing {
  Button._(super.parent, super.position, super.print, this._wall) : super._();
  Surface get wall => _wall;
  Surface _wall;
  void activate(void Function(Object?) print, Thing perspective) {
    if (wall is! OpeningSurface) {
      OpeningSurface opening =
          OpeningSurface._(wall._side1Parent, wall._side2Parent);
      Direction side1Dir = wall._side1Parent!._surfaces.entries
          .singleWhere((element) => element.value == wall)
          .key;
      wall._side1Parent!._surfaces[side1Dir] = opening;
      Direction side2Dir = wall._side2Parent!._surfaces.entries
          .singleWhere((element) => element.value == wall)
          .key;
      wall._side2Parent!._surfaces[side2Dir] = opening;
      print(
          '${capitalizeFirst(wall.toStringFromPerspective(perspective))} turns into an opening.\n');
          _wall = wall._side1Parent!._surfaces[side1Dir]!;
    }
  }

  @override
  Set<Thing> _accessibleChildren(bool? side1) {
    return _allChildren.toSet();
  }

  @override
  String toStringFromPerspective(Thing perspective) {
    return 'the button';
  }

  @override
  void _addThing(void Function(Object?) print, Thing thing, Thing perspective) {
    _allChildren.add(thing);
    activate(print, perspective);
  }

  @override
  final Set<Thing> _allChildren = {};

  @override
  void _removeThing(
      void Function(Object?) print, Thing thing, Thing perspective) {
    bool wasChild = _allChildren.remove(thing);
    assert(wasChild);
  }

  @override
  Set<Atom> accessibleAtoms() {
    return _parent!.accessibleAtoms();
  }

  @override
  void describe(Thing perspective, void Function(Object? p1) print) {
    // TODO: better description
    print("I'm a button!\n");
  }

  @override
  bool get hasInterior => false;

  @override
  bool get open => false;

  @override
  bool stringRepresentsThis(String str) {
    return str == 'button' || str == 'the button';
  }

  @override
  bool hasSurface(Thing perspective) {
    return true;
  }
}

class Backpack extends Container {
  Backpack._(
    super.parent,
    super.position,
    super.print,
    super.capacity,
    super.name,
    super.regex,
    super.description,
  ) : super._();
}

sealed class Command {}

class EastCommand extends Command {}

class WestCommand extends Command {}

class InventoryCommand extends Command {}

class LookCommand extends Command {}

class LookDirCommand extends Command {
  final Direction dir;

  LookDirCommand(this.dir);
}

class LookAtCommand extends Command {
  final Atom target;

  LookAtCommand(this.target);
}

class TakeCommand extends Command {
  final Atom target;
  final bool putInBackpack;

  TakeCommand(this.target, [this.putInBackpack = true]);
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

  void handleCommand(Command command, void Function(Object?) print) {
    switch (command) {
      case InventoryCommand():
        print('You are holding ');
        if (_inventory.isEmpty) {
          print('nothing');
        } else {
          print(_inventory.single);
        }
        if (_backpack != null) {
          print(' and are wearing a backpack containing:\n');
          for (Thing thing in _backpack!._inventory) {
            print('${thing.toStringFromPerspective(this)}\n');
          }
        } else {
          print('.\n');
        }
      case LookCommand():
        print('(');
        printPosition(print, false, this);
        print(')\n');
        if (_parent is Thing) {
          (_parent as Thing).describe(this, print);
        } else {
          assert(_parent is Surface);
          (_parent as Surface)._side1Parent!.describe(this, print);
        }
      case LookAtCommand(target: Atom target):
        if (target is SingletonAllAtom) {
          for (Atom atom in accessibleAtoms()) {
            if (atom is Surface) continue;
            print('\n${atom.toStringFromPerspective(this)}:\n');
            handleCommand(LookAtCommand(atom), print);
          }
          break;
        }
        print('(');
        if (target is Ground) {
          if (indirectly(RelativePosition.onParent, target)) {
            print('the ground');
          } else if (rootT<Ground>()._side1Parent!._surfaces[Direction.up] ==
              target) {
            print('the ceiling');
          } else if ((target._side1Parent ?? target._side2Parent!)
              .indirectly(RelativePosition.onParent, rootT<Ground>())) {
            print('inside something in this room');
          } else {
            print('outside of ${rootT<Ground>()._side1Parent}');
          }
        } else {
          target.printPosition(print, false, this);
        }
        print(')\n');
        if (target is Thing) {
          target.describe(this, print);
        } else {
          assert(target is Surface);
          (target as Surface).describe(this, print);
        }
      case TakeCommand(target: Atom target, putInBackpack: bool pib):
        if (target is SingletonAllAtom) {
          for (Atom atom in accessibleAtoms()..remove(_backpack)) {
            if (atom is Surface) continue;
            print('\n${atom.toStringFromPerspective(this)}:\n');
            handleCommand(TakeCommand(atom), print);
          }
        } else if (target is! Thing) {
          assert(target is Surface);
          print('You cannot take a wall or floor or ceiling!\n');
        } else if (parents.contains(target) || target == this) {
          print('You cannot take something if it would cause recursion!\n');
        } else if (_inventory.isNotEmpty && _backpack == null) {
          if (_inventory.single is Backpack && _inventory.contains(target)) {
            print('You put it on your back.\n');
            _backpack = target as Backpack;
            target._position = RelativePosition.onParent;
            _inventory.remove(target);
          } else if (_inventory.contains(target)) {
            print(
                'You are already holding ${target.toStringFromPerspective(this)}!\n');
          } else if (target is Backpack) {
            print('(first dropping ${_inventory.single})\n');
            handleCommand(DropCommand(_inventory.single), print);
            handleCommand(TakeCommand(target), print);
          } else {
            print(
                'You are already holding something! Maybe consider getting a backpack?\n');
            for (Atom a in accessibleAtoms()) {
              if (a is Backpack) {
                print('There is a backpack ');
                a.printPosition(print, false, this);
                print('.\n');
              }
            }
          }
        } else if (_backpack == null || !pib) {
          if (target is Backpack && _backpack == null) {
            print(
                'You put ${target.toStringFromPerspective(this)} on your back.\n');
            _backpack = target;
          } else {
            print('You take ${target.toStringFromPerspective(this)}.\n');
            _inventory.add(target);
          }
          target._parent?._removeThing(print, target, this);
          target._parent = this;
          if (_backpack == target) {
            target._position = RelativePosition.onParent;
          } else {
            target._position = RelativePosition.heldByParent;
          }
        } else {
          if (target == _backpack) {
            if (_inventory.isNotEmpty) {
              print(
                  'You are already holding something, and ${target.toStringFromPerspective(this)} is already on your back!\n');
            } else {
              _backpack = null;
              _inventory.add(target);
              target._position = RelativePosition.heldByParent;
            }
          } else if (_backpack!._inventory.length >= _backpack!.capacity) {
            if (_inventory.isNotEmpty) {
              print(
                  'You are already holding something, and your backpack is full!\n');
            } else {
              _inventory.add(target);
              target._parent?._removeThing(print, target, this);
              target._parent = this;
              target._position = RelativePosition.heldByParent;
            }
          } else if (_backpack!._inventory.contains(target)) {
            if (_inventory.isEmpty) {
              _inventory.add(target);
              target._parent?._removeThing(print, target, this);
              target._parent = this;
              target._position = RelativePosition.heldByParent;
            } else {
              print(
                  'You are already holding ${target.toStringFromPerspective(this)}!\n');
            }
          } else {
            print(
                'You put ${target.toStringFromPerspective(this)} in your backpack.\n');
            _backpack!._open = true;
            _moveThing(
                print, target, _backpack!, RelativePosition.inParent, this);
          }
        }
      case DropCommand(target: Atom target):
        if (target is SingletonAllAtom) {
          for (Atom atom in _inventory +
              (_backpack?._inventory ?? {}) +
              {if (_backpack != null) _backpack!}) {
            print('\n${atom.toStringFromPerspective(this)}:\n');
            handleCommand(DropCommand(atom), print);
          }
        } else if (target is! Thing) {
          print('You cannot drop a non-thing!\n');
        } else if (!_inventory.contains(target) &&
            !(_backpack?._inventory.contains(target) ?? false) &&
            _backpack != target) {
          print(
              'You are not holding ${target.toStringFromPerspective(this)}!\n');
        } else {
          print('You drop ${target.toStringFromPerspective(this)}.\n');
          if (_inventory.contains(target)) {
            _inventory.remove(target);
            target._parent = _parent;
            target._position = _position;
          } else if (target == _backpack) {
            _backpack = null;
            (target as Backpack)._parent = _parent;
            target._position = _position;
          } else {
            _backpack!._open = true;
            _backpack!._inventory.remove(target);
            target._parent = _parent;
            target._position = _position;
          }
          _parent?._addThing(print, target, this);
        }
      case ClimbCommand(target: Atom target):
        if (target is SingletonAllAtom) {
          print('You cannot climb multiple things at once!\n');
        } else if (_accessibleAtomsTowardsLeaves(true).contains(target) ||
            target == this) {
          print('You cannot climb something if it would cause recursion!\n');
        } else if (target == _parent) {
          print(
              'You are already on ${target.toStringFromPerspective(this)}!\n');
        } else if (!target.hasSurface(this)) {
          print('You cannot climb ${target.toStringFromPerspective(this)}!\n');
        } else {
          print('You climb ${target.toStringFromPerspective(this)}.\n');
          _moveThing(print, this, target, RelativePosition.onParent, this);
        }
      case EnterCommand(target: Atom target):
        if (target is SingletonAllAtom) {
          print('You cannot enter multiple things at once!\n');
        } else if (target is! Thing) {
          print('You cannot enter ${target.toStringFromPerspective(this)}!\n');
        } else if (!target.open) {
          print(
              'You cannot enter ${target.toStringFromPerspective(this)}, it\'s closed!\n');
        } else if (target is Container) {
          // you don't want to end up directly in the container, so this puts you on its ground
          if (_parent == target.ground) {
            print(
                'You are already in ${target.toStringFromPerspective(this)}!\n');
          } else {
            print('(climbing ${target.ground})\n');
            handleCommand(ClimbCommand(target.ground), print);
          }
        } else if (target.parents.contains(this)) {
          print('You cannot enter something if it would cause recursion!\n');
        } else if (!target.hasInterior) {
          print(
              'You cannot enter ${target.toStringFromPerspective(this)}, it has no interior or is closed!\n');
        } else if (target == _parent) {
          print(
              'You are already in ${target.toStringFromPerspective(this)}!\n');
        } else {
          print('You enter ${target.toStringFromPerspective(this)}.\n');
          _moveThing(print, this, target, RelativePosition.inParent, this);
        }
      case CloseCommand(target: Atom target):
        if (target is SingletonAllAtom) {
          for (Atom atom in accessibleAtoms()) {
            if (atom is! Container || !atom.open) continue;
            print('\n${atom.toStringFromPerspective(this)}:\n');
            handleCommand(CloseCommand(atom), print);
          }
        } else if (target is! Container) {
          print('You cannot close something that is not a container!\n');
        } else if (!target._open) {
          print(
              'You cannot close ${target.toStringFromPerspective(this)}, it is already closed!\n');
        } else {
          print('You close ${target.toStringFromPerspective(this)}.\n');
          target._open = false;
        }
      case OpenCommand(target: Atom target):
        if (target is SingletonAllAtom) {
          for (Atom atom in accessibleAtoms()) {
            if (atom is! Container) continue;
            print('\n${atom.toStringFromPerspective(this)}:\n');
            handleCommand(OpenCommand(atom), print);
          }
        } else if (target is! Container) {
          print('You cannot open something that is not a container!\n');
        } else if (target._open) {
          print(
              'You cannot open ${target.toStringFromPerspective(this)}, it is already open!\n');
        } else if (!target.openable) {
          print('You cannot open ${target.toStringFromPerspective(this)}!\n');
        } else {
          print('You open ${target.toStringFromPerspective(this)}.\n');
          target._open = true;
        }
      case PutOnCommand(source: Atom src, dest: Atom dest):
        if (src is SingletonAllAtom) {
          for (Thing thing in accessibleAtoms().whereType()) {
            print(
                '\n${thing.toStringFromPerspective(this)} on ${dest.toStringFromPerspective(this)}:\n');
            handleCommand(PutOnCommand(thing, dest), print);
            if (_inventory.contains(thing)) {
              print('(dropping ${thing.toStringFromPerspective(this)})\n');
              handleCommand(DropCommand(thing), print);
            }
          }
          break;
        }
        if (!_inventory.contains(src)) {
          print('(first taking ${src.toStringFromPerspective(this)})\n');
          handleCommand(TakeCommand(src, false), print);
          if (_backpack == src) {
            handleCommand(TakeCommand(src, false), print);
          }
        }
        if (dest is SingletonAllAtom) {
          print('You cannot put something on multiple things at once!\n');
        } else if (!_inventory.contains(src) && src is! SingletonAllAtom) {
          // do nothing, the take above printed the error
        } else if (src._accessibleAtomsTowardsLeaves(true).contains(dest) ||
            dest == src) {
          print(
              'You cannot put something on something if it would cause recursion!\n');
        } else {
          print(
              'You put ${src.toStringFromPerspective(this)} on ${dest.toStringFromPerspective(this)}.\n');
          _moveThing(
              print, src as Thing, dest, RelativePosition.onParent, this);
        }

      case PutInCommand(source: Atom src, dest: Atom dest):
        if (src is SingletonAllAtom) {
          for (Atom atom in accessibleAtoms()) {
            print(
                '\n${atom.toStringFromPerspective(this)} in ${dest.toStringFromPerspective(this)}:\n');
            handleCommand(PutInCommand(atom, dest), print);
            if (_inventory.contains(atom)) {
              print('(dropping ${atom.toStringFromPerspective(this)})\n');
              handleCommand(DropCommand(atom), print);
            }
          }
          break;
        }
        if (!_inventory.contains(src)) {
          print('(first taking ${src.toStringFromPerspective(this)})\n');
          handleCommand(TakeCommand(src, false), print);
          if (_backpack == src) {
            handleCommand(TakeCommand(src, false), print);
          }
        }
        if (dest is SingletonAllAtom) {
          print('You cannot put something in multiple things at once!\n');
        } else if (!_inventory.contains(src)) {
          // do nothing, the take above printed the error
        } else if (dest is! Thing) {
          print(
              'You cannot put something on ${dest.toStringFromPerspective(this)}!\n');
        } else if (!dest.hasInterior &&
            !indirectly(RelativePosition.inParent, dest)) {
          print(
              '${dest.toStringFromPerspective(this)} does not have an interior, or is not open!\n');
        } else if (src._accessibleAtomsTowardsLeaves(true).contains(dest) ||
            dest == src) {
          print(
              'You cannot put something in something if it would cause recursion!\n');
        } else if (dest is Container) {
          print(
              '(putting ${src.toStringFromPerspective(this)} on ${dest.ground})\n');
          handleCommand(PutOnCommand(src, dest.ground), print);
        } else {
          print(
              'You put ${src.toStringFromPerspective(this)} in ${dest.toStringFromPerspective(this)}.\n');
          _moveThing(
              print, src as Thing, dest, RelativePosition.inParent, this);
        }
      case LookDirCommand(dir: Direction dir):
        rootT<Ground>()._side1Parent!._surfaces[dir]!.describe(this, print);
      case EastCommand():
        Surface surface =
            rootT<Ground>()._side1Parent!._surfaces[Direction.east]!;
        if (surface is OpeningSurface) {
          handleCommand(EnterCommand(surface._side2Parent!), print);
        } else {
          print(
              '${capitalizeFirst(surface.toStringFromPerspective(this))} blocks the way.\n');
        }
      case WestCommand():
        Surface surface =
            rootT<Ground>()._side1Parent!._surfaces[Direction.west]!;
        if (surface is OpeningSurface) {
          handleCommand(EnterCommand(surface._side1Parent!), print);
        } else {
          print(
              '${capitalizeFirst(surface.toStringFromPerspective(this))} blocks the way.\n');
        }
    }
  }

  Person._(super.parent, super.position, super.print, this.name) : super._();
  final String name;

  @override
  Set<Atom> accessibleAtoms() => _parent!.accessibleAtoms();

  @override
  String toStringFromPerspective(Thing perspective) => name;

  @override
  void describe(Thing perspective, void Function(Object?) print) {
    print('This is $this.\n');
    for (Thing thing in _inventory) {
      print(
          '$this is holding ${thing.toStringFromPerspective(perspective)}.\n');
    }
    if (_backpack != null) {
      print('$_backpack is on $this.\n');
    }
  }

  @override
  Set<Thing> _accessibleChildren(bool? side1) => {
        if (_backpack != null) _backpack!,
        ..._inventory,
      };

  @override
  bool stringRepresentsThis(String str) {
    return str.toLowerCase() == name.toLowerCase() || str.toLowerCase() == 'me';
  }

  @override
  void _addThing(void Function(Object?) print, Thing thing, Thing perspective) {
    assert(false);
  }

  @override
  void _removeThing(
      void Function(Object?) print, Thing thing, Thing perspective) {
    if (thing._position == RelativePosition.heldByParent) {
      // we're holding it
      bool removed = _inventory.remove(thing);
      assert(removed, 'contract violation');
    } else if (thing._position == RelativePosition.inParent) {
      // it's in the backpack
      _backpack!._removeThing(print, thing, this);
    } else {
      // it's the backpack
      _backpack = null;
    }
  }

  @override
  bool get hasInterior => false;

  @override
  bool get open => true;

  @override
  Set<Thing> get _allChildren => _accessibleChildren(null);

  @override
  bool hasSurface(Thing perspective) {
    return false;
  }
}

void _moveThing(void Function(Object?) print, Thing thing, Atom targetParent,
    RelativePosition targetPosition, Thing perspective) {
  assert(targetParent != thing._parent);
  thing._parent?._removeThing(print, thing, perspective);
  assert(!(thing._parent?._allChildren.contains(thing) ?? false));
  Atom? oldParent = thing._parent;
  thing._parent = targetParent;
  thing._position = targetPosition;
  targetParent._addThing(print, thing, perspective);
  assert(!(oldParent?._allChildren.contains(thing) ?? false),
      '${targetParent.toStringFromPerspective(thing)} ${thing.toStringFromPerspective(thing)}');
}

String capitalizeFirst(String string) =>
    string.replaceRange(0, 1, string[0].toUpperCase());
