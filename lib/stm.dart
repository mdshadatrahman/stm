library stm;

import 'package:flutter/material.dart';

class Ref {
  Ref();
  final Map<Setme, Element> _elements = {};

  final Map<Setme, Set<Setme>> _graph = {};

  Element _element<T>(Setme setme) => _elements.putIfAbsent(setme, () => setme._createElement(this));

  T watch<T>(Setme<T> setme, Setme? watcher) {
    if (watcher != null) {
      (_graph[setme] ??= {}).add(watcher);
    }
    return _element<T>(setme).state;
  }

  void set<T>(Setme<T> setme, T state) {
    final element = _element<T>(setme);
    if (state != element.state) {
      element.state = state;
      _onStatehange(setme);
    }
  }

  void update<T>(Setme<T> setme, T Function(T) update) {
    set<T>(setme, update(_element(setme).state));
  }

  void _onStatehange(Setme setme) {
    for (final c in _graph[setme] ?? {}) {
      _element(c).recreate();
    }
  }

  void recreate(Setme setme) {
    _element(setme).recreate();
  }

  void dispose(Setme setme) {
    if ((_graph[setme] ?? {}).isNotEmpty) {
      return;
    }
    _elements.remove(setme);
    _graph.remove(setme);
    for (final c in _elements.keys.toSet()) {
      if ((_graph[c] ?? {}).contains(setme)) {
        _graph[c]!.remove(setme);
        dispose(c);
      }
    }
  }
}

class Setme<T> {
  const Setme(this.create);
  final T Function(Ref ref, Setme<T> slef) create;
  Element<T> _createElement(Ref ref) => Element<T>(ref, this);
}

class Element<T> {
  Element(this.ref, this.setme) : state = setme.create(ref, setme);

  final Ref ref;
  final Setme<T> setme;
  T state;
  void recreate() {
    final newState = setme.create(ref, setme);
    if (newState != state) {
      state = newState;
      ref._onStatehange(setme);
    }
  }
}

class SetmeGraph extends InheritedWidget {
  SetmeGraph({super.key, required Widget child})
      : ref = Ref(),
        super(child: child);

  final Ref ref;

  static SetmeGraph? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SetmeGraph>();
  }

  @override
  bool updateShouldNotify(SetmeGraph oldWidget) {
    return ref != oldWidget.ref;
  }
}

class Listenme extends StatefulWidget {
  const Listenme(this.builder, {super.key});

  final Widget Function(BuildContext context, Ref ref, Setme self)? builder;

  @override
  State<Listenme> createState() => _ListenmeState();
}

class _ListenmeState extends State<Listenme> {
  late Setme<Widget> builder;
  late Ref ref;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ref = SetmeGraph.of(context)!.ref;
    builder = Setme((ref, self) {
      setState(() {});
      return widget.builder!(context, ref, self);
    });
  }

  @override
  void dispose() {
    ref.dispose(builder);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ref.watch(builder, null);
  }
}

extension ContextRef on BuildContext {
  Ref get ref => SetmeGraph.of(this)!.ref;
}
