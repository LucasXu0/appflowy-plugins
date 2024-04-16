import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';

void main() {
  runApp(const AppWidget());
}

class AppWidget extends StatefulWidget {
  const AppWidget({super.key});

  @override
  State<AppWidget> createState() => _AppWidgetState();
}

class _AppWidgetState extends State<AppWidget> {
  ThemeData theme = ThemeData.light();

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plugins',
      theme: theme,
      home: Editor(
        toggleBrightness: () => setState(
          () => theme = theme.brightness == Brightness.light
              ? ThemeData.dark()
              : ThemeData.light(),
        ),
      ),
    );
  }
}

class Editor extends StatefulWidget {
  const Editor({super.key, required this.toggleBrightness});

  final VoidCallback toggleBrightness;

  @override
  State<Editor> createState() => _EditorState();
}

class _EditorState extends State<Editor> {
  late final EditorState editorState;
  late final List<CharacterShortcutEvent>? shortcutEvents;
  late final List<CommandShortcutEvent>? commandEvents;
  late final Map<String, BlockComponentBuilder>? blockComponentBuilders;

  @override
  void initState() {
    super.initState();
    editorState = EditorState(
      document: Document.fromJson(jsonDecode(_initialDocumentData)),
    );

    shortcutEvents = [
      ...codeBlockCharacterEvents,
      ...standardCharacterShortcutEvents,
    ];

    commandEvents = [
      ...codeBlockCommands(),
      ...standardCommandShortcutEvents.where(
        (event) => event != pasteCommand, // Remove standard paste command
      ),
      linkPreviewCustomPasteCommand, // Add link preview paste command
      convertUrlToLinkPreviewBlockCommand,
    ];

    blockComponentBuilders = {
      ...standardBlockComponentBuilderMap,
      CodeBlockKeys.type: CodeBlockComponentBuilder(
        editorState: editorState,
        configuration: BlockComponentConfiguration(
          textStyle: (_) => const TextStyle(
            fontFamily: 'RobotoMono',
            fontSize: 14,
            height: 1.5,
          ),
        ),
        styleBuilder: () => CodeBlockStyle(
          backgroundColor: Theme.of(context).brightness == Brightness.light
              ? Colors.grey[200]!
              : Colors.grey[800]!,
          foregroundColor: Theme.of(context).brightness == Brightness.light
              ? Colors.blue
              : Colors.blue[800]!,
        ),
        actions: CodeBlockActions(
          onCopy: (code) => Clipboard.setData(ClipboardData(text: code)),
        ),
      ),
      LinkPreviewBlockKeys.type: LinkPreviewBlockComponentBuilder(
        showMenu: true,
        menuBuilder: (context, node, state) => Positioned(
          top: 8,
          right: 4,
          child: SizedBox(
            height: 32.0,
            child: InkWell(
              borderRadius: BorderRadius.circular(4.0),
              onTap: () => Clipboard.setData(ClipboardData(
                  text: node.attributes[LinkPreviewBlockKeys.url])),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.copy, size: 18.0),
              ),
            ),
          ),
        ),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor Plugins'),
        actions: [
          IconButton(
            onPressed: widget.toggleBrightness,
            icon: Icon(
              Theme.of(context).brightness == Brightness.light
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
          ),
        ],
      ),
      body: AppFlowyEditor(
        editorState: editorState,
        characterShortcutEvents: shortcutEvents,
        commandShortcutEvents: commandEvents,
        blockComponentBuilders: blockComponentBuilders,
      ),
    );
  }
}

const _initialDocumentData = """{
  "document": {
    "type": "page",
    "children": [
      {
        "type": "paragraph",
        "data": {"delta": []}
      },
      {
        "type": "code",
        "data": {"delta": []}
      },
      {
        "type": "paragraph",
        "data": {"delta": []}
      }
    ]
  }
}""";
