package hxParserVis;

import Vscode.*;
import js.node.Buffer;
import vscode.*;

class Main {
    var context:ExtensionContext;

    function new(context:ExtensionContext) {
        this.context = context;

        var provider = new ContentProvider();

        var highlightDecoration = window.createTextEditorDecorationType({
            borderWidth: '1px',
            borderStyle: 'solid',
            borderColor: 'rgba(255,255,0,0.3)',
            backgroundColor: 'rgba(255,255,0,0.3)'
        });
        context.subscriptions.push(highlightDecoration);

        context.subscriptions.push(workspace.registerTextDocumentContentProvider('hxparservis', provider));

        context.subscriptions.push(window.onDidChangeActiveTextEditor(function(editor) {
            provider.updateText();
        }));

        // TODO: figure out what to do with regular updates as we can now receive the language server's incremental parsing results
        /*context.subscriptions.push(workspace.onDidChangeTextDocument(function(e) {
            var activeEditor = window.activeTextEditor;
            if (activeEditor != null && e.document == activeEditor.document) {
                activeTextEditor.setDecorations(highlightDecoration, []);
                provider.updateText();
            }
        }));*/

        context.subscriptions.push(commands.registerCommand("hxparservis.updateParseTree", function(uri:String, parseTree:String) {
            if (uri == provider.previousEditor.document.uri.toString())
                provider.updateText(haxe.Unserializer.run(parseTree));
        }));

        context.subscriptions.push(window.onDidChangeTextEditorSelection(function(e) {
            if (e.textEditor == window.activeTextEditor) {
                provider.highlightNode(e.textEditor.document.offsetAt(e.textEditor.selection.anchor));
            }
        }));

        context.subscriptions.push(workspace.onDidCloseTextDocument(function(e) {
            if (e.fileName != "\\hxparservis")
                return;
            forEditorWithUri(provider.previousEditor.document.uri.toString(), function(editor) {
                editor.setDecorations(highlightDecoration, []);
            });
        }));

        context.subscriptions.push(commands.registerCommand("hxparservis.visualize", function() {
            return commands.executeCommand('vscode.previewHtml', ContentProvider.visUri, ViewColumn.Two, 'hxparser visualization')
                .then(null, function(error) window.showErrorMessage(error));
        }));

        context.subscriptions.push(commands.registerCommand("hxparservis.reveal", function(uri:String, start:Int, end:Int) {
            forEditorWithUri(uri, function(editor) {
                var range = new Range(editor.document.positionAt(start), editor.document.positionAt(end));
                editor.revealRange(range, InCenter);
                editor.setDecorations(highlightDecoration, [range]);
            });
        }));

        context.subscriptions.push(commands.registerCommand("hxparservis.switchOutput", function(outputKind:String) {
            provider.switchOutputKind(outputKind);
        }));

        createCursorOffsetStatusBarItem();
    }

    function forEditorWithUri(uri:String, callback:TextEditor->Void) {
        for (editor in window.visibleTextEditors) {
            if (editor.document.uri.toString() == uri)
                callback(editor);
        }
    }

    /** Useful for debugging Haxe display requests, since the cursor offset is needed there. **/
    function createCursorOffsetStatusBarItem() {
        var cursorOffset = window.createStatusBarItem(Right, 100);
        cursorOffset.tooltip = "Cursor byte offset";
        context.subscriptions.push(cursorOffset);

        function updateItem() {
            var editor = window.activeTextEditor;
            if (editor == null || editor.document.languageId != "haxe") {
                cursorOffset.hide();
                return;
            }
            var pos = editor.selection.start;
            var textUntilCursor = editor.document.getText(new Range(0, 0, pos.line, pos.character));
            cursorOffset.text = "Offset: " + Buffer.byteLength(textUntilCursor);
            cursorOffset.show();
        }

        context.subscriptions.push(window.onDidChangeTextEditorSelection(function(_) updateItem()));
        context.subscriptions.push(window.onDidChangeActiveTextEditor(function(_) updateItem()));
        updateItem();
    }

    @:expose("activate")
    static function activate(context:ExtensionContext) {
        new Main(context);
    }
}
