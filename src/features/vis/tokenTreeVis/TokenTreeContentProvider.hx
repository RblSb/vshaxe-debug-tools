package features.vis.tokenTreeVis;

import byte.ByteData;
import features.vis.ContentProviderBase;
import js.lib.Promise;
import haxeparser.HaxeLexer;
import haxeparser.Data.Token;
import tokentree.TokenStream;
import tokentree.TokenTree;
import tokentree.TokenTreeBuilder;

class TokenTreeContentProvider extends ContentProviderBase<TokenTree> {
	override function printHtml(editor:String, fontFamily:String, fontSize:String):String {
		return new TokenTreeHtmlPrinter().print(editor, content, currentNodePos, fontFamily, fontSize);
	}

	override function reparse():Promise<String> {
		return new Promise(function(resolve, reject) {
			var editor = getActiveEditor();
			if (editor == null) {
				return;
			}

			var src = editor.document.getText();

			try {
				var tokens:Array<Token> = [];
				var bytes:ByteData = ByteData.ofString(src);
				var lexer = new HaxeLexer(bytes, "TokenStream");
				var t:Token = lexer.token(HaxeLexer.tok);
				while (t.tok != Eof) {
					tokens.push(t);
					t = lexer.token(haxeparser.HaxeLexer.tok);
				}
				TokenStream.MODE = Relaxed;
				content = TokenTreeBuilder.buildTokenTree(tokens, bytes);
				resolve(rerender());
			} catch (e:Any) {
				reject('tokentree failed: $e');
			}
		});
	}
}
