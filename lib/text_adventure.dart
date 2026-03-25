import 'dart:core' hide print;
part 'world_creation.dart';

sealed class Atom {
  const Atom();

  /// Returns the children of this atom that can be seen from the outside of this atom.
  Set<Atom> _accessibleChildren();

  /// Returns all the children of this atom.
  Set<Atom> get _allChildren;

  /// Returns all children that can be seen by [perspective].
  // If you can see out of this atom, it defers to the parent. Otherwise, it just calls [_accessibleAtomsTowardsLeaves].
  Set<Atom> accessibleAtoms(Thing perspective);

  /// A noun phrase that describes the atom.
  @override
  String toString() => '<$runtimeType>';

  /// Prints this atom's parent chain up to an atom you can't see out of.
  void printPosition(
    void Function(Object?) print,
    bool addComma,
    Thing perspective,
  );

  /// Returns a detailed description of the atom.
  void describe(Thing perspective, void Function(Object?) print);

  /// Returns whether or not you can put something on this atom.
  bool hasAccessibleSurface(Thing perspective);

  /// All (visible if [includeHiddenAtoms] is false) descendants of this atom, including itself.
  Set<Atom> _accessibleAtomsTowardsLeaves(bool includeHiddenAtoms) =>
      (includeHiddenAtoms ? _allChildren : _accessibleChildren())
          .expand(
            (element) =>
                element._accessibleAtomsTowardsLeaves(includeHiddenAtoms),
          )
          .toSet()
        ..add(this);

  bool stringRepresentsThis(String str);

  void _addThing(void Function(Object?) print, Thing thing, Thing perspective);
  void _removeThing(
    void Function(Object?) print,
    Thing thing,
    Thing perspective,
  );

  /// Walks up the tree to find the first [T]
  T rootT<T extends Atom>() {
    final Atom atom = this;
    return atom is T
        ? atom
        : atom is Thing
        ? atom._parent?.rootT<T>() ??
              (throw StateError('$runtimeType with no parent'))
        : atom is Surface
        ? atom._parent.rootT<T>()
        : (throw UnimplementedError('non-thing-or-surface'));
  }

  void listChildren(
    void Function(Object?) print,
    int indent,
    Thing perspective,
  );
}

enum RelativePosition { heldByParent, inParent, onParent }

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
  const SingletonAllAtom._();
  static const SingletonAllAtom instance = SingletonAllAtom._();
  factory SingletonAllAtom() {
    return instance;
  }
  @override
  Set<Atom> _accessibleChildren() =>
      throw UnsupportedError('SingletonAllAtom._accessibleChildren');
  @override
  void listChildren(
    void Function(Object?) print,
    int indent,
    Thing perspective,
  ) => throw UnsupportedError('SingletonAllAtom.listChildren');
  @override
  Set<Atom> get _allChildren =>
      throw UnsupportedError('SingletonAllAtom._accessibleChildren');

  @override
  void _addThing(void Function(Object?) print, Thing thing, Thing perspective) {
    throw UnsupportedError('SingletonAllAtom._addThing');
  }

  @override
  void _removeThing(
    void Function(Object?) print,
    Thing thing,
    Thing perspective,
  ) {
    throw UnsupportedError('SingletonAllAtom._removeThing');
  }

  @override
  Set<Atom> accessibleAtoms(Thing perspective) =>
      throw UnsupportedError('SingletonAllAtom.accessibleAtoms()');

  @override
  Set<Atom> _accessibleAtomsTowardsLeaves(bool includeHiddenAtoms) =>
      throw UnsupportedError('SingletonAllAtom.accessibleAtomsTowardsLeaves');

  @override
  void printPosition(
    void Function(Object p1) print,
    bool addComma,
    Thing perspective,
  ) {
    throw UnsupportedError('SingletonAllAtom.printPosition');
  }

  @override
  bool stringRepresentsThis(String str) {
    throw UnsupportedError('SingletonAllAtom.stringRepresentsThis');
  }

  @override
  String toString() => '<all>';

  @override
  void describe(Thing perspective, void Function(Object? p1) print) {
    throw UnsupportedError('SingletonAllAtom.describe');
  }

  @override
  bool hasAccessibleSurface(Thing perspective) {
    throw UnsupportedError('SingletonAllAtom.hasSurface');
  }
}

enum Direction { up, down, north, east, south, west }

typedef SurfacePair = (Surface inside, Surface outside);
typedef SurfaceMap = Map<Direction, SurfacePair>;

SurfaceMap surfaces(Thing thing) {
  // TODO: maybe make these connectedsurfaces?
  return {
    Direction.up: (Ceiling._(thing), Ground._(thing)),
    Direction.down: (Ground._(thing), Ceiling._(thing)),
    Direction.north: (Surface._(thing), Surface._(thing)),
    Direction.east: (Surface._(thing), Surface._(thing)),
    Direction.south: (Surface._(thing), Surface._(thing)),
    Direction.west: (Surface._(thing), Surface._(thing)),
  };
}


// TODO: consider merging with Container
abstract class Thing extends Atom {
  Atom? _parent;
  RelativePosition _position;
  final (int, int, int) localGridPosition;
  late final SurfaceMap _surfaces;
  Ground get top => _surfaces[Direction.up]!.$2 as Ground;

  /// Whether you can put things in this thing.
  bool get hasInterior;
  bool get open;
  bool get portable;

  Set<Atom> get parents => {
    if (_parent != null) ...{
      _parent!,
      if (_parent is Thing) ...(_parent as Thing).parents,
      if (_parent is Surface) ...{
        (_parent as Surface)._parent,
        ...(_parent as Surface)._parent.parents,
      },
    },
  };

  bool indirectly(RelativePosition position, Atom potentialAncestor) {
    // indirectly <on/in/held by> <atom>
    if (_parent == potentialAncestor) {
      return position == _position;
    }
    if (_parent is Ground) {
      Ground parent = _parent as Ground;
      if (parent._parent == potentialAncestor) {
        if (parent._parent._surfaces[Direction.down]!.$1 == parent) {
          return position == RelativePosition.inParent;
        } else {
          assert(parent._parent._surfaces[Direction.up]!.$2 == parent);
          return position == RelativePosition.onParent;
        }
      } else {
        return parent._parent.indirectly(position, potentialAncestor);
      }
    }
    return _parent is Thing
        ? (_parent as Thing).indirectly(position, potentialAncestor)
        : false;
  }

  // TODO: maybe not put such a specific function in Thing
  Container container() {
    Thing thing = this;
    Container container = thing.rootT<Container>();
    while (true) {
      if (thing.indirectly(RelativePosition.onParent, container)) {
        container = container.rootT<Container>();
      } else {
        assert(thing.indirectly(RelativePosition.inParent, container));
        return container;
      }
    }
  }

  @override
  void printPosition(
    void Function(Object?) print,
    bool addComma,
    Thing perspective,
  ) {
    if (addComma) print(', ');
    print('${positionToString(_position)} ${_parent!}');
    _parent!.printPosition(print, true, perspective);
  }

  @override
  void _addThing(void Function(Object?) print, Thing thing, Thing perspective) {
    switch (thing._position) {
      case RelativePosition.onParent:
        top._children.add(thing);
      default:
        assert(false);
    }
  }

  @override
  void _removeThing(
    void Function(Object?) print,
    Thing thing,
    Thing perspective,
  ) {
    switch (thing._position) {
      case RelativePosition.onParent:
        top._children.remove(thing);
      default:
        assert(false);
    }
  }

  @override
  Set<Atom> _accessibleChildren() =>
    _surfaces.values.expand((e) => [if (open) e.$1, e.$2]).toSet();

  @override
  Set<Atom> get _allChildren =>
      _surfaces.values.expand((e) => [e.$1, e.$2]).toSet();

  Thing._(
    this._parent,
    this._position,
    void Function(Object?) print, [
    this.localGridPosition = (0, 0, 0),
    SurfaceMap? _surfaces,
  ]) {
    this._surfaces = _surfaces ?? surfaces(this);
    _parent?._addThing(print, this, this);
  }
}

class Surface extends Atom {
  final Thing _parent;
  Surface._(this._parent);

  @override
  Set<Atom> _accessibleChildren() {
    return {};
  }

  @override
  void listChildren(
    void Function(Object?) print,
    int indent,
    Thing perspective,
  ) {}

  @override
  void _addThing(void Function(Object?) print, Thing thing, Thing perspective) {
    throw UnsupportedError('Surface._addThing');
  }

  @override
  Set<Atom> get _allChildren => {};

  @override
  void _removeThing(
    void Function(Object?) print,
    Thing thing,
    Thing perspective,
  ) {
    throw UnsupportedError('Surface._removeThing');
  }

  @override
  Set<Atom> accessibleAtoms(Thing perspective) {
    return _parent.accessibleAtoms(perspective);
  }

  @override
  void describe(Thing perspective, void Function(Object?) print) {
    print('This is a wall.\n');
  }

  @override
  bool hasAccessibleSurface(Thing perspective) {
    return false;
  }

  @override
  void printPosition(
    void Function(Object?) print,
    bool addComma,
    Thing perspective,
  ) {
    if (addComma) print(', ');
    print('part of $_parent');
    _parent.printPosition(print, true, perspective);
  }

  @override
  bool stringRepresentsThis(String str) {
    return str.toLowerCase() == 'wall' || str.toLowerCase() == 'the wall';
  }

  @override
  String toString() {
    return 'the wall';
  }
}

class Ground extends Surface {
  Ground._(super.parent) : super._();
  final Set<Thing> _children = {};

  @override
  Set<Atom> _accessibleChildren() {
    return _children;
  }

  @override
  void listChildren(
    void Function(Object?) print,
    int indent,
    Thing perspective,
  ) {
    for (Thing child in _children) {
      if (child != perspective) {
        print(
          '${'  ' * indent}$child (${positionToString(child._position)})\n',
        );
        child.listChildren(print, indent + 1, perspective);
      }
    }
  }

  @override
  void _addThing(void Function(Object?) print, Thing thing, Thing perspective) {
    assert(thing._position == RelativePosition.onParent);
    _children.add(thing);
  }

  @override
  Set<Atom> get _allChildren => _children;

  @override
  void _removeThing(
    void Function(Object?) print,
    Thing thing,
    Thing perspective,
  ) {
    bool removed = _children.remove(thing);
    assert(removed);
  }

  @override
  void describe(Thing perspective, void Function(Object?) print) {
    print('This is a flat surface.\n');
    print('On the ground, you see:\n');
    for (Thing child in _children) {
      if (child != perspective) {
        print('  $child\n');
        child.listChildren(print, 2, perspective);
      }
    }
  }

  @override
  bool hasAccessibleSurface(Thing perspective) {
    return true;
  }

  @override
  bool stringRepresentsThis(String str) {
    return str.toLowerCase() == 'ground' || str.toLowerCase() == 'the ground';
  }

  @override
  String toString() {
    return 'the ground';
  }
}

class Ceiling extends Surface {
  Ceiling._(super.parent) : super._();

  @override
  void describe(Thing perspective, void Function(Object?) print) {
    print('This is the ceiling.\n');
  }

  @override
  bool hasAccessibleSurface(Thing perspective) {
    return false;
  }

  @override
  bool stringRepresentsThis(String str) {
    return str.toLowerCase() == 'ceiling' || str.toLowerCase() == 'the ceiling';
  }

  @override
  String toString() {
    return 'the ceiling';
  }
}

class ConnectedSurface extends Surface {
  late final ConnectedSurface _otherSide;
  ConnectedSurface._(super.parent) : super._();
}

class OpeningSurface extends ConnectedSurface {
  OpeningSurface._(super.parent) : super._();

  // TODO: think about the consequences of seeing the room but not its children
  @override
  Set<Atom> _accessibleAtomsTowardsLeaves(bool includeHiddenAtoms) {
    return {this, _otherSide._parent};
  }

  @override
  void describe(Thing perspective, void Function(Object?) print) {
    print('This is a wall with a hole in it.\n');
    print('Through the hole you see ${_otherSide._parent}.\n');
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
  Set<Atom> _accessibleChildren() =>
      (open ? _inventory : <Thing>{}) + _surfaceChildren;

  @override
  Set<Atom> get _allChildren => _inventory + _surfaceChildren;

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
    this.portable = true,
    this.openable = true,
    super.localGridPosition,
    super._surfaces,
  ]) : super._();

  final String name;
  final RegExp nameRegex;
  final String description;
  @override
  final bool portable;
  @override
  String toString() => name;

  final int capacity;
  bool _open = false;
  @override
  bool get open => _open;
  final bool openable;

  Ceiling get ceiling => _surfaces[Direction.up]!.$1 as Ceiling;
  Ground get ground => _surfaces[Direction.down]!.$1 as Ground;

  @override
  void describe(Thing perspective, void Function(Object?) print) {
    print("$description\n");
    if (top._children.isNotEmpty &&
        (open || !perspective.parents.contains(ground))) {
          // TODO: connecting rooms
      print("\nOn $this, you see the following:\n");
      for (Thing child in top._children) {
        if (child != perspective) {
          print('  $child\n');
          child.listChildren(print, 2, perspective);
        }
      }
    }
    if ((_open && ground._children.isNotEmpty) ||
        perspective.parents.contains(ground)) {
      print("\nIn $this, you see the following:\n");
      for (Thing child in ground._children) {
        if (child != perspective) {
          print('  $child\n');
          child.listChildren(print, 2, perspective);
        }
      }
    }
  }

  @override
  void printPosition(
    void Function(Object?) print,
    bool addComma,
    Thing perspective,
  ) {
    if (open || !inInventoryOrAdjoiningRoom(perspective)) {
      if (addComma) print(', ');
      if (_parent == null) {
        // not supposed to happen, but "debug find all" triggers it
        print('in the void');
      } else {
        print('${positionToString(_position)} ${_parent!}');
        _parent!.printPosition(print, true, perspective);
      }
    } else if (!addComma) {
      print('somewhere');
    }
  }

  @override
  Set<Atom> accessibleAtoms(Thing perspective) =>
      open || !inInventoryOrAdjoiningRoom(perspective)
      ? _parent!.accessibleAtoms(perspective)
      : (ground._children
                .map((e) => e._accessibleAtomsTowardsLeaves(false))
                .expand((element) => element)
                .toSet() +
            {
              ..._surfaces.values
                  .map((e) => e.$1._accessibleAtomsTowardsLeaves(false))
                  .expand((element) => element),
              this,
            });

  @override
  bool stringRepresentsThis(String str) {
    return nameRegex.hasMatch(str);
  }

  @override
  bool get hasInterior => open;

  @override
  void _addThing(void Function(Object?) print, Thing thing, Thing perspective) {
    switch (thing._position) {
      case RelativePosition.inParent:
        ground._children.add(thing);
      default:
        super._addThing(print, thing, perspective);
    }
  }

  @override
  void _removeThing(
    void Function(Object?) print,
    Thing thing,
    Thing perspective,
  ) {
    switch (thing._position) {
      case RelativePosition.inParent:
        ground._children.remove(thing);
      default:
        super._removeThing(print, thing, perspective);
    }
  }

  @override
  bool hasAccessibleSurface(Thing perspective) {
    return open || !inInventoryOrAdjoiningRoom(perspective);
  }

  bool inInventoryOrAdjoiningRoom(Thing perspective) {
    return inInventory(perspective) ||
        _surfaces.values.any(
          (e) =>
              perspective.indirectly(RelativePosition.inParent, e.$2._parent),
        );
  }

  bool inInventory(Thing perspective) {
    return ground._children.any(
      (e) => e._accessibleAtomsTowardsLeaves(true).contains(perspective),
    );
  }

  @override
  void listChildren(
    void Function(Object?) print,
    int indent,
    Thing perspective,
  ) {
    if (open || inInventoryOrAdjoiningRoom(perspective)) {
      for (Thing child in ground._children) {
        if (child != perspective) {
          print('${'  ' * indent}$child (in)\n');
          child.listChildren(print, indent + 1, perspective);
        }
      }
    }
    if (open || !inInventoryOrAdjoiningRoom(perspective)) {
      for (Thing child in top._children) {
        if (child != perspective) {
          print('${'  ' * indent}$child (on)\n');
          child.listChildren(print, indent + 1, perspective);
        }
      }
    }
  }
}

class Button extends Thing {
  Button._(super.parent, super.position, super.print, this._wall) : super._();
  ConnectedSurface get wall => _wall;
  ConnectedSurface _wall;
  void activate(void Function(Object?) print, Thing perspective) {
    if (wall is! OpeningSurface) {
      print('${capitalizeFirst(wall.toString())} turns into an opening.\n');
      OpeningSurface openingWallSide = OpeningSurface._(wall._parent);
      OpeningSurface openingOtherSide = OpeningSurface._(
        wall._otherSide._parent,
      );
      openingWallSide._otherSide = openingOtherSide;
      openingOtherSide._otherSide = openingWallSide;
      Direction wallSideDir = wall._parent._surfaces.entries
          .singleWhere((element) => element.value.$1 == wall)
          .key;
      Direction otherSideDir = wall._otherSide._parent._surfaces.entries
          .singleWhere((element) => element.value.$1 == wall._otherSide)
          .key;
      wall._parent._surfaces[wallSideDir] = (openingWallSide, openingOtherSide);
      wall._otherSide._parent._surfaces[otherSideDir] = (
        openingOtherSide,
        openingWallSide,
      );
      _wall = openingWallSide;
    }
  }

  @override
  Set<Atom> _accessibleChildren() {
    return _allChildren.toSet();
  }

  @override
  void listChildren(
    void Function(Object?) print,
    int indent,
    Thing perspective,
  ) {
    for (Thing child in _allChildren.whereType()) {
      if (child != perspective) {
        print(
          '${'  ' * indent}$child (${positionToString(child._position)})\n',
        );
        child.listChildren(print, indent + 1, perspective);
      }
    }
  }

  @override
  String toString() {
    return 'the button';
  }

  @override
  void _addThing(void Function(Object?) print, Thing thing, Thing perspective) {
    super._addThing(print, thing, perspective);
    activate(print, perspective);
  }

  @override
  void _removeThing(
    void Function(Object?) print,
    Thing thing,
    Thing perspective,
  ) {
    bool wasChild = _allChildren.remove(thing);
    assert(wasChild);
  }

  @override
  Set<Atom> accessibleAtoms(Thing perspective) {
    return _parent!.accessibleAtoms(perspective);
  }

  @override
  void describe(Thing perspective, void Function(Object? p1) print) {
    print("This is a button.\n");
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
  bool hasAccessibleSurface(Thing perspective) {
    return true;
  }

  @override
  bool get portable => true;
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
          if (_backpack!._open) {
            print(' and are wearing a backpack containing:\n');
            for (Thing thing in _backpack!.ground._children) {
              print('$thing\n');
            }
          } else {
            print(' and are wearing a closed backpack.\n');
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
          (_parent as Surface)._parent.describe(this, print);
        }
      case LookAtCommand(target: Atom target):
        if (target is SingletonAllAtom) {
          for (Atom atom in accessibleAtoms(this)) {
            if (atom is Surface) continue;
            print('\n$atom:\n');
            handleCommand(LookAtCommand(atom), print);
          }
          break;
        }
        print('(');
        if (target is Ground) {
          if (indirectly(RelativePosition.onParent, target)) {
            print('the ground');
          } else if (target._parent.indirectly(
            RelativePosition.onParent,
            rootT<Ground>(),
          )) {
            // TODO: maybe more clear?
            print('inside something in this room');
          } else {
            // TODO: maybe more clear?
            print('outside of ${rootT<Ground>()._parent}');
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
          for (Atom atom
              in accessibleAtoms(this)..removeAll(
                _backpack?._accessibleAtomsTowardsLeaves(false) ?? <Atom>[],
              )) {
            if (atom is Surface) continue;
            if (atom == this) continue;
            assert(atom is Thing);
            if (!(atom as Thing).portable) continue;
            print('\n$atom:\n');
            handleCommand(TakeCommand(atom), print);
          }
        } else if (target is! Thing) {
          assert(target is Surface);
          print('You cannot take a wall or floor or ceiling!\n');
        } else if (!target.portable) {
          print('You cannot take $target!\n');
        } else if (parents.contains(target) || target == this) {
          print('You cannot take something if it would cause recursion!\n');
        } else if (_inventory.isNotEmpty && _backpack == null) {
          if (_inventory.single is Backpack && _inventory.contains(target)) {
            print('You put it on your back.\n');
            _backpack = target as Backpack;
            target._position = RelativePosition.onParent;
            _inventory.remove(target);
          } else if (_inventory.contains(target)) {
            print('You are already holding $target!\n');
          } else if (target is Backpack) {
            print('(first dropping ${_inventory.single})\n');
            handleCommand(DropCommand(_inventory.single), print);
            handleCommand(TakeCommand(target), print);
          } else {
            print(
              'You are already holding something! Maybe consider getting a backpack?\n',
            );
            for (Atom a in accessibleAtoms(this)) {
              if (a is Backpack) {
                print('There is a backpack ');
                a.printPosition(print, false, this);
                print('.\n');
              }
            }
          }
        } else if (_backpack == null || !pib) {
          if (target is Backpack && _backpack == null) {
            print('You put $target on your back.\n');
            _backpack = target;
          } else {
            print('You take $target.\n');
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
                'You are already holding something, and $target is already on your back!\n',
              );
            } else {
              print('You take $target off your back.\n');
              _backpack = null;
              _inventory.add(target);
              target._position = RelativePosition.heldByParent;
            }
          } else if (_backpack!.ground._children.length >= _backpack!.capacity) {
            if (_inventory.isNotEmpty) {
              print(
                'You are already holding something, and your backpack is full!\n',
              );
            } else {
              print('You take $target.\n');
              _inventory.add(target);
              target._parent?._removeThing(print, target, this);
              target._parent = this;
              target._position = RelativePosition.heldByParent;
            }
          } else if (_backpack!.ground._children.contains(target)) {
            if (_inventory.isEmpty) {
              print('You take $target from your backpack.\n');
              _inventory.add(target);
              target._parent?._removeThing(print, target, this);
              target._parent = this;
              target._position = RelativePosition.heldByParent;
            } else {
              print('You are already holding $target in your backpack!\n');
            }
          } else {
            print('You put $target in your backpack.\n');
            _backpack!._open = true;
            _moveThing(
              print,
              target,
              _backpack!,
              RelativePosition.inParent,
              this,
            );
          }
        }
      case DropCommand(target: Atom target):
        if (target is SingletonAllAtom) {
          for (Atom atom
              in _inventory +
                  (_backpack != null && _backpack!._open
                      ? _backpack!.ground._children
                      : {}) +
                  {if (_backpack != null) _backpack!}) {
            print('\n$atom:\n');
            handleCommand(DropCommand(atom), print);
          }
        } else if (target is! Thing) {
          print('You cannot drop a non-thing!\n');
        } else if (!_inventory.contains(target) &&
            !(_backpack?.ground._children.contains(target) ?? false) &&
            _backpack != target) {
          print('You are not holding $target!\n');
        } else {
          print('You drop $target.\n');
          if (_inventory.contains(target)) {
            _inventory.remove(target);
            target._parent = _parent;
            target._position = _position;
          } else if (target == _backpack) {
            _backpack = null;
            (target as Backpack)._parent = _parent;
            target._position = _position;
          } else {
            assert(_backpack!._open);
            _backpack!.ground._children.remove(target);
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
          print('You are already on $target!\n');
        } else if (!target.hasAccessibleSurface(this)) {
          print('You cannot climb $target!\n');
        } else {
          print('You climb $target.\n');
          _moveThing(print, this, target, RelativePosition.onParent, this);
        }
      case EnterCommand(target: Atom target):
        if (target is SingletonAllAtom) {
          print('You cannot enter multiple things at once!\n');
        } else if (target is! Thing) {
          print('You cannot enter $target!\n');
        } else if (target is Container) {
          // you don't want to end up directly in the container, so this puts you on its ground
          if (_parent == target.ground) {
            print('You are already in $target!\n');
          } else if (target.open || target.inInventoryOrAdjoiningRoom(this)) {
            print('(climbing ${target.ground})\n');
            handleCommand(ClimbCommand(target.ground), print);
          } else {
            print('You cannot enter $target, it\'s closed!\n');
          }
        } else if (!target.open) {
          print('You cannot enter $target, it\'s closed!\n');
        } else if (target.parents.contains(this)) {
          print('You cannot enter something if it would cause recursion!\n');
        } else if (!target.hasInterior) {
          print('You cannot enter $target, it has no interior!\n');
        } else if (target == _parent) {
          print('You are already in $target!\n');
        } else {
          print('You enter $target.\n');
          _moveThing(print, this, target, RelativePosition.inParent, this);
        }
      case CloseCommand(target: Atom target):
        if (target is SingletonAllAtom) {
          for (Atom atom in accessibleAtoms(this)) {
            if (atom is! Container || !atom.open) continue;
            print('\n$atom:\n');
            handleCommand(CloseCommand(atom), print);
          }
        } else if (target is! Container) {
          print('You cannot close something that is not a container!\n');
        } else if (!target._open) {
          print('You cannot close $target, it is already closed!\n');
        } else {
          print('You close $target.\n');
          target._open = false;
        }
      case OpenCommand(target: Atom target):
        if (target is SingletonAllAtom) {
          for (Atom atom in accessibleAtoms(this)) {
            if (atom is! Container) continue;
            if (!atom.openable) continue;
            print('\n$atom:\n');
            handleCommand(OpenCommand(atom), print);
          }
        } else if (target is! Container) {
          print('You cannot open something that is not a container!\n');
        } else if (target._open) {
          print('You cannot open $target, it is already open!\n');
        } else if (!target.openable) {
          print('You cannot open $target!\n');
        } else {
          print('You open $target.\n');
          target._open = true;
        }
      case PutOnCommand(source: Atom src, dest: Atom dest):
        if (src is SingletonAllAtom) {
          for (Thing thing in accessibleAtoms(this).whereType()) {
            print('\n$thing on $dest:\n');
            handleCommand(PutOnCommand(thing, dest), print);
            if (_inventory.contains(thing)) {
              print('(dropping $thing)\n');
              handleCommand(DropCommand(thing), print);
            }
          }
          break;
        }
        if (!_inventory.contains(src)) {
          print('(first taking $src)\n');
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
            'You cannot put something on something if it would cause recursion!\n',
          );
        } else if (!dest.hasAccessibleSurface(this)) {
          print('You cannot put something on $dest!\n');
        } else {
          print('You put $src on $dest.\n');
          _moveThing(
            print,
            src as Thing,
            dest,
            RelativePosition.onParent,
            this,
          );
        }

      case PutInCommand(source: Atom src, dest: Atom dest):
        if (src is SingletonAllAtom) {
          for (Thing thing in accessibleAtoms(this).whereType()) {
            print('\n$thing in $dest:\n');
            handleCommand(PutInCommand(thing, dest), print);
            if (_inventory.contains(thing)) {
              print('(dropping $thing)\n');
              handleCommand(DropCommand(thing), print);
            }
          }
          break;
        }
        if (!_inventory.contains(src)) {
          print('(first taking $src)\n');
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
          print('You cannot put something in $dest!\n');
        } else if (!dest.hasInterior &&
            !indirectly(RelativePosition.inParent, dest)) {
          print('${capitalizeFirst(dest.toString())} does not have an interior, or is not open!\n');
        } else if (src._accessibleAtomsTowardsLeaves(true).contains(dest) ||
            dest == src) {
          print(
            'You cannot put something in something if it would cause recursion!\n',
          );
        } else if (dest is Container) {
          print('(putting $src on ${dest.ground})\n');
          handleCommand(PutOnCommand(src, dest.ground), print);
        } else {
          print('You put $src in $dest.\n');
          _moveThing(
            print,
            src as Thing,
            dest,
            RelativePosition.inParent,
            this,
          );
        }
      case LookDirCommand(dir: Direction dir):
        rootT<Ground>()._parent._surfaces[dir]!.$1.describe(this, print);
      case EastCommand():
        SurfacePair wall = container()._surfaces[Direction.east]!;
        if (wall.$1 is OpeningSurface) {
          handleCommand(EnterCommand(wall.$2._parent), print);
        } else {
          print('${capitalizeFirst(wall.$1.toString())} blocks the way.\n');
        }
      case WestCommand():
        SurfacePair wall = container()._surfaces[Direction.west]!;
        if (wall.$1 is OpeningSurface) {
          handleCommand(EnterCommand(wall.$2._parent), print);
        } else {
          print('${capitalizeFirst(wall.$1.toString())} blocks the way.\n');
        }
    }
  }

  Person._(super.parent, super.position, super.print, this.name) : super._();
  final String name;

  @override
  Set<Atom> accessibleAtoms(Thing perspective) =>
      _parent!.accessibleAtoms(perspective);

  @override
  void listChildren(
    void Function(Object?) print,
    int indent,
    Thing perspective,
  ) {
    for (Thing child in _accessibleChildren().whereType()) {
      if (child != perspective) {
        print(
          '${'  ' * indent}$child (${positionToString(child._position)})\n',
        );
        child.listChildren(print, indent + 1, perspective);
      }
    }
  }

  @override
  String toString() => name;

  @override
  void describe(Thing perspective, void Function(Object?) print) {
    print('This is $this.\n');
    for (Thing thing in _inventory) {
      print('$this is holding $thing.\n');
    }
    if (_backpack != null) {
      print('$_backpack is on $this.\n');
    }
  }

  @override
  Set<Atom> _accessibleChildren() => {
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
    void Function(Object?) print,
    Thing thing,
    Thing perspective,
  ) {
    if (thing._position == RelativePosition.heldByParent) {
      // we're holding it
      bool removed = _inventory.remove(thing);
      assert(removed, 'contract violation');
    } else if (thing._position == RelativePosition.inParent) {
      // it's in the backpack
      _backpack!._removeThing(print, thing, this);
    } else {
      assert(thing == _backpack);
      // it's the backpack
      _backpack = null;
    }
  }

  @override
  bool get hasInterior => false;

  @override
  bool get open => true;

  @override
  Set<Atom> get _allChildren => _accessibleChildren();

  @override
  bool hasAccessibleSurface(Thing perspective) {
    return false;
  }

  @override
  bool get portable => true;
}

void _moveThing(
  void Function(Object?) print,
  Thing thing,
  Atom targetParent,
  RelativePosition targetPosition,
  Thing perspective,
) {
  assert(targetParent != thing._parent);
  thing._parent?._removeThing(print, thing, perspective);
  assert(!(thing._parent?._allChildren.contains(thing) ?? false));
  Atom? oldParent = thing._parent;
  assert(
    !(oldParent?._allChildren.contains(thing) ?? false),
    '$targetParent $thing',
  );

  thing._parent = switch (targetPosition) {
    .heldByParent => targetParent,
    .inParent => () {
      assert(targetParent is Container);
      return (targetParent as Container).ground;
    }(),
    .onParent => targetParent is Thing ? targetParent.top : targetParent,
  };
  thing._position = targetPosition;
  targetParent._addThing(print, thing, perspective);
}

String capitalizeFirst(String string) =>
    string.replaceRange(0, 1, string[0].toUpperCase());
